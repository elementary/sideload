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

    private static Gtk.CssProvider provider;

    private Gtk.Grid details_grid;
    private Gtk.Stack details_stack;
    private Gtk.Label download_size_label;

    static construct {
        provider = new Gtk.CssProvider ();
        provider.load_from_resource ("io/elementary/sideload/colors.css");
    }

    construct {
        primary_label.label = _("Install untrusted software?");

        secondary_label.label = _("This software is provided solely by its developer and has not been reviewed for security, privacy, or system integration.");

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.start ();

        var loading_label = new Gtk.Label (_("Fetching details"));

        var loading_grid = new Gtk.Grid ();
        loading_grid.column_spacing = 6;
        loading_grid.add (loading_spinner);
        loading_grid.add (loading_label);

        var agree_check = new Gtk.CheckButton.with_label (_("I understand"));
        agree_check.margin_top = 12;

        var download_size_icon = new Gtk.Image.from_icon_name ("browser-download-symbolic", Gtk.IconSize.BUTTON);
        download_size_icon.valign = Gtk.Align.START;

        unowned Gtk.StyleContext download_context = download_size_icon.get_style_context ();
        download_context.add_class ("downloads");
        download_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        download_size_label = new Gtk.Label (null);
        download_size_label.selectable = true;
        download_size_label.max_width_chars = 50;
        download_size_label.wrap = true;
        download_size_label.xalign = 0;

        var updates_icon = new Gtk.Image.from_icon_name ("system-software-update-symbolic", Gtk.IconSize.BUTTON);
        updates_icon.valign = Gtk.Align.START;

        unowned Gtk.StyleContext updates_context = updates_icon.get_style_context ();
        updates_context.add_class ("updates");
        updates_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var updates_label = new Gtk.Label (_("Updates to this app will not be reviewed"));
        updates_label.selectable = true;
        updates_label.max_width_chars = 50;
        updates_label.wrap = true;
        updates_label.xalign = 0;

        details_grid = new Gtk.Grid ();
        details_grid.orientation = Gtk.Orientation.VERTICAL;
        details_grid.column_spacing = 6;
        details_grid.row_spacing = 12;
        details_grid.attach (download_size_icon, 0, 0);
        details_grid.attach (download_size_label, 1, 0);
        details_grid.attach (updates_icon, 0, 1);
        details_grid.attach (updates_label, 1, 1);
        details_grid.attach (agree_check, 0, 3, 2);

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

    public void display_details (string? size, bool extra_repo) {
        if (size != null) {
            download_size_label.label = _("Download size may be up to %s").printf (size);
        } else {
            download_size_label.label = _("Unknown download size");
        }

        if (extra_repo) {
            var repo_icon = new Gtk.Image.from_icon_name ("package-x-generic-symbolic", Gtk.IconSize.BUTTON);
            repo_icon.valign = Gtk.Align.START;

            var repo_label = new Gtk.Label (_("Installing will add a software source that may contain other apps"));
            repo_label.selectable = true;
            repo_label.max_width_chars = 50;
            repo_label.wrap = true;
            repo_label.xalign = 0;

            details_grid.attach (repo_icon, 0, 2);
            details_grid.attach (repo_label, 1, 2);
        }

        details_stack.visible_child_name = "details";
        show_all ();
    }
}
