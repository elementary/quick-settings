/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public enum UserState {
    ACTIVE,
    ONLINE,
    OFFLINE;

    public static UserState to_enum (string state) {
        switch (state) {
            case "active":
                return UserState.ACTIVE;
            case "online":
                return UserState.ONLINE;
        }

        return UserState.OFFLINE;
    }
}

public class QuickSettings.UserManager : Object {
    private const string LOGIN_IFACE = "org.freedesktop.login1";
    private const string LOGIN_PATH = "/org/freedesktop/login1";

    private static SystemInterface? login_proxy;

    private static async void init_login_proxy () {
        try {
            login_proxy = yield Bus.get_proxy (BusType.SYSTEM, LOGIN_IFACE, LOGIN_PATH, DBusProxyFlags.NONE);
        } catch (IOError e) {
            critical ("Failed to create login1 dbus proxy: %s", e.message);
        }
    }

    public static async UserState get_user_state (uint32 uuid) {
        if (login_proxy == null) {
            yield init_login_proxy ();
        }

        try {
            UserInfo[] users = login_proxy.list_users ();
            if (users == null) {
                return UserState.OFFLINE;
            }

            foreach (UserInfo user in users) {
                if (user.uid == uuid) {
                    if (user.user_object == null) {
                        return UserState.OFFLINE;
                    }
                    UserInterface? user_interface = yield Bus.get_proxy (BusType.SYSTEM, LOGIN_IFACE, user.user_object, DBusProxyFlags.NONE);
                    if (user_interface == null) {
                        return UserState.OFFLINE;
                    }
                    return UserState.to_enum (user_interface.state);
                }
            }

        } catch (GLib.Error e) {
            critical ("Failed to get user state: %s", e.message);
        }

        return UserState.OFFLINE;
    }

    public static async UserState get_guest_state () {
        if (login_proxy == null) {
            return UserState.OFFLINE;
        }

        try {
            UserInfo[] users = login_proxy.list_users ();
            foreach (UserInfo user in users) {
                var state = yield get_user_state (user.uid);
                if (user.user_name.has_prefix ("guest-")
                    && state == UserState.ACTIVE) {
                    return UserState.ACTIVE;
                }
            }
        } catch (GLib.Error e) {
            critical ("Failed to get Guest state: %s", e.message);
        }

        return UserState.OFFLINE;
    }

    private static Act.UserManager? usermanager = null;
    public static unowned Act.UserManager? get_usermanager () {
        if (usermanager != null && usermanager.is_loaded) {
            return usermanager;
        }

        usermanager = Act.UserManager.get_default ();
        return usermanager;
    }

    public static Act.User? get_current_user () {
        Act.User? current_user = null;

        foreach (unowned Act.User user in get_usermanager ().list_users ()) {
            if (is_current_user (user)) {
                current_user = user;
                break;
            }
        }

        return current_user;
    }

    public static bool is_current_user (Act.User user) {
        return user.get_user_name () == GLib.Environment.get_user_name ();
    }

    public static async SessionInterface? setup_session_interface () {
        try {
            return yield Bus.get_proxy (BusType.SESSION, "org.gnome.SessionManager", "/org/gnome/SessionManager");
        } catch (IOError e) {
            critical ("Unable to connect to GNOME session interface: %s", e.message);
            return null;
        }
    }
}
