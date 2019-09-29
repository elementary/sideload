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

public class Sideload.ErrorView : Gtk.Grid {
    public GLib.Error error { get; construct; }

    public ErrorView ( GLib.Error error) {
        Object (error: error);
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("io.elementary.sideload", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var badge = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.LARGE_TOOLBAR);
        badge.halign = badge.valign = Gtk.Align.END;

        var overlay = new Gtk.Overlay ();
        overlay.valign = Gtk.Align.START;
        overlay.add (image);
        overlay.add_overlay (badge);

        var primary_label = new Gtk.Label (_("Install failed"));
        primary_label.hexpand = true;
        primary_label.max_width_chars = 50;
        primary_label.selectable = true;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        var secondary_label = new Gtk.Label (prettify_flatpak_error (error));
        secondary_label.use_markup = true;
        secondary_label.selectable = true;
        secondary_label.margin_bottom = 18;
        secondary_label.max_width_chars = 50;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

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
        expander.add (scroll_box);

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.action_name = "app.quit";

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.expand = true;
        button_box.valign = Gtk.Align.END;
        button_box.layout_style = Gtk.ButtonBoxStyle.END;
        button_box.margin_top = 12;
        button_box.spacing = 6;
        button_box.add (close_button);

        column_spacing = 12;
        row_spacing = 6;
        margin = 12;
        attach (overlay, 0, 0, 1, 2);
        attach (primary_label, 1, 0);
        attach (secondary_label, 1, 1);
        attach (expander, 1, 2);
        attach (button_box, 0, 3, 2);
        show_all ();
    }

    private static string prettify_flatpak_error (GLib.Error e) {
        if (e is Flatpak.Error.ALREADY_INSTALLED) {
            return _("This package is already installed.");
        }

        if (e is Flatpak.Error.NEED_NEW_FLATPAK) {
            return _("A newer version of flatpak is needed to install this package.");
        }

        if (e is Flatpak.Error.REMOTE_NOT_FOUND) {
            return _("A required remote was not found.");
        }

        if (e is Flatpak.Error.RUNTIME_NOT_FOUND) {
            return _("A required runtime dependency could not be found.");
        }

        if (e is Flatpak.Error.INVALID_REF) {
            return _("The supplied .flatpakref file does not seem to be valid.");
        }

        if (e is Flatpak.Error.UNTRUSTED) {
            return _("The package is not signed with a trusted signature.");
        }

        if (e is Flatpak.Error.INVALID_NAME) {
            return _("The application, runtime or remote name is invalid.");
        }

        return _("An unknown error occured.");
    }
}
