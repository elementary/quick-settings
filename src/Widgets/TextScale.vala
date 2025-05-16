/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.TextScale : Gtk.Box {
    private Gtk.Button zoom_in_button;
    private Gtk.Button zoom_out_button;
    private Settings interface_settings;

    class construct {
        set_css_name ("scalebox");
    }

    construct {
        zoom_out_button = new Gtk.Button.from_icon_name ("format-text-smaller-symbolic") {
            tooltip_text = _("Decrease text size")
        };
        zoom_out_button.add_css_class ("circular");

        var zoom_adjustment = new Gtk.Adjustment (-1, 0.75, 1.75, 0.05, 0, 0);

        var zoom_scale = new Gtk.Scale (HORIZONTAL, zoom_adjustment) {
            draw_value = false,
            hexpand = true
        };
        zoom_scale.add_mark (1, BOTTOM, null);
        zoom_scale.add_mark (1.5, BOTTOM, null);

        zoom_in_button = new Gtk.Button.from_icon_name ("format-text-larger-symbolic") {
            tooltip_text = _("Increase text size")
        };
        zoom_in_button.add_css_class ("circular");

        add_css_class ("font-size");
        append (zoom_out_button);
        append (zoom_scale);
        append (zoom_in_button);

        interface_settings = new Settings ("org.gnome.desktop.interface");
        interface_settings.bind ("text-scaling-factor", zoom_adjustment, "value", GET);
        interface_settings.changed["text-scaling-factor"].connect (update_zoom_buttons);
        update_zoom_buttons ();

        uint update_timeout_id = 0;
        zoom_adjustment.value_changed.connect (() => {
            if (update_timeout_id != 0) {
                GLib.Source.remove (update_timeout_id);
            }

            update_timeout_id = Timeout.add (300, () => {
                update_timeout_id = 0;
                interface_settings.set_double ("text-scaling-factor", zoom_adjustment.value);
                return GLib.Source.REMOVE;
            });
        });

        zoom_in_button.clicked.connect (() => {
            zoom_adjustment.value += 0.05;
        });

        zoom_out_button.clicked.connect (() => {
            zoom_adjustment.value += -0.05;
        });
    }

    private void update_zoom_buttons () {
        var scaling_factor = interface_settings.get_double ("text-scaling-factor");
        zoom_in_button.sensitive = scaling_factor < 1.75;
        zoom_out_button.sensitive = scaling_factor > 0.75;
    }
}
