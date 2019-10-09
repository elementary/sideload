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

    public SuccessType view_type { get; construct; }

    public SuccessView (SuccessType type = SuccessType.INSTALLED) {
        Object (view_type: type);
    }

    construct {
        badge.gicon = new ThemedIcon ("process-completed");

        var appstore_name = ((Sideload.Application) GLib.Application.get_default ()).get_appstore_name ();

        if (view_type == SuccessType.INSTALLED) {
            primary_label.label = _("The app has been installed");
            secondary_label.label = _("Open it any time from the Applications Menu. Visit %s for app information, updates, and to uninstall.").printf (appstore_name);
        } else if (view_type == SuccessType.ALREADY_INSTALLED) {
            primary_label.label = _("App already installed");
            secondary_label.label = _("No changes were made. Visit %s for app information, updates, and to uninstall.").printf (appstore_name);
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
