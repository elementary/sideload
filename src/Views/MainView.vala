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
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

public class Sideload.MainView : AbstractView {
    public signal void install_request ();

    public string app_name {
        set {
            primary_label.label = _("Trust and install “%s”?").printf (value);
        }
    }

    private Gtk.Grid details_grid;
    private Gtk.Stack details_stack;
    private Gtk.Label download_size_label;
    private Gtk.Image updates_icon;
    private Gtk.Label updates_label;
    private Gtk.Image repo_icon;
    private Gtk.Label repo_label;
    private Gtk.Image permissions_image;
    private Gtk.Label permissions_label;

    construct {
        primary_label.label = _("Trust and install this app?");

        secondary_label.label = _("This app is provided solely by its developer and has not been reviewed by elementary for security, privacy, or system integration.");

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.start ();

        var loading_label = new Gtk.Label (_("Fetching details"));

        var loading_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        loading_grid.append (loading_spinner);
        loading_grid.append (loading_label);

        var agree_check = new Gtk.CheckButton.with_label (_("I understand"));
        agree_check.margin_top = 12;

        var download_size_icon = new Gtk.Image.from_icon_name ("browser-download-symbolic") {
            valign = START
        };
        download_size_icon.add_css_class (Granite.STYLE_CLASS_ACCENT);
        download_size_icon.add_css_class ("green");

        download_size_label = new Gtk.Label (null);
        download_size_label.selectable = true;
        download_size_label.max_width_chars = 50;
        download_size_label.wrap = true;
        download_size_label.xalign = 0;

        updates_icon = new Gtk.Image.from_icon_name ("system-software-update-symbolic") {
            valign = START
        };
        updates_icon.add_css_class (Granite.STYLE_CLASS_ACCENT);
        updates_icon.add_css_class ("orange");

        updates_label = new Gtk.Label (_("Updates to this app will not be reviewed by elementary"));
        updates_label.selectable = true;
        updates_label.max_width_chars = 50;
        updates_label.wrap = true;
        updates_label.xalign = 0;

        repo_icon = new Gtk.Image.from_icon_name ("system-software-install-symbolic") {
            valign = START
        };
        repo_icon.add_css_class (Granite.STYLE_CLASS_ACCENT);
        repo_icon.add_css_class ("purple");

        var appstore_name = ((Sideload.Application) GLib.Application.get_default ()).get_appstore_name ();

        repo_label = new Gtk.Label (_("Other apps from this distributor may appear in %s").printf (appstore_name));
        repo_label.selectable = true;
        repo_label.max_width_chars = 50;
        repo_label.wrap = true;
        repo_label.xalign = 0;

        permissions_image = new Gtk.Image () {
            valign = Gtk.Align.START
        };
        permissions_image.add_css_class (Granite.STYLE_CLASS_ACCENT);

        permissions_label = new Gtk.Label ("") {
            max_width_chars = 50,
            selectable = true,
            wrap = true,
            xalign = 0
        };

        details_grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 12
        };
        details_grid.attach (download_size_icon, 0, 0);
        details_grid.attach (download_size_label, 1, 0);
        details_grid.attach (agree_check, 0, 4, 2);

        details_stack = new Gtk.Stack ();
        details_stack.vhomogeneous = false;
        details_stack.add_named (loading_grid, "loading");
        details_stack.add_named (details_grid, "details");
        details_stack.visible_child_name = "loading";

        content_area.attach (details_stack, 0, 0);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.action_name = "app.quit";

        var install_button = new Gtk.Button.with_label (_("Install Anyway"));
        install_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);

        button_box.append (cancel_button);
        button_box.append (install_button);

        agree_check.bind_property ("active", install_button, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        agree_check.grab_focus ();

        install_button.clicked.connect (() => {
            install_request ();
        });
    }

    public void display_bundle_details (string size, bool has_repo, bool extra_repo) {
        download_size_label.label = _("Install size may be up to %s").printf (size);

        if (has_repo) {
            details_grid.attach (updates_icon, 0, 1);
            details_grid.attach (updates_label, 1, 1);
        }

        if (extra_repo) {
            details_grid.attach (repo_icon, 0, 2);
            details_grid.attach (repo_label, 1, 2);
        }

        details_stack.visible_child_name = "details";
    }

    public void display_ref_details (string? size, bool extra_repo, FlatpakFile.PermissionsFlags permissions_flags) {
        if (size != null) {
            download_size_label.label = _("Download size may be up to %s").printf (size);
        } else {
            download_size_label.label = _("Unknown download size");
        }

        if (
            FlatpakFile.PermissionsFlags.ESCAPE_SANDBOX in permissions_flags ||
            FlatpakFile.PermissionsFlags.FILESYSTEM_FULL in permissions_flags ||
            FlatpakFile.PermissionsFlags.SYSTEM_BUS in permissions_flags
        ) {
            permissions_image.icon_name = "security-low-symbolic";
            permissions_image.add_css_class ("red");
            permissions_label.label = _("Requests advanced permissions that could be used to violate your privacy or security");
        } else if (
            FlatpakFile.PermissionsFlags.DOWNLOADS_FULL in permissions_flags ||
            FlatpakFile.PermissionsFlags.DOWNLOADS_READ in permissions_flags ||
            FlatpakFile.PermissionsFlags.FILESYSTEM_OTHER in permissions_flags ||
            FlatpakFile.PermissionsFlags.FILESYSTEM_READ in permissions_flags ||
            FlatpakFile.PermissionsFlags.HOME_FULL in permissions_flags ||
            FlatpakFile.PermissionsFlags.HOME_READ in permissions_flags
        ) {
            permissions_image.icon_name = "security-low-symbolic";
            permissions_image.add_css_class ("yellow");
            permissions_label.label = _("Requests file and folder permissions that could be used to violate your privacy");
        } else {
            permissions_image.icon_name = "security-high-symbolic";
            permissions_image.add_css_class ("green");
            permissions_label.label = _("Doesn't request advanced system permissions");
        }

        details_grid.attach (permissions_image, 0, 1);
        details_grid.attach (permissions_label, 1, 1);
        details_grid.attach (updates_icon, 0, 2);
        details_grid.attach (updates_label, 1, 2);

        if (extra_repo) {
            details_grid.attach (repo_icon, 0, 3);
            details_grid.attach (repo_label, 1, 3);
        }
        details_stack.visible_child_name = "details";
    }
}
