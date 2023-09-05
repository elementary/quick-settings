/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.RotationToggle: SettingsToggle {
    public RotationToggle () {
        Object (
            icon: new ThemedIcon ("quick-settings-rotation-locked-symbolic"),
            label: _("Rotation Lock")
        );
    }

    construct {
        settings_uri = "settings://display";

        var touchscreen_settings = new Settings ("org.gnome.settings-daemon.peripherals.touchscreen");
        touchscreen_settings.bind ("orientation-lock", this, "active", DEFAULT);

        bind_property ("active", this, "icon", SYNC_CREATE, (binding, srcval, ref targetval) => {
            if ((bool) srcval) {
                targetval = new ThemedIcon ("quick-settings-rotation-locked-symbolic");
            } else {
                targetval = new ThemedIcon ("quick-settings-rotation-allowed-symbolic");
            }
            return true;
        });
    }
}
