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
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/

public class Sideload.MainWindow : Gtk.ApplicationWindow {
    private const string BUNDLE_CONTENT_TYPE = "application/vnd.flatpak";
    private const string REF_CONTENT_TYPE = "application/vnd.flatpak.ref";
    private const string FLATPAK_HTTPS_CONTENT_TYPE = "x-scheme-handler/flatpak+https";
    private const string[] SUPPORTED_CONTENT_TYPES = {
        BUNDLE_CONTENT_TYPE,
        REF_CONTENT_TYPE,
        FLATPAK_HTTPS_CONTENT_TYPE
    };

    public File file { get; construct; }

    public FlatpakFile flatpak_file { get; private set; }

    private Cancellable? current_cancellable = null;

    private Gtk.Stack stack;
    private MainView main_view;
    private ProgressView progress_view;

    private string? app_name = null;
    private string? app_id = null;

    public MainWindow (Gtk.Application application, File file) {
        Object (
            application: application,
            icon_name: "io.elementary.sideload",
            resizable: false,
            title: _("Install Untrusted App"),
            file: file
        );
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("io.elementary.sideload") {
            pixel_size = 48,
            valign = Gtk.Align.START
        };

        main_view = new MainView ();
        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            vhomogeneous = false,
            interpolate_size = true
        };
        stack.add_child (main_view);
        stack.visible_child = main_view;

        var window_handle = new Gtk.WindowHandle () {
            child = stack
        };

        child = window_handle;

        // We need to hide the title area
        var null_title = new Gtk.Grid () {
            visible = false
        };
        set_titlebar (null_title);

        add_css_class ("dialog");
        add_css_class (Granite.STYLE_CLASS_MESSAGE_DIALOG);

        GLib.Application.get_default ().shutdown.connect (() => {
            if (current_cancellable != null) {
                current_cancellable.cancel ();
            }
        });

        if (file.get_uri ().has_prefix ("flatpak+https://")) {
            var uri = file.get_uri ().replace ("flatpak+https://", "https://");
            var path = Path.build_filename (
                Environment.get_user_special_dir (UserDirectory.DOWNLOAD),
                Path.get_basename (uri)
            );

            var remote_file = File.new_for_uri (uri);
            var local_file = File.new_for_path (path);
            try {
                if (!remote_file.copy (local_file, FileCopyFlags.OVERWRITE)) {
                    var message = (_("Failed to download file from %s")).printf (uri);
                    var error_view = new ErrorView (-1, message);
                    stack.add_child (error_view);
                    stack.visible_child = error_view;
                    return;
                }
            } catch (Error e) {
                var message = (_("Failed to download file from %s: %s")).printf (uri, e.message);
                var error_view = new ErrorView (-1, message);
                stack.add_child (error_view);
                stack.visible_child = error_view;
                return;
            }

            file = local_file;
        }

        FileInfo? file_info = null;
        try {
            file_info = file.query_info (
                FileAttribute.STANDARD_CONTENT_TYPE,
                FileQueryInfoFlags.NONE
            );
        } catch (Error e) {
            var message = (_("Unable to query content type of provided file: %s")).printf (e.message);
            var error_view = new ErrorView (-1, message);
            stack.add_child (error_view);
            stack.visible_child = error_view;
            return;
        }

        if (file_info == null) {
            var message = _("Unable to query content type of provided file");
            var error_view = new ErrorView (-1, message);
            stack.add_child (error_view);
            stack.visible_child = error_view;
            return;
        }

        var content_type = file_info.get_attribute_as_string (FileAttribute.STANDARD_CONTENT_TYPE);
        if (content_type == null) {
            var message = _("Unable to query content type of provided file");
            var error_view = new ErrorView (-1, message);
            stack.add_child (error_view);
            stack.visible_child = error_view;
            return;
        }

        if (!(content_type in SUPPORTED_CONTENT_TYPES)) {
            var message = _("This does not appear to be a valid flatpak/flatpakref file");
            var error_view = new ErrorView (-1, message);
            stack.add_child (error_view);
            stack.visible_child = error_view;
            return;
        }

