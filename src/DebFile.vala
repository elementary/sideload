/*
* Copyright 2025 Ethan Lurks @ https://github.com/thisaintcub
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
*/

public class Sideload.DebFile : PackageFile {
    private string? package_name = null;
    private string? package_version = null;
    private string? package_description = null;
    
    private const string HELPER_PATH = "/usr/lib/io.elementary.sideload/deb_helper.sh";

    public DebFile (File file) {
        Object (file: file);
    }
 
    construct {
        size = "0";
        try {
            string stdout;
            string stderr;
            int exit_status;

            // Use dpkg-deb --info to validate the file
            string[] args = {"dpkg-deb", "--info", file.get_path ()};
            Process.spawn_sync (
                null,
                args,
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );

            if (exit_status != 0) {
                error_code = -1;
                error_message = _("Not a valid Debian package file");
                return;
            }

            extract_package_info ();
        } catch (Error e) {
            error_code = -1;
            error_message = _("Error reading package file: %s").printf (e.message);
        }
    }

    private void extract_package_info () throws Error {
        string stdout;
        string stderr;
        int exit_status;

        // Read package name
        string[] name_args = {"dpkg-deb", "--field", file.get_path (), "Package"};
        Process.spawn_sync (
            null,
            name_args,
            null,
            SpawnFlags.SEARCH_PATH,
            null,
            out stdout,
            out stderr,
            out exit_status
        );

        if (exit_status == 0 && stdout.strip () != "") {
            package_name = stdout.strip ();
        } else {
            throw new IOError.FAILED (_("Could not read package name"));
        }

        // Read package version
        string[] version_args = {"dpkg-deb", "--field", file.get_path (), "Version"};
        Process.spawn_sync (
            null,
            version_args,
            null,
            SpawnFlags.SEARCH_PATH,
            null,
            out stdout,
            out stderr,
            out exit_status
        );

        if (exit_status == 0) {
            package_version = stdout.strip ();
        }

        // Read package description
        string[] desc_args = {"dpkg-deb", "--field", file.get_path (), "Description"};
        Process.spawn_sync (
            null,
            desc_args,
            null,
            SpawnFlags.SEARCH_PATH,
            null,
            out stdout,
            out stderr,
            out exit_status
        );

        if (exit_status == 0) {
            package_description = stdout.strip ();
        }

        // Read installed size
        string[] size_args = {"dpkg-deb", "--field", file.get_path (), "Installed-Size"};
        Process.spawn_sync (
            null,
            size_args,
            null,
            SpawnFlags.SEARCH_PATH,
            null,
            out stdout,
            out stderr,
            out exit_status
        );

        if (exit_status == 0 && stdout.strip () != "") {
            var size_kb = int64.parse (stdout.strip ());
            size = GLib.format_size (size_kb * 1024);
        } else {
            // Fallback to file size if Installed-Size not available
            try {
                var file_info = file.query_info (FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE);
                size = GLib.format_size (file_info.get_size ());
            } catch (Error e) {
                size = _("Unknown");
            }
        }
    }

    public override async string? get_id () {
        return package_name;
    }

    public override async string? get_name () {
        return package_name;
    }

    public override async void get_details (Cancellable? cancellable = null) {
        try {
            // Check if already installed
            string stdout;
            string stderr;
            int exit_status;

            string[] args = {"dpkg-query", "-W", "-f=${Status}", package_name};
            Process.spawn_sync (
                null,
                args,
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );

            already_installed = (exit_status == 0 && "installed" in stdout);
        } catch (Error e) {
            warning ("Error checking if package is installed: %s", e.message);
            already_installed = false;
        } finally {
            details_ready ();
        }
    }

    public override async void install (Cancellable cancellable) throws Error {
        if (cancellable.is_cancelled ()) {
            throw new IOError.CANCELLED (_("Installation cancelled"));
        }

        // Check if helper script exists
        var helper_file = File.new_for_path (HELPER_PATH);
        if (!helper_file.query_exists ()) {
            throw new IOError.FAILED (_("Installation helper not found. Please reinstall Sideload."));
        }

        error_code = -1;

        new Thread<void*> ("install-deb", () => {
            try {
                Idle.add (() => {
                    progress_changed (_("Preparing installation…"), 0.05);
                    return false;
                });

                if (cancellable.is_cancelled ()) {
                    error_code = -1;
                    error_message = _("Installation cancelled");
                    Idle.add (install.callback);
                    return null;
                }

                string[] pkexec_args = {"pkexec", HELPER_PATH, file.get_path ()};

                int standard_output;
                int standard_error;
                Pid child_pid;

                Process.spawn_async_with_pipes (
                    null,
                    pkexec_args,
                    null,
                    SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                    null,
                    out child_pid,
                    null,
                    out standard_output,
                    out standard_error
                );

                var output_channel = new IOChannel.unix_new (standard_output);
                var last_progress = 0.05;

                output_channel.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                    if (condition == IOCondition.HUP) {
                        return false;
                    }

                    try {
                        string line;
                        channel.read_line (out line, null, null);

                        if (line != null && line.has_prefix ("PROGRESS:")) {
                            var progress_str = line.strip ().substring (9);
                            var progress_val = double.parse (progress_str) / 100.0;

                            string status_msg;
                            if (progress_val <= 0.1) {
                                status_msg = _("Updating package cache…");
                            } else if (progress_val <= 0.3) {
                                status_msg = _("Installing package…");
                            } else if (progress_val <= 0.6) {
                                status_msg = _("Resolving dependencies…");
                            } else if (progress_val <= 0.9) {
                                status_msg = _("Verifying installation…");
                            } else {
                                status_msg = _("Installation complete");
                            }

                            last_progress = progress_val;

                            Idle.add (() => {
                                progress_changed (status_msg, progress_val);
                                return false;
                            });
                        }
                    } catch (Error e) {
                        warning ("Error reading output: %s", e.message);
                    }

                    return true;
                });

                // Wait for process to complete
                int status;
                Posix.waitpid (child_pid, out status, 0);
                Process.close_pid (child_pid);

                var exit_status = Process.exit_status (status);

                if (exit_status != 0) {
                    error_code = exit_status;
                    error_message = _("Installation failed. Package may have dependency issues or you cancelled authentication.");
                } else {
                    // Final verification
                    string stdout;
                    string stderr;
                    string[] verify_args = {"dpkg-query", "-W", "-f=${Status}", package_name};

                    Process.spawn_sync (
                        null,
                        verify_args,
                        null,
                        SpawnFlags.SEARCH_PATH,
                        null,
                        out stdout,
                        out stderr,
                        out exit_status
                    );

                    if (exit_status != 0 || !("installed" in stdout)) {
                        error_code = exit_status;
                        error_message = _("Installation verification failed");
                    } else {
                        error_code = -1; // Success
	
                        Idle.add (() => {
                            progress_changed (_("Installation complete"), 1.0);
                            return false;
                        });
                    }
                }

            } catch (Error e) {
                error_code = -1;
                error_message = e.message;
            }

            Idle.add (install.callback);
            return null;
        });

        yield;

        if (error_code >= 0) {
            installation_failed (error_code, error_message);
            throw new IOError.FAILED (error_message);
        } else {
            installation_succeeded ();
        }
    }

    public override async void launch () {
        // Debs don't have a standard launch mechanism
        // Try to find a .desktop file for the package
        try {
            string desktop_file = package_name + ".desktop";
            var app_info = new DesktopAppInfo (desktop_file);
            if (app_info != null) {
                app_info.launch (null, null);
            }
        } catch (Error e) {
            warning ("Could not launch application: %s", e.message);
        }
    }
}
