/*
* Copyright 2019 elementary, Inc. (https://elementary.io)
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

public class Sideload.Application : Gtk.Application {
    private const string REF_CONTENT_TYPE = "application/vnd.flatpak.ref";
    private const string REPO_CONTENT_TYPE = "application/vnd.flatpak.repo";
    private const string[] SUPPORTED_CONTENT_TYPES = {
        REF_CONTENT_TYPE,
        REPO_CONTENT_TYPE
    };

    public Application () {
        Object (
            application_id: "io.elementary.sideload",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    protected override void open (File[] files, string hint) {
        if (files.length == 0) {
            return;
        }

        var file = files[0];
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            return;
        }

        hold ();
        open_file.begin (file);
    }

    private async void open_file (File file) {
        GLib.FileInfo? file_info = null;
        try {
            file_info = yield file.query_info_async (
                FileAttribute.STANDARD_CONTENT_TYPE,
                FileQueryInfoFlags.NONE
            );
        } catch (Error e) {
            print ("Unable to query content type of provided file\n");
            release ();
            return;
        }

        if (file_info == null) {
            print ("Unable to query content type of provided file\n");
            release ();
            return;
        }

        var content_type = file_info.get_attribute_string (FileAttribute.STANDARD_CONTENT_TYPE);
        if (content_type == null) {
            print ("Unable to get content type of provided file\n");
            release ();
            return;
        }

        if (!(content_type in SUPPORTED_CONTENT_TYPES)) {
            print ("This does not appear to be a valid flatpakref/flatpakrepo file\n");
            release ();
            return;
        }

        Gtk.ApplicationWindow? main_window = null;

        if (content_type == REF_CONTENT_TYPE) {
            var ref_file = new FlatpakRefFile (file);
            main_window = new InstallRefWindow (this, ref_file);
            main_window.show_all ();

            var launch_action = new SimpleAction ("launch", null);
            add_action (launch_action);

            launch_action.activate.connect (() => {
                ref_file.launch.begin ();
                activate_action ("quit", null);
            });
        } else if (content_type == REPO_CONTENT_TYPE) {
            var repo_file = new FlatpakRepoFile (file);
            main_window = new AddRepoWindow (this, repo_file);
            main_window.show_all ();
        }

        var quit_action = new SimpleAction ("quit", null);
        add_action (quit_action);

        set_accels_for_action ("app.quit", {"<Control>q"});

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
            }
        });

        release ();
    }

    protected override void activate () {

    }

    public string get_appstore_name () {
        var appinfo = GLib.AppInfo.get_default_for_uri_scheme ("appstream");
        if (appinfo != null) {
            return appinfo.get_name ();
        } else {
            return _("your software center");
        }
    }

    public static int main (string[] args) {
        if (args.length < 2) {
            print ("Usage: %s /path/to/flatpakref or /path/to/flatpakrepo\n", args[0]);
            return 1;
        }

        var app = new Application ();
        return app.run (args);
    }
}
