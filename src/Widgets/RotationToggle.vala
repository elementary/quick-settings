/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.RotationToggle: SettingsToggle {
    public RotationToggle () {
        Object (
            icon: new ThemedIcon ("rotation-locked-symbolic"),
            label: _("Rotation Lock")
        );
    }

    construct {
        settings_uri = "settings://display";

        var touchscreen_settings = new Settings ("org.gnome.settings-daemon.peripherals.touchscreen");
        touchscreen_settings.bind ("orientation-lock", this, "active", DEFAULT);
    }
}
