/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

 public class QuickSettings.CurrentUserButton : Gtk.Button {
    public Act.User? user { get; set; default = null; }

    private Hdy.Avatar avatar;
    private Act.UserManager manager;

    public CurrentUserButton () {
        Object (
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER
        );
    }

    construct {
        get_style_context ().add_class ("circular");
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("no-padding");

        avatar = new Hdy.Avatar (28, null, true);

        add (avatar);
        manager = Act.UserManager.get_default ();
        update_current_user ();
        manager.notify["is-loaded"].connect (() => {
            update_current_user ();
        });
    }

    public void update_current_user () {
        user = get_current_user ();
        if (user == null) {
            return;
        }

        avatar.text = user.real_name;
        avatar.set_image_load_func (avatar_image_load_func);
    }

    public Act.User? get_current_user () {
        if (!manager.is_loaded) {
            return null;
        }

        foreach (Act.User user in manager.list_users ()) {
            if (user.is_logged_in ()) {
                return user;
            }
        }

        return null;
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
 }