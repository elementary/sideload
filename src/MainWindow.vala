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

public class Sideload.MainWindow : Gtk.ApplicationWindow {
    public FlatpakRefFile file { get; construct; }
    private Cancellable? current_cancellable = null;

    private Gtk.Stack stack;
    private ProgressView progress_view;

    public MainWindow (Gtk.Application application, FlatpakRefFile file) {
        Object (
            application: application,
            icon_name: "io.elementary.sideload",
            resizable: false,
            title: _("Install Untrusted Software"),
            file: file
        );
    }

    construct {
        var titlebar = new Gtk.HeaderBar ();
        titlebar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        titlebar.set_custom_title (new Gtk.Grid ());

        var image = new Gtk.Image.from_icon_name ("io.elementary.sideload", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var primary_label = new Gtk.Label (_("Install Untrusted Software?"));
        primary_label.max_width_chars = 50;
        primary_label.selectable = true;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        var secondary_label = new Gtk.Label (_("This software is provided solely by its developer and has not been reviewed for security, privacy, or system integration."));
        secondary_label.max_width_chars = 55;
        secondary_label.selectable = true;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        var agree_check = new Gtk.CheckButton.with_label (_("I understand"));
        agree_check.margin_bottom = 6;
        agree_check.margin_top = 12;

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.action_name = "app.quit";

        var install_button = new Gtk.Button.with_label (_("Install"));
        install_button.sensitive = false;
        install_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.layout_style = Gtk.ButtonBoxStyle.END;
        button_box.margin_top = 12;
        button_box.spacing = 6;
        button_box.add (cancel_button);
        button_box.add (install_button);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.margin = 12;
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (agree_check, 1, 2);
        grid.attach (button_box, 0, 3, 2);
        grid.show_all ();

        progress_view = new ProgressView ();

        stack = new Gtk.Stack ();
        stack.add (grid);
        stack.add (progress_view);

        add (stack);
        get_style_context ().add_class ("rounded");
        set_titlebar (titlebar);

        agree_check.bind_property ("active", install_button, "sensitive");

        install_button.clicked.connect (on_install_button_clicked);
        cancel_button.clicked.connect (() => cancel ());
        file.progress_changed.connect (on_progress_changed);
        get_details.begin ();
    }

    protected override bool delete_event (Gdk.EventAny event) {
        return cancel ();
    }

    private bool cancel () {
        if (current_cancellable != null) {
            current_cancellable.cancel ();
            return true;
        }

        return false;
    }

    private async void get_details () {
        string? name = yield file.get_name ();
        if (name != null) {
            progress_view.app_name = name;
        }
    }

    private void on_install_button_clicked () {
        current_cancellable = new Cancellable ();
        file.install.begin (current_cancellable, (obj, res) => {
            try {
                file.install.end (res);
            } catch (Error e) {
                warning (e.message);
            }
        });

        stack.visible_child = progress_view;
    }

    private void on_progress_changed (string description, double progress) {
        progress_view.progress = progress;
    }
}

