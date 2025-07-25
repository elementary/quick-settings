/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

 public class QuickSettings.AvatarButton : Gtk.Box {
    private Act.User? user = null;
    private Hdy.Avatar avatar;

    construct {
        avatar = new Hdy.Avatar (32, null, true);

        // We want to use the user's accent, not a random color
        avatar.get_style_context ().remove_class ("color1");
        avatar.get_style_context ().remove_class ("color2");
        avatar.get_style_context ().remove_class ("color3");
        avatar.get_style_context ().remove_class ("color4");
        avatar.get_style_context ().remove_class ("color5");
        avatar.get_style_context ().remove_class ("color6");
        avatar.get_style_context ().remove_class ("color7");
        avatar.get_style_context ().remove_class ("color8");
        avatar.get_style_context ().remove_class ("color9");
        avatar.get_style_context ().remove_class ("color10");
        avatar.get_style_context ().remove_class ("color11");
        avatar.get_style_context ().remove_class ("color12");
        avatar.get_style_context ().remove_class ("color13");
        avatar.get_style_context ().remove_class ("color14");

        child = avatar;

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
    }

    private void update_current_user () {
        user = UserManager.get_current_user ();

        if (user != null) {
            user.changed.connect (() => {
                update ();
            });

            update ();
        }
    }

    private GLib.LoadableIcon? get_avatar_icon () {
        var file = File.new_for_path (user.get_icon_file ());
        if (file.query_exists ()) {
            return new FileIcon (file);
        }

        return null;
    }

    private void update () {
        if (user == null) {
            return;
        }

        avatar.text = user.real_name;
        avatar.set_loadable_icon (get_avatar_icon ());
    }
 }
