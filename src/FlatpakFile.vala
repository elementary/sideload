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

public abstract class Sideload.FlatpakFile : Object {
    public File file { get; construct; }

    [Flags]
    public enum PermissionsFlags {
        DEVICES,
        DOWNLOADS_FULL,
        DOWNLOADS_READ,
        ESCAPE_SANDBOX,
        FILESYSTEM_FULL,
        FILESYSTEM_OTHER,
        FILESYSTEM_READ,
        HOME_FULL,
        HOME_READ,
        NETWORK,
        NONE,
        SESSION_BUS,
        SETTINGS,
        SYSTEM_BUS,
        UNKNOWN,
        X11
    }

    public PermissionsFlags permissions_flags { get; set; default = PermissionsFlags.UNKNOWN; }
    public string? size { get; protected set; default = null; }
    public bool already_installed { get; protected set; default = false; }
    public bool extra_remotes_needed { get; protected set; default = false; }

    protected string? appdata_name = null;
    public int error_code = -1;
    public string error_message = "";

    public signal void progress_changed (string description, double progress);
    public signal void installation_failed (int error_code, string? message);
    public signal void installation_succeeded ();
    public signal void details_ready ();

    protected static Flatpak.Installation? installation;

    static construct {
        try {
            installation = new Flatpak.Installation.user ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    public abstract async string? get_id ();

    public abstract async string? get_name ();

    public abstract async void get_details (Cancellable? cancellable = null);

    public abstract async void install (Cancellable cancellable) throws Error;

    public abstract async void launch ();

    protected bool parse_xml (GLib.File appstream_file, string id) {
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

    protected async void run_transaction_async (Flatpak.Transaction transaction, Cancellable cancellable) {
        error_code = -1;
        new Thread<void*> ("install-flatpak", () => {
            try {
                transaction.run (cancellable);
            } catch (Error e) {
                error_code = e.code;
                error_message = e.message;
            }

            Idle.add (run_transaction_async.callback);
            return null;
        });

        yield;

        if (error_code >= 0) {
            installation_failed (error_code, error_message);
        } else {
            installation_succeeded ();
        }
    }

    protected bool on_operation_error (Flatpak.TransactionOperation op, GLib.Error e, Flatpak.TransactionErrorDetails details) {
        if (Flatpak.TransactionErrorDetails.NON_FATAL in details) {
            warning ("transaction warning: %s", e.message);
            return true;
        }

        error_code = e.code;
        error_message = e.message;

        Idle.add (() => {
            installation_failed (error_code, error_message);

            return GLib.Source.REMOVE;
        });

        return false;
    }
}
