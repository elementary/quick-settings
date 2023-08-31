/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.DarkModeToggle: SettingsToggle {
    public Pantheon.AccountsService pantheon_service { get; construct; }

    public DarkModeToggle (Pantheon.AccountsService pantheon_service) {
        Object (
            pantheon_service: pantheon_service,
            icon: new ThemedIcon ("dark-mode-symbolic"),
            label: _("Dark Mode")
        );
    }

    construct {
        settings_uri = "settings://desktop/appearance";

        active = pantheon_service.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        var settings = new Settings ("io.elementary.settings-daemon.prefers-color-scheme");

        notify["active"].connect (() => {
            settings.set_string ("prefer-dark-schedule", "disabled");

            if (active) {
                pantheon_service.prefers_color_scheme = Granite.Settings.ColorScheme.DARK;
            } else {
                pantheon_service.prefers_color_scheme = Granite.Settings.ColorScheme.NO_PREFERENCE;
            }
        });

        ((DBusProxy) pantheon_service).g_properties_changed.connect ((changed, invalid) => {
            var color_scheme = changed.lookup_value ("PrefersColorScheme", new VariantType ("i"));
            if (color_scheme != null) {
                active = (Granite.Settings.ColorScheme) color_scheme.get_int32 () == Granite.Settings.ColorScheme.DARK;
            }
        });
    }
}
