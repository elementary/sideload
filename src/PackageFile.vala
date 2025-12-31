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

public abstract class Sideload.PackageFile : Object {
    public File file { get; construct; }

    public string? size { get; protected set; default = null; }
    public bool already_installed { get; protected set; default = false; }

    public int error_code = -1;
    public string error_message = "";

    public signal void progress_changed (string description, double progress);
    public signal void installation_failed (int error_code, string? message);
    public signal void installation_succeeded ();
    public signal void details_ready ();

    public abstract async string? get_id ();
    public abstract async string? get_name ();
    public abstract async void get_details (Cancellable? cancellable = null);
    public abstract async void install (Cancellable cancellable) throws Error;
    public abstract async void launch ();
}
