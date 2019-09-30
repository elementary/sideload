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

    construct {
        primary_label.label = _("Install untrusted software?");

        secondary_label.label = _("This software is provided solely by its developer and has not been reviewed for security, privacy, or system integration. Installing this software may add a repository of other apps that will show up in AppCenter.");

        var agree_check = new Gtk.CheckButton.with_label (_("I understand"));

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.action_name = "app.quit";

        var install_button = new Gtk.Button.with_label (_("Install"));
        install_button.sensitive = false;
        install_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        content_area.add (agree_check);

        button_box.add (cancel_button);
        button_box.add (install_button);

        show_all ();

        agree_check.grab_focus ();

        agree_check.bind_property ("active", install_button, "sensitive");

        install_button.clicked.connect (() => {
            install_request ();
        });
    }
}
