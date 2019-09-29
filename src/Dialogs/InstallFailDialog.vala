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

public class InstallFailDialog : Granite.MessageDialog {
    public GLib.Error error { get; construct; }
    public InstallFailDialog ( GLib.Error e) {
        Object (
            title: "",
            primary_text: _("Install failed"),
            secondary_text: prettify_flatpak_error (e),
            buttons: Gtk.ButtonsType.CLOSE,
            image_icon: new ThemedIcon ("dialog-error"),
            window_position: Gtk.WindowPosition.CENTER,
            error: e
        );
    }

    construct {
        response.connect (() => destroy ());

        show_error_details (error.message);
        stick ();
    }

    private static string prettify_flatpak_error (GLib.Error e) {
        if (e is Flatpak.Error.ALREADY_INSTALLED) {
            return _("This package is already installed.");
        }

        if (e is Flatpak.Error.NEED_NEW_FLATPAK) {
            return _("A newer version of flatpak is needed to install this package.");
        }

        if (e is Flatpak.Error.REMOTE_NOT_FOUND) {
            return _("A required remote was not found.");
        }

        if (e is Flatpak.Error.RUNTIME_NOT_FOUND) {
            return _("A required runtime dependency could not be found.");
        }

        if (e is Flatpak.Error.INVALID_REF) {
            return _("The supplied .flatpakref file does not seem to be valid.");
        }

        if (e is Flatpak.Error.UNTRUSTED) {
            return _("The package is not signed with a trusted signature.");
        }

        if (e is Flatpak.Error.INVALID_NAME) {
            return _("The application, runtime or remote name is invalid");
        }

        return _("An unknown error occured");
    }
}
