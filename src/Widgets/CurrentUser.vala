/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

 public class QuickSettings.CurrentUser : Gtk.Box {
    public bool minimal { get; construct; }
    public Act.User? user { get; set; default = null; }

    private Adw.Avatar avatar;
    private Gtk.Label fullname_label;
    private Gtk.Label status_label;
    private Gtk.Button logout_button;

    public signal void logout ();

    public bool is_guest {
        get {
            return user == null;
        }
    }

    public CurrentUser.avatar_only () {
        Object (minimal: true);
    }

    public CurrentUser () {
        Object (minimal: false);
    }

    construct {
        avatar = new Adw.Avatar (minimal ? 32 : 48, null, true);

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

        fullname_label = new Gtk.Label (null) {
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

        logout_button = new Gtk.Button.from_icon_name ("system-log-out-symbolic") {
            tooltip_text = _("Log Out…"),
            hexpand = true,
            halign = END,
            valign = CENTER
        };
        logout_button.get_style_context ().add_class ("circular");

        if (minimal) {
            add (avatar);
        } else {
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
        }

        if (UserManager.get_usermanager ().is_loaded) {
            update_current_user ();
        } else {
            UserManager.get_usermanager ().notify["is-loaded"].connect (() => {
                update_current_user ();
            });
        }

        UserManager.get_usermanager ().user_is_logged_in_changed.connect (() => {
            update_current_user ();
        });

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

    public void update_current_user () {
        user = UserManager.get_current_user ();

        if (user == null) {
            fullname_label.label = _("Guest");
            update_state.begin ();
        } else {
            user.changed.connect (() => {
                update ();
                update_state.begin ();
            });

            update ();
            update_state.begin ();
        }
    }

    private GLib.LoadableIcon? get_avatar_icon () {
        var file = File.new_for_path (user.get_icon_file ());
        if (file.query_exists ()) {
            return new FileIcon (file);
        }

        return null;
    }

    public async void update_state () {
        UserState state = yield get_user_state ();

        if (state == UserState.ACTIVE || state == UserState.ONLINE) {
            status_label.label = _("Logged in");
        } else {
            status_label.label = _("Logged out");
        }
    }

    public async UserState get_user_state () {
        if (is_guest) {
            return yield UserManager.get_guest_state ();
        } else {
            return yield UserManager.get_user_state (user.get_uid ());
        }
    }

    private void update () {
        if (user == null) {
            return;
        }

        fullname_label.label = user.real_name;
        avatar.text = user.real_name;
        avatar.set_loadable_icon (get_avatar_icon ());
    }
 }
