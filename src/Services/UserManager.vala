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
    private static string? active_user_real_name;

    public static async UserState get_user_state (uid_t uuid) {
        try {
            var users = Login1Manager.get_default ().proxy.list_users ();
            if (users == null) {
                return UserState.OFFLINE;
            }

            foreach (var user in users) {
                if (((uid_t) user.uid) != uuid) {
                    continue;
                }

                if (user.user_object == null) {
                    return UserState.OFFLINE;
                }

                var user_interface = yield Bus.get_proxy<UserInterface> (
                    SYSTEM,
                    "org.freedesktop.login1",
                    user.user_object
                );
                if (user_interface == null) {
                    return UserState.OFFLINE;
                }

                return UserState.to_enum (user_interface.state);
            }
        } catch (GLib.Error e) {
            critical ("Failed to get user state: %s", e.message);
        }

        return UserState.OFFLINE;
    }

    public static async UserState get_guest_state () {
        try {
            var users = Login1Manager.get_default ().proxy.list_users ();
            foreach (var user in users) {
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

    public static async string? get_loggedin_tooltip_markup () {
        if (active_user_real_name == null) {
            active_user_real_name = Environment.get_real_name ();
        }

        if (active_user_real_name == null) {
            return null;
        }

        var tooltip_markup = _("Logged in as “%s”").printf (active_user_real_name);

        if (!get_usermanager ().is_loaded) {
            critical ("UserManager not yet loaded");
            return tooltip_markup;
        }

        var active_and_online_users = 0;
        foreach (unowned var user in get_usermanager ().list_users ()) {
            if (user.system_account) {
                continue;
            }

            var state = yield get_user_state (user.uid);
            if (state == ACTIVE || state == ONLINE) {
                active_and_online_users++;
            }
        }

        var other_users = active_and_online_users - 1;
        if (other_users > 0) {
            var description = dngettext (
                Constants.GETTEXT_PACKAGE,
                "%i other person logged in",
                "%i other people logged in",
                other_users
            );
            description = description.printf (other_users);
            tooltip_markup += "\n" + Granite.TOOLTIP_SECONDARY_TEXT_MARKUP.printf (description);
        }

        return tooltip_markup;
    }
}
