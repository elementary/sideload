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

public class Sideload.MainView : AbstractView {
    public signal void install_request ();

    private Gtk.Stack details_stack;
    private Gtk.Label download_size_label;

    construct {
        primary_label.label = _("Install untrusted software?");

        secondary_label.label = _("This software is provided solely by its developer and has not been reviewed for security, privacy, or system integration. Installing this software may add a repository of other apps that will show up in AppCenter.");

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.start ();

        var loading_label = new Gtk.Label (_("Fetching details"));

        var loading_grid = new Gtk.Grid ();
        loading_grid.column_spacing = 6;
        loading_grid.add (loading_spinner);
        loading_grid.add (loading_label);

        var agree_check = new Gtk.CheckButton.with_label (_("I understand"));

        var download_size_icon = new Gtk.Image.from_icon_name ("dialog-information-symbolic", Gtk.IconSize.BUTTON);

        download_size_label = new Gtk.Label (null);

        var details_grid = new Gtk.Grid ();
        details_grid.orientation = Gtk.Orientation.VERTICAL;
        details_grid.column_spacing = 6;
        details_grid.row_spacing = 12;
        details_grid.attach (download_size_icon, 0, 0);
        details_grid.attach (download_size_label, 1, 0);
        details_grid.attach (agree_check, 0, 1, 2);

        details_stack = new Gtk.Stack ();
        details_stack.vhomogeneous = false;
        details_stack.add_named (loading_grid, "loading");
        details_stack.add_named (details_grid, "details");
        details_stack.visible_child_name = "loading";

        content_area.add (details_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.action_name = "app.quit";

        var install_button = new Gtk.Button.with_label (_("Install Anyway"));
        install_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        button_box.add (cancel_button);
        button_box.add (install_button);

        show_all ();

        agree_check.bind_property ("active", install_button, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        agree_check.grab_focus ();

        install_button.clicked.connect (() => {
            install_request ();
        });
    }

    public void display_details (string? size) {
        if (size != null) {
            download_size_label.label = _("Download size up to: %s").printf (size);
            details_stack.visible_child_name = "details";
        }
    }
}
