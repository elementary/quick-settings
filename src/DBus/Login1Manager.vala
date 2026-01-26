/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024-2026 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.Login1Manager : Object {
    public struct UserInfo {
        uint32 uid;
        string user_name;
        ObjectPath? user_object;
    }

    [DBus (name = "org.freedesktop.login1.Manager")]
    public interface Login1ManagerInterface : Object {
        public abstract void suspend (bool interactive) throws GLib.Error;
        public abstract void reboot (bool interactive) throws GLib.Error;
        public abstract void power_off (bool interactive) throws GLib.Error;
        public abstract void reboot_with_flags (uint64 flags) throws GLib.Error;
        public abstract void power_off_with_flags (uint64 flags) throws GLib.Error;

        public abstract UserInfo[] list_users () throws GLib.Error;
        public abstract string can_suspend () throws GLib.Error;
    }

    public Login1ManagerInterface proxy { get; private set; }

    private static GLib.Once<Login1Manager> instance;
    public static unowned Login1Manager get_default () {
        return instance.once (() => new Login1Manager ());
    }

    private Login1Manager () {}

    construct {
        try {
            object = Bus.get_proxy_sync<Login1ManagerInterface> (
                SYSTEM,
                "org.freedesktop.login1",
                "/org/freedesktop/login1"
            );
        } catch (Error e) {
            critical (e.message);
        }
    }
}
