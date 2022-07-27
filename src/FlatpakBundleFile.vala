/*
* Copyright 2021-2022 elementary, Inc. (https://elementary.io)
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

public class Sideload.FlatpakBundleFile : FlatpakFile {
    public bool has_remote { get; private set; default = false; }

    private Flatpak.BundleRef bundle = null;

    public FlatpakBundleFile (File file) {
        Object (file: file);
    }

    construct {
        try {
            bundle = new Flatpak.BundleRef (file);
            size = GLib.format_size (bundle.get_installed_size ());
            has_remote = bundle.get_origin () != null;
        } catch (Error e) {
            warning (e.message);
        }
    }

    public override async string? get_id () {
        return bundle.get_name ();
    }

    public override async string? get_name () {
        // Application name from AppData is preferred
        if (appdata_name != null) {
            return appdata_name;
        }

        // Otherwise, fallback to the app id
        return bundle.get_name ();
    }

    private async void dry_run (Cancellable? cancellable) throws GLib.Error {
        if (installation == null) {
            throw new IOError.FAILED (_("Did not find suitable Flatpak installation."));
        }

        var added_remotes = new Gee.ArrayList<string> ();

        try {
            var flatpak_id = bundle.get_name ();

            // get_appstream () only returns the bytes form the appstream file.
            // so we create a temporary file to parse it.
            var appstream_file = GLib.File.new_for_path (file.get_path () + ".appstream");
            try {
                // get the appstream info from inside the bundle
                var stream = appstream_file.create (FileCreateFlags.NONE);
                yield stream.write_bytes_async (bundle.get_appstream ());

                // If we can't find the app by ID in the appstream data, try with a .desktop suffix
                if (!parse_xml (appstream_file, flatpak_id)) {
                    parse_xml (appstream_file, flatpak_id + ".desktop");
                }
            } catch (Error e) {
                warning ("Error while trying to get the bundle appstream file: %s", e.message);
            } finally {
                appstream_file.trash_async.begin ();
            }

            try {
                // mannualy check if it's already installed
                installation.get_installed_ref (bundle.kind, flatpak_id, null, bundle.branch, null);
                already_installed = true;
            } catch (Error e) {
                // assume not installed
                already_installed = false;
            }

            var transaction = new Flatpak.Transaction.for_installation (installation, cancellable);
            transaction.add_default_dependency_sources ();
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

    public override async void get_details (Cancellable? cancellable = null) {
        try {
            yield dry_run (cancellable);
        } catch (Error e) {
            if (!(e is Flatpak.Error.ABORTED)) {
                warning ("Error during dry run: %s", e.message);
            }
        } finally {
            details_ready ();
        }
    }

    public override async void install (Cancellable cancellable) throws Error {
        if (installation == null) {
            throw new IOError.FAILED (_("Did not find suitable Flatpak installation."));
        }

        try {
            var transaction = new Flatpak.Transaction.for_installation (installation, cancellable);
            transaction.add_default_dependency_sources ();
            transaction.add_install_bundle (file, null);

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
                return true;
            });

            yield run_transaction_async (transaction, cancellable);
        } catch (Error e) {
            throw e;
        }
    }

    public override async void launch () {
        try {
            installation.launch (bundle.get_name (), null, bundle.get_branch (), null, null);
        } catch (Error e) {
            warning ("Error launching app: %s", e.message);
        }
    }
}
