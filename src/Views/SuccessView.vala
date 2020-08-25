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

        var appstore_name = ((Sideload.Application) GLib.Application.get_default ()).get_appstore_name ();

        if (view_type == SuccessType.INSTALLED) {
            if (app_name != null) {
                primary_label.label = _("“%s” was installed successfully").printf (app_name);
            } else {
                primary_label.label = _("The app was installed successfully");
            }

            secondary_label.label = _("Open it any time from the Applications Menu. Visit %s for app information, updates, and to uninstall. Permissions can be changed in <a href='%s'>%s → %s…</a>").printf (
                appstore_name, "settings://applications/permissions", _("System Settings"), _("Applications")
            );
        } else if (view_type == SuccessType.ALREADY_INSTALLED) {
            if (app_name != null) {
                primary_label.label = _("“%s” is already installed").printf (app_name);
            } else {
                primary_label.label = _("This app is already installed");
            }

            secondary_label.label = _("No changes were made. Visit %s for app information, updates, and to uninstall. Permissions can be changed in <a href='%s'>%s → %s…</a>").printf (
                appstore_name, "settings://applications/permissions", _("System Settings"), _("Applications")
            );
        }

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.action_name = "app.quit";

        var open_button = new Gtk.Button.with_label (_("Open App"));
        open_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        open_button.action_name = "app.launch";

        button_box.add (close_button);
        button_box.add (open_button);

        show_all ();

        open_button.grab_focus ();
    }
}
