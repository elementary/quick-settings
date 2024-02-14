/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.PowerModeToggle: SettingsToggle {
    public PowerModeToggle () {
        Object (
            icon: new ThemedIcon ("quick-settings-powersaver-symbolic"),
            label: _("Power Saver")
        );
    }

    construct {
        settings_uri = "settings://power";

        bind_property ("active", this, "icon", SYNC_CREATE, (binding, srcval, ref targetval) => {
            if ((bool) srcval) {
                targetval = new ThemedIcon ("quick-settings-powersaver-symbolic");
            } else {
                targetval = new ThemedIcon ("quick-settings-powersaver-disabled-symbolic");
            }
            return true;
        });

        setup_power_profiles.begin ((obj, res) => {
            var power_profiles = setup_power_profiles.end (res);

            ((DBusProxy) power_profiles).g_properties_changed.connect ((changed, invalid) => {
                var active_profile = changed.lookup_value ("ActiveProfile", new VariantType ("s"));
                if (active_profile != null) {
                    active = active_profile.get_string () == "power-saver";
                }
            });

            active = power_profiles.active_profile == "power-saver";

            setup_upower.begin ((obj, res) => {
                var upower = setup_upower.end (res);

                notify["active"].connect (() => {
                    if (active) {
                        power_profiles.active_profile = "power-saver";
                    } else {
                        var power_settings = new Settings ("io.elementary.settings-daemon.power");
                        if (upower.on_battery) {
                            power_profiles.active_profile = power_settings.get_string ("profile-on-good-battery");
                        } else {
                            power_profiles.active_profile = power_settings.get_string ("profile-plugged-in");
                        }
                    }
                });
            });
        });
    }

    private async PowerProfiles? setup_power_profiles () {
        try {
            return yield Bus.get_proxy (BusType.SYSTEM, "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles");
        } catch (Error e) {
            info ("Unable to connect to PowerProfiles: %s", e.message);
            return null;
        }
    }

    private async UPower? setup_upower () {
        try {
            return yield Bus.get_proxy (BusType.SYSTEM, "org.freedesktop.UPower", "/org/freedesktop/UPower");
        } catch (Error e) {
            info ("Unable to connect to Upower: %s", e.message);
            return null;
        }
    }
}
