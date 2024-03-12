/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.TextScale : Gtk.Box {
    private Gtk.Button zoom_button;
    private Settings interface_settings;

    class construct {
        set_css_name ("scalebox");
    }

    construct {
        zoom_button = new Gtk.Button.from_icon_name ("quick-settings-text-small-symbolic");
        zoom_button.get_style_context ().add_class ("toggle");

        var zoom_adjustment = new Gtk.Adjustment (-1, 0.75, 1.75, 0.05, 0, 0);

        var zoom_scale = new Gtk.Scale (HORIZONTAL, zoom_adjustment) {
            draw_value = false,
            hexpand = true
        };

        add (zoom_button);
        add (zoom_scale);

        interface_settings = new Settings ("org.gnome.desktop.interface");
        interface_settings.bind ("text-scaling-factor", zoom_adjustment, "value", DEFAULT);
        interface_settings.changed["text-scaling-factor"].connect (update_zoom_buttons);
        update_zoom_buttons ();

        zoom_button.clicked.connect (() => {
            if (zoom_adjustment.value > 1) {
                zoom_adjustment.value = 1;
            } else {
                zoom_adjustment.value = 1.25;
            }
        });
    }

    private void update_zoom_buttons () {
        var scaling_factor = interface_settings.get_double ("text-scaling-factor");
        if (scaling_factor > 1) {
            ((Gtk.Image) zoom_button.image).icon_name = "quick-settings-text-large-symbolic";
            zoom_button.tooltip_text = _("Decrease text size");
        } else {
            ((Gtk.Image) zoom_button.image).icon_name = "quick-settings-text-small-symbolic";
            zoom_button.tooltip_text = _("Increase text size");
        }
    }
}
