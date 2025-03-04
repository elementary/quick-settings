/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

 public class QuickSettings.UserList : Gtk.Box {
    public signal void switch_to_guest ();
    public signal void switch_to_user (string username);

    private const uint GUEST_USER_UID = 999;
    private const string DM_DBUS_ID = "org.freedesktop.DisplayManager";


    private SeatInterface? dm_proxy = null;
    private Gee.HashMap<uint, UserRow> user_map = new Gee.HashMap<uint, UserRow> ();

    private Gtk.ListBox listbox;
    private Gtk.Popover? popover;
    private Gtk.Revealer user_list_revealer;

    construct {
        var current_user = new UserRow (UserManager.get_current_user ());

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        listbox.set_sort_func (sort_func);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = NEVER,
            max_content_height = 200,
            propagate_natural_height = true,
            child = listbox
        };

        var settings_button = new Gtk.ModelButton () {
            text = _("User Accounts Settings…")
        };

        var user_list_vbox = new Gtk.Box (VERTICAL, 0);
        user_list_vbox.add (new Gtk.Separator (HORIZONTAL));
        user_list_vbox.add (listbox_scrolled);

        user_list_revealer = new Gtk.Revealer () {
            child = user_list_vbox,
            reveal_child = false
        };

        orientation = VERTICAL;
        add (current_user);
        add (user_list_revealer);
        add (new Gtk.Separator (HORIZONTAL));
        add (settings_button);

        if (UserManager.get_usermanager ().is_loaded) {
            init_users ();
        } else {
            UserManager.get_usermanager ().notify["is-loaded"].connect (() => {
                init_users ();
            });
        }

        UserManager.get_usermanager ().user_added.connect (add_user);
        UserManager.get_usermanager ().user_removed.connect (remove_user);
        UserManager.get_usermanager ().user_changed.connect (update_user);

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
        foreach (Act.User user in UserManager.get_usermanager ().list_users ()) {
            add_user (user);
        }
    }

    private void add_user (Act.User? user) {
        // Don't add any of the system reserved users
        if (user.is_system_account ()) {
            return;
        }

        var uid = user.get_uid ();
        if (user_map.has_key (uid)) {
            return;
        }

        if (UserManager.is_current_user (user)) {
            return;
        }

        user_map[uid] = new UserRow (user);
        user_map[uid].show ();

        listbox.add (user_map[uid]);
        user_list_revealer.reveal_child = listbox.get_row_at_index (0) != null;
    }

    private void add_guest () {
        if (user_map[GUEST_USER_UID] != null) {
            return;
        }

        // Current user is guest
        if (UserManager.get_current_user () == null) {
            return;
        }

        user_map[GUEST_USER_UID] = new UserRow (null);
        user_map[GUEST_USER_UID].show ();

        listbox.add (user_map[GUEST_USER_UID]);
        user_list_revealer.reveal_child = listbox.get_row_at_index (0) != null;
    }

    private void remove_user (Act.User user) {
        var uid = user.get_uid ();
        var user_row = user_map[uid];
        if (user_row == null) {
            return;
        }

        user_map.unset (uid);
        listbox.remove (user_row);
        listbox.invalidate_sort ();
        user_list_revealer.reveal_child = listbox.get_row_at_index (0) != null;
    }

    private void update_user (Act.User user) {
        var userbox = user_map[user.get_uid ()];
        if (userbox == null) {
            return;
        }

        userbox.update_state.begin ();
        user_list_revealer.reveal_child = listbox.get_row_at_index (0) != null;
    }

    public void update_all () {
        foreach (UserRow row in user_map.values) {
            row.update_state.begin ();
        }
    }

    public int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        var userbox1 = (UserRow) row1;
        var userbox2 = (UserRow) row2;

        if (userbox1.is_guest && !userbox2.is_guest) {
            return 1;
        } else if (!userbox1.is_guest && userbox2.is_guest) {
            return -1;
        }

        return userbox1.user.collate (userbox2.user);
    }

    private void show_settings () {
        try {
            AppInfo.launch_default_for_uri ("settings://accounts", null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }
 }
