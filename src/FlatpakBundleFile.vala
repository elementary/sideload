/*
* Copyright 2021 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/

public class Sideload.FlatpakBundleFile : Object {
    public File file { get; construct; }

    public string? download_size { get; private set; default = null; }
    public bool already_installed { get; private set; default = false; }
    public bool extra_remotes_needed { get; private set; default = false; }

    private string? appdata_name = null;

    public signal void progress_changed (string description, double progress);
    public signal void installation_failed (GLib.Error details);
    public signal void installation_succeeded ();
    public signal void details_ready ();

    private Flatpak.BundleRef bundle = null;

    private uint total_operations;
    private int current_operation;

    private static Flatpak.Installation? installation;

    static construct {
        try {
            installation = new Flatpak.Installation.user ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    public FlatpakBundleFile (File file) {
        Object (file: file);
    }

    construct {
        try {
            bundle = new Flatpak.BundleRef (file);
        } catch (Error e) {
            warning (e.message);
        }
    }

    private async string? get_id () {
        return ((Flatpak.Ref) bundle).get_name ();
    }

    public async string? get_name () {
        // Application name from AppData is preferred
        if (appdata_name != null) {
            return appdata_name;
        }

        // Otherwise, fallback to the app id
        return yield get_id ();
    }

    private async string? get_branch () {
        return ((Flatpak.Ref) bundle).get_branch ();
    }

    private async void dry_run (Cancellable? cancellable) throws GLib.Error {
        if (installation == null) {
            throw new IOError.FAILED (_("Did not find suitable Flatpak installation."));
        }

        var added_remotes = new Gee.ArrayList<string> ();

        try {
            uint64 total_download_size = -1;
            var flatpak_id = yield get_id ();
            var transaction = new Flatpak.Transaction.for_installation (installation, cancellable);
            transaction.add_install_bundle (file, null);

            transaction.add_new_remote.connect ((reason, from_id, remote_name, url) => {
                if (reason == Flatpak.TransactionRemoteReason.RUNTIME_DEPS) {
                    added_remotes.add (url);
                    extra_remotes_needed = true;
                    return true;
                }

                return false;
            });

            transaction.ready.connect (() => {
                var operations = transaction.get_operations ();
                operations.foreach ((entry) => {
                    try {
                        var @ref = Flatpak.Ref.parse (entry.get_ref ());

                        // If this is the ref the user requested to install, download the appdata for its remote
                        if (@ref.name == flatpak_id) {
                            installation.update_appstream_sync (entry.get_remote (), @ref.arch, null, cancellable);
                            var remote = installation.get_remote_by_name (entry.get_remote ());
                            var appstream_dir = remote.get_appstream_dir (@ref.arch);
                            var appstream_file = appstream_dir.get_child ("appstream.xml.gz");
                            // If we can't find the app by ID in the appstream data, try with a .desktop suffix
                            if (!parse_xml (appstream_file, flatpak_id)) {
                                parse_xml (appstream_file, flatpak_id + ".desktop");
                            }
                        }

                        total_download_size += entry.get_download_size ();
                    } catch (Error e) {
                        warning ("Error calculating download size: %s", e.message);
                    }
                });

                download_size = GLib.format_size (total_download_size);

                // Do not allow the install to start, this is a dry run
                return false;
            });

            Error? transaction_error = null;
            new Thread<void*> ("install-bundle", () => {
                try {
                    transaction.run (cancellable);
                } catch (Error e) {
                    transaction_error = e;
                }

                Idle.add (dry_run.callback);
                return null;
            });

            yield;

            // Cleanup any remotes we had to add while testing the transaction
            installation.list_remotes ().foreach ((remote) => {
                if (remote.get_url () in added_remotes) {
                    try {
                        installation.remove_remote (remote.get_name ());
                    } catch (Error e) {
                        warning ("Error while removing dry run remote: %s", e.message);
                    }
                }
            });

            if (transaction_error != null) {
                throw transaction_error;
            }
        } catch (Error e) {
            throw e;
        }
    }

    private bool parse_xml (GLib.File appstream_file, string id) {
        var path = appstream_file.get_path ();
        Xml.Doc* doc = Xml.Parser.parse_file (path);
        if (doc == null) {
            warning ("Appstream XML file %s not found or permissions missing", path);
            return false;
        }

        Xml.XPath.Context cntx = new Xml.XPath.Context (doc);
        // Find a <component> with a child <id> that matches our id
        var xpath = "/components/component/id[text()='%s']/parent::component".printf (id);
        Xml.XPath.Object* res = cntx.eval_expression (xpath);

        if (res == null) {
            delete doc;
            return false;
        }

        if (res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null) {
            delete res;
            delete doc;
            return false;
        }

        Xml.Node* node = res->nodesetval->item (0);
        for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
            if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                switch (iter->name) {
                    case "name":
                        // Get the non-localised "<name>" tags
                        if (iter->has_prop ("lang") == null) {
                            appdata_name = iter->get_content ();
                        }
                        break;
                    default:
                        break;
                }
            }
        }

        delete res;
        delete doc;

        return true;
    }

    public async void get_details (Cancellable? cancellable = null) {
        try {
            yield dry_run (cancellable);
        } catch (Error e) {
            if (e is Flatpak.Error.ALREADY_INSTALLED) {
                already_installed = true;
            } else if (!(e is Flatpak.Error.ABORTED)) {
                warning ("Error during dry run: %s", e.message);
            }
        } finally {
            details_ready ();
        }
    }

    public async void install (Cancellable cancellable) throws Error {
        if (installation == null) {
            throw new IOError.FAILED (_("Did not find suitable Flatpak installation."));
        }

        try {
            var transaction = new Flatpak.Transaction.for_installation (installation, cancellable);
            transaction.add_install_bundle (file, null);
            transaction.new_operation.connect ((operation, progress) => on_new_operation (operation, progress, cancellable));

            transaction.add_new_remote.connect ((reason, from, name, url) => {
                // If the bundle requests to add a new remote for dependencies, allow it
                if (reason == Flatpak.TransactionRemoteReason.RUNTIME_DEPS) {
                    return true;
                }

                return false;
            });

            transaction.operation_error.connect (on_operation_error);

            // Automatically select the first available remote thas has the dependency we need to install
            transaction.choose_remote_for_ref.connect ((@ref, runtime_ref, remotes) => {
                // TODO: Possibly be more clever here, but this currently matches AppCenter & GNOME Software
                if (remotes.length > 0) {
                    return 0;
                } else {
                    return -1;
                }
            });

            transaction.ready.connect (() => {
                total_operations = transaction.get_operations ().length ();
                return true;
            });

            current_operation = 0;
            yield run_transaction_async (transaction, cancellable);
        } catch (Error e) {
            throw e;
        }
    }

    private bool on_operation_error (Flatpak.TransactionOperation op, GLib.Error e, Flatpak.TransactionErrorDetails details) {
        if (Flatpak.TransactionErrorDetails.NON_FATAL in details) {
            warning ("transaction warning: %s", e.message);
            return true;
        }

        var e_copy = e.copy ();

        Idle.add (() => {
            installation_failed (e_copy);

            return GLib.Source.REMOVE;
        });

        return false;
    }

    private void on_new_operation (Flatpak.TransactionOperation operation, Flatpak.TransactionProgress progress, Cancellable cancellable) {
        current_operation++;

        progress.changed.connect (() => {
            if (cancellable.is_cancelled ()) {
                return;
            }

            Idle.add (() => {
                double existing_progress = (double)(current_operation - 1) / (double)total_operations;
                double this_op_progress = (double)progress.get_progress () / 100.0f / (double)total_operations;
                progress_changed (progress.get_status (), existing_progress + this_op_progress);
                return false;
            });
        });
    }

    private async void run_transaction_async (Flatpak.Transaction transaction, Cancellable cancellable) {
        Error? transaction_error = null;
        new Thread<void*> ("install-bundle", () => {
            try {
                transaction.run (cancellable);
            } catch (Error e) {
                transaction_error = e;
            }

            Idle.add (run_transaction_async.callback);
            return null;
        });

        yield;

        if (transaction_error != null) {
            installation_failed (transaction_error);
        } else {
            installation_succeeded ();
        }
    }

    public async void launch () {
        try {
            installation.launch (yield get_id (), null, yield get_branch (), null, null);
        } catch (Error e) {
            warning ("Error launching app: %s", e.message);
        }
    }
}
