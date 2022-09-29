/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.MainWidget : Gtk.Box {
    construct {
        var button = new Gtk.Button.with_label (_("System Settings…"));
        button.add_css_class (Granite.STYLE_CLASS_MENUITEM);

        button.get_first_child ().halign = Gtk.Align.START;

        margin_top = 3;
        margin_bottom = 3;
        append (button);


        button.clicked.connect (() => {
            var appinfo = new DesktopAppInfo ("io.elementary.settings.desktop");
            try {
                appinfo.launch (null, null);
                ((Gtk.Popover) get_ancestor (typeof (Gtk.Popover))).popdown ();
            } catch (Error e) {
                critical ("couldn't launch settings: %s", e.message);
            }

        });
    }
}
