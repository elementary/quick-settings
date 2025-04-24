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
        action_name = "quick-settings.rotation-lock";
        settings_uri = "settings://display";

        var settings = new Settings ("org.gnome.settings-daemon.peripherals.touchscreen");

        var rotation_lock_action = new SimpleAction.stateful (
            "rotation-lock",
            null,
            settings.get_boolean ("orientation-lock")
        );

        rotation_lock_action.activate.connect (() => {
            settings.set_boolean ("orientation-lock", !settings.get_boolean ("orientation-lock"));
        });

        settings.changed["orientation-lock"].connect (() => {
            rotation_lock_action.set_state (settings.get_boolean ("orientation-lock"));
        });

        rotation_lock_action.change_state.connect ((value) => {
            if (value.get_boolean ()) {
                icon = new ThemedIcon ("quick-settings-rotation-locked-symbolic");
            } else {
                icon = new ThemedIcon ("quick-settings-rotation-allowed-symbolic");
            }
        });

        map.connect (() => {
            var action_group = (SimpleActionGroup) get_action_group ("quick-settings");
            action_group.add_action (rotation_lock_action);
        });
    }
}
