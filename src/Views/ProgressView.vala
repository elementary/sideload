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

public class Sideload.ProgressView : Gtk.Grid {
    private Gtk.Label primary_label;
    private Gtk.ProgressBar progressbar;

    public string app_name {
        set {
            primary_label.label = _("Installing “%s”").printf (value);
        }
    }

    public double progress {
        set {
            progressbar.fraction = value;
        }
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("io.elementary.sideload", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        primary_label = new Gtk.Label ("Installing…");
        primary_label.max_width_chars = 50;
        primary_label.selectable = true;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        progressbar = new Gtk.ProgressBar ();
        progressbar.fraction = 0.0;
        progressbar.hexpand = true;

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.action_name = "app.quit";

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.expand = true;
        button_box.valign = Gtk.Align.END;
        button_box.layout_style = Gtk.ButtonBoxStyle.END;
        button_box.margin_top = 12;
        button_box.spacing = 6;
        button_box.add (cancel_button);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        grid.margin = 12;
        grid.attach (image, 0, 0, 1, 3);
        grid.attach (primary_label, 1, 0);
        grid.attach (progressbar, 1, 1);
        grid.attach (button_box, 0, 3, 2);
        grid.show_all ();

        add (grid);
    }
}
