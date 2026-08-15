/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

 public class QuickSettings.AvatarButton : Granite.Bin {
    private Act.User? user = null;
    private Adw.Avatar avatar;

    construct {
        avatar = new Adw.Avatar (32, null, true);

        // We want to use the user's accent, not a random color
        avatar.remove_css_class ("color1");
        avatar.remove_css_class ("color2");
        avatar.remove_css_class ("color3");
        avatar.remove_css_class ("color4");
        avatar.remove_css_class ("color5");
        avatar.remove_css_class ("color6");
        avatar.remove_css_class ("color7");
        avatar.remove_css_class ("color8");
        avatar.remove_css_class ("color9");
        avatar.remove_css_class ("color10");
        avatar.remove_css_class ("color11");
        avatar.remove_css_class ("color12");
        avatar.remove_css_class ("color13");
        avatar.remove_css_class ("color14");

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

    private Gdk.Texture? get_avatar_icon () {
        try {
            return Gdk.Texture.from_filename (user.get_icon_file ());
        } catch {
            return null;
        }
    }

    private void update () {
        if (user == null) {
            return;
        }

        avatar.text = user.real_name;
        avatar.custom_image = get_avatar_icon ();
    }
 }
