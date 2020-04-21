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

public class Sideload.FlatpakRepoFile : Object {
    public signal void details_ready ();
    public signal void loading_failed ();

    public File file { get; construct; }

    private static Flatpak.Installation? installation;
    private Bytes? bytes = null;

    public Flatpak.Remote? remote = null;

    static construct {
        try {
            installation = new Flatpak.Installation.user ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    public FlatpakRepoFile (File file) {
        Object (file: file);
    }

    public async void get_details () {
        var basename = file.get_basename ();

        // Build a valid flatpak repo name from the filename
        var repo_id = basename.to_ascii ();

        // Strip the extension
        repo_id = repo_id[0:repo_id.last_index_of(".")];

        // Replace any non-alphanumeric characters with underscores
        var builder = new StringBuilder ();
        for (uint i = 0; repo_id[i] != '\0'; i++) {
            if (repo_id[i].isalnum ()) {
                builder.append_c (repo_id[i]);
            } else {
                builder.append_c ('_');
            }
        }

        repo_id = builder.str;

        try {
            remote = new Flatpak.Remote.from_file (repo_id, yield get_bytes ());
        } catch (Error e) {
            critical ("Unable to read flatpak repofile, is it valid? Details: %s", e.message);
            loading_failed ();
            return;
        }

        details_ready ();
    }

    public string? get_title () {
        return remote.get_title ();
    }

    public bool add () {
        bool success = false;
        try {
            success = installation.add_remote (remote, true, null);
        } catch (Error e) {
            warning ("Error adding flatpak remote: %s", e.message);
        }

        return success;
    }

    private async Bytes get_bytes () throws Error {
        if (bytes != null) {
            return bytes;
        }

        bytes = yield file.load_bytes_async (null, null);
        return bytes;
    }
}
