/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.DarkModeToggle: SettingsToggle {
    public DarkModeToggle () {
        Object (
            icon: new ThemedIcon ("dark-mode-symbolic"),
            label: _("Dark Mode")
        );
    }

    construct {
        settings_uri = "settings://desktop/appearance";

        var settings = new GLib.Settings ("org.gnome.desktop.interface");

        active = settings.get_enum ("color-scheme") == Granite.Settings.ColorScheme.DARK;
        settings.changed["color-scheme"].connect (() => {
            active = settings.get_enum ("color-scheme") == Granite.Settings.ColorScheme.DARK;
        });

        notify["active"].connect (() => {
            if (active) {
                settings.set_enum ("color-scheme", Granite.Settings.ColorScheme.DARK);
            } else {
                settings.set_enum ("color-scheme", Granite.Settings.ColorScheme.NO_PREFERENCE);
            }
        });
    }
}
