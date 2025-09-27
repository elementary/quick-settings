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
        var lock_image = new Gtk.Image ();
        lock_image.get_style_context ().add_class ("lock");

        var arrow_image = new Gtk.Image.from_icon_name ("quick-settings-rotation-arrow-symbolic", BUTTON);
        arrow_image.get_style_context ().add_class ("arrow");

        var overlay = new Gtk.Overlay () {
            child = lock_image
        };
        overlay.add_overlay (arrow_image);
        overlay.set_overlay_pass_through (arrow_image, true);
        overlay.set_overlay_pass_through (lock_image, true);

        button_child = overlay;

        get_style_context ().add_class ("rotation");
        settings_uri = "settings://display";

        var touchscreen_settings = new Settings ("org.gnome.settings-daemon.peripherals.touchscreen");
        touchscreen_settings.bind ("orientation-lock", this, "active", DEFAULT);

        bind_property ("active", lock_image, "icon-name", SYNC_CREATE, (binding, srcval, ref targetval) => {
            if ((bool) srcval) {
                targetval = "quick-settings-rotation-locked-symbolic";
            } else {
                targetval = "quick-settings-rotation-allowed-symbolic";
            }
            return true;
        });
    }
}
