/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.PopoverWidget : Gtk.Box {
    public signal void close ();

    class construct {
        set_css_name ("quicksettings");
    }

    construct {
        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic", MENU) {
            halign = START,
            hexpand = true,
            tooltip_text = _("System Settings…")
        };
        settings_button.get_style_context ().add_class ("circular");

        add (settings_button);

        settings_button.clicked.connect (() => {
            close ();

            try {
                AppInfo.launch_default_for_uri ("settings://", null);
            } catch (Error e) {
                critical ("Failed to open system settings: %s", e.message);
            }
        });
    }
}
