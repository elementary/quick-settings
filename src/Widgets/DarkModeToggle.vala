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
        action_name = "quick-settings.dark-mode";
        icon_name = "dark-mode-symbolic";
        settings_uri = "settings://desktop/appearance";

        var settings = new GLib.Settings ("io.elementary.settings-daemon.prefers-color-scheme");

        var dark_mode_action = new SimpleAction.stateful (
            "dark-mode",
            null,
            new Variant.boolean (settings.get_enum ("color-scheme") == Granite.Settings.ColorScheme.DARK)
        );

        dark_mode_action.activate.connect (() => {
            if (settings.get_enum ("color-scheme") == Granite.Settings.ColorScheme.DARK) {
                settings.set_enum ("color-scheme", Granite.Settings.ColorScheme.NO_PREFERENCE);
            } else {
                settings.set_enum ("color-scheme", Granite.Settings.ColorScheme.DARK);
            }
        });

        settings.changed["color-scheme"].connect (() => {
            dark_mode_action.set_state (
                new Variant.boolean (settings.get_enum ("color-scheme") == Granite.Settings.ColorScheme.DARK)
            );
        });

        map.connect (() => {
            var action_group = (SimpleActionGroup) get_action_group ("quick-settings");
            action_group.add_action (dark_mode_action);
        });
    }
}
