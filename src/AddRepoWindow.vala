/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
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

public class Sideload.AddRepoWindow : Gtk.ApplicationWindow {
    public FlatpakRepoFile file { get; construct; }

    public AddRepoWindow (Gtk.Application application, FlatpakRepoFile file) {
        Object (
            application: application,
            icon_name: "io.elementary.sideload",
            resizable: false,
            title: _("Add untrusted software source"),
            file: file
        );
    }

    construct {
        var titlebar = new Gtk.HeaderBar ();
        titlebar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        titlebar.set_custom_title (new Gtk.Grid ());

        var view = new AddRepoView ();

        view.add_requested.connect (() => {
            file.add ();
            destroy ();
        });

        add (view);

        file.details_ready.connect (() => {
            view.display_details (file.get_title ());
        });

        file.get_details.begin ();

        get_style_context ().add_class ("rounded");
        set_titlebar (titlebar);
    }
}
