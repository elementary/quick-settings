/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.freedesktop.login1.Manager")]
interface QuickSettings.SystemInterface : Object {
    public abstract void suspend (bool interactive) throws GLib.Error;
    public abstract void reboot (bool interactive) throws GLib.Error;
    public abstract void power_off (bool interactive) throws GLib.Error;

    public abstract string can_suspend () throws GLib.Error;
}
