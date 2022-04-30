/*
* Copyright 2019-2022 elementary, Inc. (https://elementary.io)
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

public abstract class AbstractView : Gtk.Box {
    protected Gtk.Box button_box;
    protected Gtk.Grid content_area;
    protected Gtk.Image badge;
    protected Gtk.Label primary_label;
    protected Gtk.Label secondary_label;

    construct {
        var image = new Gtk.Image.from_icon_name ("io.elementary.sideload") {
            pixel_size = 48
        };
        image.valign = Gtk.Align.START;

        badge = new Gtk.Image ();
        badge.pixel_size = 24;
        badge.halign = badge.valign = Gtk.Align.END;

        var overlay = new Gtk.Overlay () {
            child = image,
            valign = Gtk.Align.START
        };
        overlay.add_overlay (badge);

        primary_label = new Gtk.Label (null) {
            max_width_chars = 1,
            xalign = 0
        };

        primary_label.selectable = true;
        primary_label.wrap = true;
        primary_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        secondary_label = new Gtk.Label (null) {
            max_width_chars = 50,
            width_chars = 50,
            xalign = 0
        };
        secondary_label.use_markup = true;
        secondary_label.selectable = true;
        secondary_label.margin_bottom = 18;
        secondary_label.wrap = true;

        content_area = new Gtk.Grid ();
        content_area.orientation = Gtk.Orientation.VERTICAL;
        content_area.row_spacing = 6;

        button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            vexpand = true,
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };
        button_box.add_css_class ("dialog-action-area");

        var message_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6
        };
        message_grid.attach (overlay, 0, 0, 1, 2);
        message_grid.attach (primary_label, 1, 0);
        message_grid.attach (secondary_label, 1, 1);
        message_grid.attach (content_area, 1, 2);
        message_grid.add_css_class ("dialog-content-area");

        orientation = Gtk.Orientation.VERTICAL;
        append (message_grid);
        append (button_box);
        add_css_class ("dialog-vbox");
    }
}
