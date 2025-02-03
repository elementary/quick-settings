/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

 public class QuickSettings.UserList : Gtk.Box {
    public signal void switch_to_guest ();
    public signal void switch_to_user (string username);

    private const string DM_DBUS_ID = "org.freedesktop.DisplayManager";
    private const uint GUEST_USER_UID = 999;

    private GLib.ListStore user_list;
    private Gtk.Popover? popover;
    private SeatInterface? dm_proxy = null;

    construct {
        var current_user = new CurrentUser ();

        user_list = new GLib.ListStore (typeof (Act.User));

        var listbox = new Gtk.ListBox () {
            hexpand = true
        };
        listbox.bind_model (user_list, create_widget_func);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = NEVER,
            max_content_height = 200,
            propagate_natural_height = true,
            child = listbox
        };

        var settings_button = new Gtk.ModelButton () {
            text = _("User Accounts Settings…")
        };

        var main_box = new Gtk.Box (VERTICAL, 0);
        main_box.add (current_user);
        main_box.add (new Gtk.Separator (HORIZONTAL));
        main_box.add (listbox_scrolled);
        main_box.add (new Gtk.Separator (HORIZONTAL));
        main_box.add (settings_button);

        add (main_box);

        if (UserManager.get_usermanager ().is_loaded) {
            init_users ();
        } else {
            UserManager.get_usermanager ().notify["is-loaded"].connect (() => {
                init_users ();
            });
        }

        UserManager.get_usermanager ().user_added.connect (add_user);
        UserManager.get_usermanager ().user_removed.connect (remove_user);
        UserManager.get_usermanager ().user_is_logged_in_changed.connect (current_user.update_current_user);

        var seat_path = Environment.get_variable ("XDG_SEAT_PATH");
        var session_path = Environment.get_variable ("XDG_SESSION_PATH");

        if (seat_path != null) {
            try {
                dm_proxy = Bus.get_proxy_sync (BusType.SYSTEM, DM_DBUS_ID, seat_path, DBusProxyFlags.NONE);

                if (dm_proxy.has_guest_account && UserManager.get_current_user () != null) {
                    add_guest ();
                }
            } catch (IOError e) {
                critical ("UserManager error: %s", e.message);
            }
        }

        if (dm_proxy != null) {
            switch_to_guest.connect (() => {
                try {
                    dm_proxy.switch_to_guest ("");
                } catch (Error e) {
                    warning ("Error switching to guest account: %s", e.message);
                }
            });

            switch_to_user.connect ((username) => {
                try {
                    dm_proxy.switch_to_user (username, session_path);
                } catch (Error e) {
                    warning ("Error switching to user '%s': %s", username, e.message);
                }
            });
        }

        listbox.row_activated.connect ((row) => {
            var userbox = (UserRow) row;
            if (userbox == null) {
                return;
            }

            popover.popdown ();

            if (userbox.is_guest) {
                switch_to_guest ();
            } else {
                var user = userbox.user;
                if (user != null) {
                    switch_to_user (user.get_user_name ());
                }
            }
        });

        settings_button.clicked.connect (() => {
            show_settings ();
        });

        realize.connect (() => {
            popover = (Gtk.Popover) get_ancestor (typeof (Gtk.Popover));
        });

        UserManager.setup_session_interface.begin ((obj, res) => {
            var session_interface = UserManager.setup_session_interface.end (res);

            current_user.logout.connect (() => {
                popover.popdown ();

                session_interface.logout.begin (0, (obj, res) => {
                    try {
                        session_interface.logout.end (res);
                    } catch (Error e) {
                        if (!(e is GLib.IOError.CANCELLED)) {
                            warning ("Unable to open logout dialog: %s", e.message);
                        }
                    }
                });
            });
        });
    }

    private void init_users () {
        foreach (unowned var user in UserManager.get_usermanager ().list_users ()) {
            add_user (user);
        }
    }

    private void add_user (Act.User? user) {
        // FIXME: is this not covered by is current?
        // if (user_row.is_guest) {
        //     return UserManager.get_current_user () != null;
        // }

        if (UserManager.is_current_user (user)) {
            return;
        }

        // Don't add any of the system reserved users
        if (user.is_system_account ()) {
            return;
        }

        uint pos = -1;
        if (user_list.find_with_equal_func (user, equal_func, out pos)) {
            return;
        }

        user_list.insert_sorted (user, compare_func);
    }

    private void add_guest () {
        
    }

    private void remove_user (Act.User user) {
        uint pos = -1;
        if (user_list.find_with_equal_func (user, (EqualFunc<Act.User>) equal_func, out pos)) {
            user_list.remove (pos);
        }
    }

    private Gtk.Widget create_widget_func (Object object) {
        var user = (Act.User) object;

        if (user.uid == GUEST_USER_UID) {
            return new UserRow.guest ();
        }

        return new UserRow (user);
    }

    private int compare_func (Object a, Object b) {
        var user_a = (Act.User) a;
        var user_b = (Act.User) b;

        //TODO: handle guest?

        return user_a.collate (user_b);
    }

    private static bool equal_func (Object a, Object b) {
        return ((Act.User) a).uid == ((Act.User) b).uid;
    }

    private void show_settings () {
        try {
            AppInfo.launch_default_for_uri ("settings://accounts", null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }
 }