        switch (content_type) {
            case REF_CONTENT_TYPE:
                flatpak_file = new FlatpakRefFile (file);
                progress_view = new ProgressView (REF_INSTALL);
                break;
            case BUNDLE_CONTENT_TYPE:
                flatpak_file = new FlatpakBundleFile (file);
                progress_view = new ProgressView (BUNDLE_INSTALL);
                break;
            case FLATPAK_HTTPS_CONTENT_TYPE:
                flatpak_file = new FlatpakRefFile (file);
                break;
        }

        if (flatpak_file.size == "0") {
            var error_view = new ErrorView (flatpak_file.error_code, flatpak_file.error_message);
            stack.add_child (error_view);
            stack.visible_child = error_view;
            return;
        } else if (flatpak_file is FlatpakBundleFile) {
            progress_view.status = (_("Installing %s. Unable to estimate time remaining.")).printf (flatpak_file.size);
        }

        stack.add_child (progress_view);

        main_view.install_request.connect (on_install_button_clicked);

        flatpak_file.progress_changed.connect (on_progress_changed);
        flatpak_file.installation_failed.connect (on_install_failed);
        flatpak_file.installation_succeeded.connect (on_install_succeeded);
        flatpak_file.details_ready.connect (() => {
            if (flatpak_file.already_installed) {
                var success_view = new SuccessView (app_name, SuccessView.SuccessType.ALREADY_INSTALLED);

                stack.add_child (success_view);
                stack.visible_child = success_view;
            } else {
                if (flatpak_file is FlatpakRefFile) {
                    main_view.display_ref_details (flatpak_file.size, flatpak_file.extra_remotes_needed, flatpak_file.permissions_flags);
                } else if (flatpak_file is FlatpakBundleFile) {
                    main_view.display_bundle_details (flatpak_file.size, ((FlatpakBundleFile) flatpak_file).has_remote, flatpak_file.extra_remotes_needed);
                }
            }
        });

        get_details.begin ();
    }

    private async void get_details () {
        yield flatpak_file.get_details ();
        app_name = yield flatpak_file.get_name ();
        app_id = yield flatpak_file.get_id ();

        if (app_name != null) {
            progress_view.app_name = app_name;
            main_view.app_name = app_name;
        }
    }

    private void on_install_button_clicked () {
        current_cancellable = new Cancellable ();
        flatpak_file.install.begin (current_cancellable);
        stack.visible_child = progress_view;

        if (flatpak_file is FlatpakRefFile) {
            Granite.Services.Application.set_progress_visible.begin (true);
        }
    }

    private void on_progress_changed (string description, double progress) {
        progress_view.status = description;
        progress_view.progress = progress;

        Granite.Services.Application.set_progress.begin (progress);
    }

    private void on_install_failed (int error_code, string? error_message) {
        switch (error_code) {
            case Flatpak.Error.ALREADY_INSTALLED:
                var success_view = new SuccessView (app_name, SuccessView.SuccessType.ALREADY_INSTALLED);
                stack.add_child (success_view);
                stack.visible_child = success_view;
                break;

            case Flatpak.Error.ABORTED:
                break;

            default:
                var error_view = new ErrorView (error_code, error_message);
                stack.add_child (error_view);
                stack.visible_child = error_view;

                break;
        }

        if (flatpak_file is FlatpakRefFile) {
            Granite.Services.Application.set_progress_visible.begin (false);
        }
    }

    private void on_install_succeeded () {
        var success_view = new SuccessView (app_name);

        stack.add_child (success_view);
        stack.visible_child = success_view;

        if (flatpak_file is FlatpakRefFile) {
            Granite.Services.Application.set_progress_visible.begin (false);
        }

        if (!is_active) {
            var notification = new Notification (_("App installed"));
            if (app_name != null) {
                notification.set_body (_("Installed “%s”").printf (app_name));
            } else {
                notification.set_body (_("The app was installed"));
            }

            var icon = get_application_icon ();
            if (icon != null) {
                notification.set_icon (icon);
            }
            application.send_notification ("installed", notification);
        }
    }

    private GLib.Icon? get_application_icon () {
        var desktop_info = new GLib.DesktopAppInfo (app_id + ".desktop");
        if (desktop_info != null) {
            return desktop_info.get_icon ();
        }
        return null;
    }
}
