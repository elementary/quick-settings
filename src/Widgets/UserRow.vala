/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.UserRow : Gtk.ListBoxRow {
    private const int ICON_SIZE = 32;
    private const int ICON_MAIN_SIZE = 48;

    public Act.User? user { get; construct; default = null; }
    public string fullname { get; construct set; }
    public UserState state { get; private set; }

    public bool is_guest {
        get {
            return user == null;
        }
    }

    private Hdy.Avatar avatar;
    private Gtk.Label fullname_label;
    private Gtk.Label status_label;
    private Gtk.Button logout_button;

    public UserRow (Act.User user) {
        Object (
            user: user
        );
    }

    public UserRow.guest () {
        Object (
            fullname: _("Guest")
        );
    }

    construct {
        fullname_label = new Gtk.Label (fullname) {
            valign = Gtk.Align.END,
            halign = Gtk.Align.START
        };
        fullname_label.get_style_context ().add_class ("fullname-label");

        status_label = new Gtk.Label (null) {
            valign = Gtk.Align.START,
            halign = Gtk.Align.START
        };

        logout_button = new Gtk.Button.from_icon_name ("system-log-out-symbolic") {
            tooltip_text = _("Log Out…"),
            hexpand = true,
            halign = END,
            valign = CENTER
        };
        logout_button.get_style_context ().add_class ("circular");

        if (user == null) {
            avatar = new Hdy.Avatar (ICON_SIZE, null, false);
            // We want to use the user's accent, not a random color
            unowned Gtk.StyleContext avatar_context = avatar.get_style_context ();
            avatar_context.remove_class ("color1");
            avatar_context.remove_class ("color2");
            avatar_context.remove_class ("color3");
            avatar_context.remove_class ("color4");
            avatar_context.remove_class ("color5");
            avatar_context.remove_class ("color6");
            avatar_context.remove_class ("color7");
            avatar_context.remove_class ("color8");
            avatar_context.remove_class ("color9");
            avatar_context.remove_class ("color10");
            avatar_context.remove_class ("color11");
            avatar_context.remove_class ("color12");
            avatar_context.remove_class ("color13");
            avatar_context.remove_class ("color14");
        } else {
            avatar = new Hdy.Avatar (ICON_SIZE, fullname, true);
            avatar.set_image_load_func (avatar_image_load_func);

            user.changed.connect (() => {
                update ();
                update_state.begin ();
            });

            user.bind_property ("locked", this, "visible", BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
            user.bind_property ("locked", this, "no-show-all", BindingFlags.SYNC_CREATE);
            user.bind_property ("real-name", avatar, "text", BindingFlags.SYNC_CREATE);

            update ();
        }

        var grid = new Gtk.Grid () {
            column_spacing = 12
        };
        grid.attach (avatar, 0, 0, 1, 2);
        grid.attach (fullname_label, 1, 0, 1, 1);
        grid.attach (status_label, 1, 1, 1, 1);
        grid.attach (logout_button, 2, 0, 2, 2);
        grid.show_all ();

        get_style_context ().add_class ("menuitem");
        add (grid);

        update_state.begin ();
    }

    private Gdk.Pixbuf? avatar_image_load_func (int size) {
        try {
            var pixbuf = new Gdk.Pixbuf.from_file (user.get_icon_file ());
            return pixbuf.scale_simple (size, size, Gdk.InterpType.BILINEAR);
        } catch (Error e) {
            debug (e.message);
            return null;
        }
    }

    public async UserState get_user_state () {
        if (is_guest) {
            return yield Services.UserManager.get_guest_state ();
        } else {
            return yield Services.UserManager.get_user_state (user.get_uid ());
        }
    }

    private void update () {
        if (user == null) {
            return;
        }

        fullname_label.label = user.real_name;
        avatar.set_image_load_func (avatar_image_load_func);
    }

    public async void update_state () {
        state = yield get_user_state ();

        selectable = state != UserState.ACTIVE;
        activatable = state != UserState.ACTIVE;

        if (state == UserState.ONLINE || state == UserState.ACTIVE) {
            status_label.label = _("Logged in");
            logout_button.visible = true;
            logout_button.no_show_all = false;
            avatar.size = ICON_MAIN_SIZE;
        } else {
            status_label.label = _("Logged out");
            logout_button.visible = false;
            logout_button.no_show_all = true;
            avatar.size = ICON_SIZE;
        }

        show_all ();
    }

    public override bool draw (Cairo.Context ctx) {
        if (!get_selectable ()) {
            get_style_context ().set_state (Gtk.StateFlags.NORMAL);
        }

        return base.draw (ctx);
    }
}