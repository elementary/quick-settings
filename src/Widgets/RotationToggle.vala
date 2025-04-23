/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.RotationToggle: SettingsToggle {
    public RotationToggle () {
        Object (
            label: _("Rotation Lock")
        );
    }

    construct {
        icon_name = "quick-settings-rotation-locked-symbolic";
        settings_uri = "settings://display";

        var touchscreen_settings = new Settings ("org.gnome.settings-daemon.peripherals.touchscreen");
        touchscreen_settings.bind ("orientation-lock", this, "active", DEFAULT);

        bind_property ("active", this, "icon-name", SYNC_CREATE, (binding, srcval, ref targetval) => {
            if ((bool) srcval) {
                targetval = "quick-settings-rotation-locked-symbolic";
            } else {
                targetval = "quick-settings-rotation-allowed-symbolic";
            }
            return true;
        });
    }
}
