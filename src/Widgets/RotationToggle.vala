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
        action_name = "quick-settings.orientation-lock";
        icon_name = "quick-settings-rotation-locked-symbolic";
        settings_uri = "settings://display";

        var settings = new Settings ("org.gnome.settings-daemon.peripherals.touchscreen");
        var rotation_lock_action = settings.create_action ("orientation-lock");

        rotation_lock_action.notify["state"].connect (() => {
            if (rotation_lock_action.state.get_boolean ()) {
                icon_name = "quick-settings-rotation-locked-symbolic";
            } else {
                icon_name = "quick-settings-rotation-allowed-symbolic";
            }
        });

        map.connect (() => {
            var action_group = (SimpleActionGroup) get_action_group ("quick-settings");
            action_group.add_action (rotation_lock_action);
        });
    }
}
