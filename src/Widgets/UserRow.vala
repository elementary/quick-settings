/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.UserRow : Gtk.ListBoxRow {
    private const int ICON_SIZE = 32;

    public Act.User? user { get; construct; default = null; }
    public string fullname { get; construct set; }
    public UserState state { get; private set; }

    public bool is_guest {
        get {
            return user == null;
        }
    }

    private Adw.Avatar avatar;
    private Gtk.Label fullname_label;
    private Gtk.Label status_label;

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
        fullname_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        status_label = new Gtk.Label (null) {
            valign = Gtk.Align.START,
            halign = Gtk.Align.START
        };
        status_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        status_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        if (user == null) {
            avatar = new Adw.Avatar (ICON_SIZE, null, false);

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
            avatar = new Adw.Avatar (ICON_SIZE, fullname, true);
            avatar.set_loadable_icon (get_avatar_icon ());

            user.changed.connect (() => {
                update_state.begin ();
            });
        }

        var grid = new Gtk.Grid () {
            column_spacing = 12
        };
        grid.attach (avatar, 0, 0, 1, 2);
        grid.attach (fullname_label, 1, 0, 1, 1);
        grid.attach (status_label, 1, 1, 1, 1);

        add_css_class ("menuitem");
        child = grid;

        update_state.begin ();
    }

    private GLib.LoadableIcon? get_avatar_icon () {
        var file = File.new_for_path (user.get_icon_file ());
        if (file.query_exists ()) {
            return new FileIcon (file);
        }

        return null;
    }

    public async UserState get_user_state () {
        if (is_guest) {
            return yield UserManager.get_guest_state ();
        } else {
            return yield UserManager.get_user_state (user.get_uid ());
        }
    }

    public async void update_state () {
        state = yield get_user_state ();

        selectable = state != UserState.ACTIVE;
        activatable = state != UserState.ACTIVE;

        if (state == UserState.ACTIVE || state == UserState.ONLINE) {
            status_label.label = _("Logged in");
        } else {
            status_label.label = _("Logged out");
        }

        if (user != null) {
            fullname_label.label = user.real_name;
            avatar.text = user.real_name;
            avatar.set_loadable_icon (get_avatar_icon ());
            sensitive = !user.locked;

            if (user.locked) {
                status_label.label = _("Locked");
            }
        }

        ((Gtk.ListBox) parent).invalidate_sort ();
    }

    public override bool draw (Cairo.Context ctx) {
        if (!get_selectable ()) {
            get_style_context ().set_state (Gtk.StateFlags.NORMAL);
        }

        return base.draw (ctx);
    }
}
