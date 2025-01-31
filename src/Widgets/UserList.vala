/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

 public class QuickSettings.UserList : Gtk.Box {
    private Gtk.ListBox listbox;

    private Act.UserManager manager;
    private SeatInterface? dm_proxy = null;

    private const string DM_DBUS_ID = "org.freedesktop.DisplayManager";

    private Gee.HashMap<uint, UserRow> user_map = new Gee.HashMap<uint, UserRow> ();

    private const uint GUEST_USER_UID = 999;
    private const uint NOBODY_USER_UID = 65534;
    private const uint RESERVED_UID_RANGE_END = 1000;

    public signal void close ();
    public signal void switch_to_guest ();
    public signal void switch_to_user (string username);

    construct {
        var user_manager = new Services.UserManager ();

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        listbox.set_sort_func (sort_func);
        listbox.set_header_func (header_func);

        var settings_button = new Gtk.ModelButton () {
            text = _("User Accounts Settings…")
        };

        var main_box = new Gtk.Box (VERTICAL, 0);
        main_box.add (listbox);
        main_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3
        });
        main_box.add (settings_button);

        add (main_box);

        manager = Act.UserManager.get_default ();

        init_users ();

        manager.user_added.connect (add_user);
        manager.user_removed.connect (remove_user);
        manager.user_is_logged_in_changed.connect (update_user);
        
        manager.notify["is-loaded"].connect (() => {
            init_users ();
        });

        listbox.row_activated.connect ((row) => {
            var userbox = (UserRow) row;
            if (userbox == null) {
                return;
            }

            close ();
            if (userbox.is_guest) {
                switch_to_guest ();
            } else {
                var user = userbox.user;
                if (user != null) {
                    switch_to_user (user.get_user_name ());
                }
            }
        });

        var seat_path = Environment.get_variable ("XDG_SEAT_PATH");
        var session_path = Environment.get_variable ("XDG_SESSION_PATH");

        if (seat_path != null) {
            try {
                dm_proxy = Bus.get_proxy_sync (BusType.SYSTEM, DM_DBUS_ID, seat_path, DBusProxyFlags.NONE);
                if (dm_proxy.has_guest_account) {
                    add_guest ();
                }
            } catch (IOError e) {
                critical ("UserManager error: %s", e.message);
            }
        }

        settings_button.clicked.connect (() => {
            show_settings ();
        });
    }

    private void init_users () {
        if (!manager.is_loaded) {
            return;
        }

        foreach (Act.User user in manager.list_users ()) {
            add_user (user);
        }
    }

    private void add_user (Act.User? user) {
        // Don't add any of the system reserved users
        var uid = user.get_uid ();
        if (uid < RESERVED_UID_RANGE_END || uid == NOBODY_USER_UID || user_map.has_key (uid)) {
            return;
        }

        user_map[uid] = new UserRow (user);
        user_map[uid].show ();
        listbox.add (user_map[uid]);
    }

    private void add_guest () {
        if (user_map[GUEST_USER_UID] != null) {
            return;
        }

        user_map[GUEST_USER_UID] = new UserRow.guest ();
        user_map[GUEST_USER_UID].show ();

        listbox.add (user_map[GUEST_USER_UID]);
    }

    private void remove_user (Act.User user) {
        var uid = user.get_uid ();
        var user_row = user_map[uid];
        if (user_row == null) {
            return;
        }

        user_map.unset (uid);
        listbox.remove (user_row);
    }

    private void update_user (Act.User user) {
        var user_row = user_map[user.get_uid ()];
        if (user_row == null) {
            return;
        }

        user_row.update_state.begin ();
    }

    // We could use here Act.User.collate () but we want to show the logged user first
    public int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        var userbox1 = (UserRow) row1;
        var userbox2 = (UserRow) row2;

        if (userbox1.state == UserState.ACTIVE) {
            return -1;
        } else if (userbox2.state == UserState.ACTIVE) {
            return 1;
        }

        if (userbox1.is_guest && !userbox2.is_guest) {
            return 1;
        } else if (!userbox1.is_guest && userbox2.is_guest) {
            return -1;
        }

        return 0;
    }

    private void header_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        if (row == listbox.get_row_at_index (1)) {
            row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        }
    }

    private void show_settings () {
        try {
            AppInfo.launch_default_for_uri ("settings://accounts", null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }
 }