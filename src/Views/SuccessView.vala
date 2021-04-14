/*
 * Copyright 2019–2021 elementary, Inc. (https://elementary.io)
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
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

public class Sideload.SuccessView : AbstractView {
    public enum SuccessType {
        INSTALLED,
        ALREADY_INSTALLED
    }

    public string? app_name { get; construct; }
    public SuccessType view_type { get; construct; }

    public SuccessView (string? app_name, SuccessType type = SuccessType.INSTALLED) {
        Object (
            app_name: app_name,
            view_type: type
        );
    }

    construct {
        badge.gicon = new ThemedIcon ("process-completed");

        var app = (Sideload.Application) GLib.Application.get_default ();
        var appstore_name = app.get_appstore_name ();
        var file = ((Sideload.MainWindow) app.active_window).file;
        string? secondary_label_string;

        if (view_type == SuccessType.INSTALLED) {
            if (app_name != null) {
                primary_label.label = _("“%s” has been installed").printf (app_name);
            } else {
                primary_label.label = _("The app has been installed");
            }

            secondary_label_string = _("Open it any time from the Applications Menu.");

        } else if (view_type == SuccessType.ALREADY_INSTALLED) {
            if (app_name != null) {
                primary_label.label = _("“%s” is already installed").printf (app_name);
            } else {
                primary_label.label = _("This app is already installed");
            }

            secondary_label_string = _("No changes were made.");
        }

        if (file is FlatpakRefFile) {
            secondary_label_string += " ";
            secondary_label_string += _("Visit %s for app information, updates, and to uninstall.").printf (
                appstore_name
            );
        }

        secondary_label_string += " ";
        secondary_label_string += _("Permissions can be changed in <a href='%s'>%s → %s…</a>").printf (
            /// TRANSLATORS: "System Settings" is related to the title of https://github.com/elementary/switchboard, "Applications" is related to the title of https://github.com/elementary/switchboard-plug-applications
            "settings://applications/permissions", _("System Settings"), _("Applications")
        );

        secondary_label.label = secondary_label_string;

        var trash_check = new Gtk.CheckButton.with_label (_("Move ”%s” to Trash").printf (file.file.get_basename ()));
        content_area.add (trash_check);

        var settings = new Settings ("io.elementary.sideload");
        settings.bind ("trash-on-success", trash_check, "active", GLib.SettingsBindFlags.DEFAULT);

        var close_button = new Gtk.Button.with_label (_("Close"));

        var open_button = new Gtk.Button.with_label (_("Open App"));
        open_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        button_box.add (close_button);
        button_box.add (open_button);

        show_all ();

        open_button.grab_focus ();

        close_button.clicked.connect (() => {
            if (trash_check.active) {
                trash_file (file);
            }

            app.quit ();
        });

        open_button.clicked.connect (() => {
            if (trash_check.active) {
                trash_file (file);
            }

            app.activate_action ("launch", null);
        });
    }

    private void trash_file (FlatpakFile file) {
        file.file.trash_async.begin (GLib.Priority.DEFAULT, null, (obj, res) => {
            try {
                file.file.trash_async.end (res);
            } catch (Error e) {
                warning (e.message);
            }
        });
    }
}
