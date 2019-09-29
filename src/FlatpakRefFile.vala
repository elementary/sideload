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
    public signal void progress_changed (string description, double progress);
    public signal void installation_failed (GLib.Error details);

    private Bytes? bytes = null;
    private KeyFile? key_file = null;

    private const string REF_GROUP = "Flatpak Ref";

    private static Flatpak.Installation? installation;

    static construct {
        try {
            installation = new Flatpak.Installation.user ();
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

    private async bool load_key_file () {
        if (key_file == null) {
            key_file = new KeyFile ();
            try {
                return key_file.load_from_bytes (yield get_bytes (), NONE);
            } catch (Error e) {
                warning (e.message);
                return false;
            }
        } else {
            return true;
        }
    }

    public async string? get_name () {
        if (!yield load_key_file ()) {
            return null;
        }

        try {
            return key_file.get_string (REF_GROUP, "Name");
        } catch (Error e) {
            warning (e.message);
            return null;
        }
    }

    public async void install (Cancellable cancellable) throws Error {
        if (installation == null) {
            throw new IOError.FAILED (_("Did not find suitable Flatpak installation."));
        }

        try {
            var bytes = yield get_bytes ();
            var transaction = new Flatpak.Transaction.for_installation (installation, cancellable);
            transaction.add_install_flatpakref (bytes);
            transaction.new_operation.connect ((operation, progress) => on_new_operation (operation, progress, cancellable));

            transaction.add_new_remote.connect ((reason, from, name, url) => {
                // If the flatpakref requests to add a new remote for dependencies, allow it
                if (reason == Flatpak.TransactionRemoteReason.RUNTIME_DEPS) {
                    return true;
                }

                return false;
            });

            transaction.operation_error.connect (on_operation_error);

            // Automatically select the first available remote thas has the dependency we need to install
            transaction.choose_remote_for_ref.connect ((@ref, runtime_ref, remotes) => {
                // TODO: Possibly be more clever here, but this currently matches AppCenter & GNOME software
                if (remotes.length > 0) {
                    return 0;
                } else {
                    return -1;
                }
            });

            yield run_transaction_async (transaction, cancellable);
        } catch (Error e) {
            throw e;
        }
    }

    private bool on_operation_error (Flatpak.TransactionOperation op, GLib.Error e, Flatpak.TransactionErrorDetails details) {
        if (Flatpak.TransactionErrorDetails.NON_FATAL in details) {
            warning ("transaction warning: %s", e.message);
            return true;
        }

        installation_failed (e);
        return false;
    }

    private void on_new_operation (Flatpak.TransactionOperation operation, Flatpak.TransactionProgress progress, Cancellable cancellable) {
        progress.changed.connect (() => {
            if (cancellable.is_cancelled ()) {
                return;
            }

            Idle.add (() => {
                progress_changed (progress.get_status (), (double)progress.get_progress () / 100.0f);
                return false;
            });
        });
    }

    private async void run_transaction_async (Flatpak.Transaction transaction, Cancellable cancellable) {
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
            installation_failed (transaction_error);
        }
    }
}
