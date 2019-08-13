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

public class Sideload.FlatpakRefFile : Object {
    public File file { get; construct; }
    private Bytes? bytes = null;

    private static Flatpak.Installation? installation;

    static construct {
        try {
            var installations = Flatpak.get_system_installations (null);
            if (installations.length > 0) {
                installation = installations[0];
            }

        } catch (Error e) {
            warning (e.message);
        }
    }

    public FlatpakRefFile (File file) {
        Object (file: file);
    }

    private async Bytes get_bytes () throws Error {
        if (bytes != null) {
            return bytes;
        }

        bytes = yield file.load_bytes_async (null, null);
        return bytes;
    }

    public async void install (Cancellable cancellable) throws Error {
        if (installation == null) {
            throw new IOError.FAILED (_("Did not find suitable Flatpak installation."));
        }

        try {
            var bytes = yield get_bytes ();
            var transaction = new Flatpak.Transaction.for_installation (installation, cancellable);
            transaction.add_install_flatpakref (bytes);
            yield run_transaction_async (transaction, cancellable);
        } catch (Error e) {
            throw e;
        }
    }

    private static async void run_transaction_async (Flatpak.Transaction transaction, Cancellable cancellable) throws Error {
        Error? transaction_error = null;
        new Thread<void*> ("install-ref", () => {
            try {
                transaction.run (cancellable);
            } catch (Error e) {
                transaction_error = e;
            }

            Idle.add (run_transaction_async.callback);
            return null;
        });

        yield;

        if (transaction_error != null) {
            throw transaction_error;
        }
    }    
}