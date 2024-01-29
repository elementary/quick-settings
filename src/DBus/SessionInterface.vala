/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.gnome.SessionManager")]
interface QuickSettings.SessionInterface : Object {
    public abstract async void logout (uint type) throws GLib.Error;
    public abstract async void reboot () throws GLib.Error;
    public abstract async void shutdown () throws GLib.Error;
}
