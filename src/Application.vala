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
    private MainWindow main_window;

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

        var ref_file = new FlatpakRefFile (file);
        main_window = new MainWindow (this, ref_file);
        main_window.show_all ();

        var quit_action = new SimpleAction ("quit", null);
        var launch_action = new SimpleAction ("launch", null);

        add_action (quit_action);
        add_action (launch_action);
        set_accels_for_action ("app.quit", {"<Control>q"});

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
            }
        });

        launch_action.activate.connect (() => {
            ref_file.launch.begin ();
            activate_action ("quit", null);
        });
    }

    protected override void activate () {

    }

    public string get_appstore_name () {
        var appinfo = GLib.AppInfo.get_default_for_uri_scheme ("appstream");
        if (appinfo != null) {
            return appinfo.get_name ();
        } else {
            return _("AppCenter");
        }
    }

    public static int main (string[] args) {
        if (args.length < 2) {
            print ("Usage: %s /path/to/flatpakref\n", args[0]);
            return 1;
        }

        var app = new Application ();
        return app.run (args);
    }
}
