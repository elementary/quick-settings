/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.UserRow : Gtk.ListBoxRow {
    public signal void logout ();

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

    public UserRow (Act.User? user) {
        Object (user: user);
    }

    construct {
        fullname_label = new Gtk.Label (fullname) {
            valign = Gtk.Align.END,
            halign = Gtk.Align.START
        };
        fullname_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        status_label = new Gtk.Label (null) {
            valign = Gtk.Align.START,
            halign = Gtk.Align.START
        };
        status_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        status_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var pixel_size = user == UserManager.get_current_user () ? 48 : 32;

        if (user == null) {
            avatar = new Hdy.Avatar (pixel_size, null, false);

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
            avatar = new Hdy.Avatar (pixel_size, fullname, true);
            avatar.set_loadable_icon (get_avatar_icon ());

            user.changed.connect (() => {
                update_state.begin ();
            });
        }

        var grid = new Gtk.Grid () {
            column_spacing = 12
        };
        grid.attach (avatar, 0, 0, 1, 2);
        grid.attach (fullname_label, 1, 0);
        grid.attach (status_label, 1, 1);

        get_style_context ().add_class ("menuitem");
        child = grid;

        if (user == UserManager.get_current_user ()) {
            var logout_button = new Gtk.Button.from_icon_name ("system-log-out-symbolic") {
                tooltip_text = _("Log Out…"),
                hexpand = true,
                halign = END,
                valign = CENTER
            };
            logout_button.get_style_context ().add_class ("circular");

            grid.attach (logout_button, 2, 0, 2, 2);

            var keybinding_settings = new Settings ("org.gnome.settings-daemon.plugins.media-keys");

            logout_button.tooltip_markup = Granite.markup_accel_tooltip (
                keybinding_settings.get_strv ("logout"), _("Log Out…")
            );

            keybinding_settings.changed["logout"].connect (() => {
                logout_button.tooltip_markup = Granite.markup_accel_tooltip (
                    keybinding_settings.get_strv ("logout"), _("Log Out…")
                );
            });

            logout_button.clicked.connect (() => {
                logout ();
            });
        }

        show_all ();
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
        } else {
            fullname = _("Guest");
        }

        ((Gtk.ListBox) parent).invalidate_sort ();

        show_all ();
    }

    public override bool draw (Cairo.Context ctx) {
        if (!get_selectable ()) {
            get_style_context ().set_state (Gtk.StateFlags.NORMAL);
        }

        return base.draw (ctx);
    }
}
