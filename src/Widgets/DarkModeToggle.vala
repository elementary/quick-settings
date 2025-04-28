/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.DarkModeToggle: SettingsToggle {
    public DarkModeToggle () {
        Object (
            label: _("Dark Mode")
        );
    }

    construct {
        icon_name = "dark-mode-symbolic";
        settings_uri = "settings://desktop/appearance";

        var settings = new GLib.Settings ("io.elementary.settings-daemon.prefers-color-scheme");

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
