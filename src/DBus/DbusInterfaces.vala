/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

 struct UserInfo {
    uint32 uid;
    string user_name;
    ObjectPath? user_object;
}

/* Power and system control */
[DBus (name = "org.gnome.ScreenSaver")]
interface LockInterface : Object {
    public abstract void lock () throws GLib.Error;
}

[DBus (name = "org.freedesktop.login1.User")]
interface UserInterface : Object {
    public abstract string state { owned get; }
}

[DBus (name = "org.freedesktop.DisplayManager.Seat")]
interface SeatInterface : Object {
    public abstract bool has_guest_account { get; }
    public abstract void switch_to_guest (string session_name) throws GLib.Error;
    public abstract void switch_to_user (string username, string session_name) throws GLib.Error;
}