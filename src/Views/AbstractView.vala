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

public abstract class AbstractView : Gtk.Grid {
    internal Gtk.ButtonBox button_box;
    internal Gtk.Grid content_area;
    internal Gtk.Image badge;
    internal Gtk.Label primary_label;
    internal Gtk.Label secondary_label;

    construct {
        var image = new Gtk.Image.from_icon_name ("io.elementary.sideload", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        badge = new Gtk.Image ();
        badge.pixel_size = 24;
        badge.halign = badge.valign = Gtk.Align.END;

        var overlay = new Gtk.Overlay ();
        overlay.valign = Gtk.Align.START;
        overlay.add (image);
        overlay.add_overlay (badge);

        primary_label = new Gtk.Label (null);
        primary_label.hexpand = true;
        primary_label.max_width_chars = 50;
        primary_label.selectable = true;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        secondary_label = new Gtk.Label (null);
        secondary_label.use_markup = true;
        secondary_label.selectable = true;
        secondary_label.margin_bottom = 18;
        secondary_label.max_width_chars = 50;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        content_area = new Gtk.Grid ();

        button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.expand = true;
        button_box.valign = Gtk.Align.END;
        button_box.layout_style = Gtk.ButtonBoxStyle.END;
        button_box.margin_top = 12;
        button_box.spacing = 6;

        column_spacing = 12;
        row_spacing = 6;
        margin = 12;
        attach (overlay, 0, 0, 1, 2);
        attach (primary_label, 1, 0);
        attach (secondary_label, 1, 1);
        attach (content_area, 1, 2);
        attach (button_box, 0, 3, 2);
    }
}
