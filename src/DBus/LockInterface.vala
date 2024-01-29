/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

/* Power and system control */
[DBus (name = "org.gnome.ScreenSaver")]
interface QuickSettings.LockInterface : Object {
    public abstract void lock () throws GLib.Error;
}
