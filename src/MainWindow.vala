/*
* Copyright 2019-2021 elementary, Inc. (https://elementary.io)
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
    public FlatpakFile file { get; construct; }
    private Cancellable? current_cancellable = null;

    private Gtk.Stack stack;
    private MainView main_view;
    private ProgressView progress_view;

    private string? app_name = null;

    public MainWindow (Gtk.Application application, FlatpakFile file) {
        Object (
            application: application,
            icon_name: "io.elementary.sideload",
            resizable: false,
            title: _("Install Untrusted App"),
            file: file
        );
    }

    construct {
        var titlebar = new Gtk.HeaderBar ();
        titlebar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        titlebar.set_custom_title (new Gtk.Grid ());

        var image = new Gtk.Image.from_icon_name ("io.elementary.sideload", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        main_view = new MainView ();

        if (file is FlatpakRefFile) {
            progress_view = new ProgressView (ProgressView.ProgressType.REF_INSTALL);
        } else {
            progress_view = new ProgressView (ProgressView.ProgressType.BUNDLE_INSTALL);
            progress_view.status = (_("Installing %s. Unable to estimate time remaining.")).printf (file.size);
        }

        stack = new Gtk.Stack ();
        stack.vhomogeneous = false;
        stack.add (main_view);
        stack.add (progress_view);

        add (stack);
        get_style_context ().add_class ("rounded");
        set_titlebar (titlebar);

        main_view.install_request.connect (on_install_button_clicked);
        file.progress_changed.connect (on_progress_changed);
        file.installation_failed.connect (on_install_failed);
        file.installation_succeeded.connect (on_install_succeeded);
        file.details_ready.connect (() => {
            if (file.already_installed) {
                var success_view = new SuccessView (app_name, SuccessView.SuccessType.ALREADY_INSTALLED);

                stack.add (success_view);
                stack.visible_child = success_view;
            } else {
                if (file is FlatpakRefFile) {
                    main_view.display_ref_details (file.size, file.extra_remotes_needed);
                } else {
                    main_view.display_bundle_details (file.size, ((FlatpakBundleFile) file).has_remote, file.extra_remotes_needed);
                }
            }
        });

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

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
        yield file.get_details ();
        app_name = yield file.get_name ();
        if (app_name != null) {
            progress_view.app_name = app_name;
            main_view.app_name = app_name;
        }
    }

    private void on_install_button_clicked () {
        current_cancellable = new Cancellable ();
        file.install.begin (current_cancellable);
        stack.visible_child = progress_view;

        if (file is FlatpakRefFile) {
            Granite.Services.Application.set_progress_visible.begin (true);
        }
    }

    private void on_progress_changed (string description, double progress) {
        progress_view.status = description;
        progress_view.progress = progress;

        Granite.Services.Application.set_progress.begin (progress);
    }

    private void on_install_failed (GLib.Error error) {
        if (error is Flatpak.Error.ALREADY_INSTALLED) {
            var success_view = new SuccessView (app_name, SuccessView.SuccessType.ALREADY_INSTALLED);

            stack.add (success_view);
            stack.visible_child = success_view;
        } else if (!(error is Flatpak.Error.ABORTED)) {
            var error_view = new ErrorView (error);

            stack.add (error_view);
            stack.visible_child = error_view;
        }

        if (file is FlatpakRefFile) {
            Granite.Services.Application.set_progress_visible.begin (false);
        }
    }

    private void on_install_succeeded () {
        var success_view = new SuccessView (app_name);

        stack.add (success_view);
        stack.visible_child = success_view;

        if (file is FlatpakRefFile) {
            Granite.Services.Application.set_progress_visible.begin (false);
        }

        var win = get_window ();
        if (win != null && !(Gdk.WindowState.FOCUSED in get_window ().get_state ())) {
            var notification = new Notification (_("App installed"));
            if (app_name != null) {
                notification.set_body (_("“%s” was installed successfully").printf (app_name));
            } else {
                notification.set_body (_("The app was installed successfully"));
            }

            notification.set_icon (new ThemedIcon ("io.elementary.sideload"));
            application.send_notification ("installed", notification);
        }
    }
}
