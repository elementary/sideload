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

public class Sideload.ProgressView : AbstractView {
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

    public string status {
        set {
            secondary_label.label = value;
        }
    }

    construct {
        secondary_label.label = _("Preparing…");

        progressbar = new Gtk.ProgressBar ();
        progressbar.fraction = 0.0;
        progressbar.hexpand = true;

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.action_name = "app.quit";

        content_area.add (progressbar);
        button_box.add (cancel_button);
        show_all ();
    }
}
