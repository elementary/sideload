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

public class Sideload.ErrorView : AbstractView {
    public GLib.Error error { get; construct; }

    public ErrorView ( GLib.Error error) {
        Object (error: error);
    }

    construct {
        badge.gicon = new ThemedIcon ("dialog-error");

        primary_label.label = _("Install failed");

        secondary_label.label = prettify_flatpak_error (error);

        var details_view = new Gtk.TextView ();
        details_view.border_width = 6;
        details_view.buffer.text = error.message;
        details_view.editable = false;
        details_view.pixels_below_lines = 3;
        details_view.wrap_mode = Gtk.WrapMode.WORD;
        details_view.get_style_context ().add_class (Granite.STYLE_CLASS_TERMINAL);

        var scroll_box = new Gtk.ScrolledWindow (null, null);
        scroll_box.margin_top = 12;
        scroll_box.min_content_height = 70;
        scroll_box.add (details_view);

        var expander = new Gtk.Expander (_("Details"));
        expander.hexpand = true;
        expander.add (scroll_box);

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.action_name = "app.quit";

        content_area.add (expander);
        button_box.add (close_button);

        show_all ();
    }

    private static string prettify_flatpak_error (GLib.Error e) {
        if (e is Flatpak.Error.ALREADY_INSTALLED) {
            return _("This software is already installed.");
        }

        if (e is Flatpak.Error.NEED_NEW_FLATPAK) {
            return _("A newer version of Flatpak is needed to install this software.");
        }

        if (e is Flatpak.Error.REMOTE_NOT_FOUND) {
            return _("A required Flatpak remote was not found.");
        }

        if (e is Flatpak.Error.RUNTIME_NOT_FOUND) {
            return _("A required runtime dependency could not be found.");
        }

        if (e is Flatpak.Error.INVALID_REF) {
            return _("The supplied .flatpakref file does not seem to be valid.");
        }

        if (e is Flatpak.Error.UNTRUSTED) {
            return _("The software is not signed with a trusted signature.");
        }

        if (e is Flatpak.Error.INVALID_NAME) {
            return _("The application, runtime, or remote name is invalid.");
        }

        return _("An unknown error occured.");
    }
}
