/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.TattleBox : Granite.Bin {
    class construct {
        set_css_name ("tattlebox");
    }

    construct {
        var location_image = new Gtk.Image.from_icon_name ("location-active-symbolic");
        location_image.add_css_class (Granite.CssClass.ACCENT);
        location_image.add_css_class ("purple");

        var location_label = new Gtk.Label (_("Location services in use"));

        var location_box = new Gtk.Box (HORIZONTAL, 3);
        location_box.append (location_image);
        location_box.append (location_label);

        var location_revealer = new Gtk.Revealer () {
            child = location_box
        };

        child = location_revealer;

        setup_geoclue_manager.begin ((obj, res) => {
            var geoclue_manager = setup_geoclue_manager.end (res);
            if (geoclue_manager == null) {
                return;
            }

            location_revealer.reveal_child = geoclue_manager.in_use;

            geoclue_manager.g_properties_changed.connect (() => {
                location_revealer.reveal_child = geoclue_manager.in_use;
            });
        });
    }

    private async GeoclueManager? setup_geoclue_manager () {
        try {
            return yield Bus.get_proxy (BusType.SYSTEM, "org.freedesktop.GeoClue2", "/org/freedesktop/GeoClue2/Manager");
        } catch (Error e) {
            info ("Unable to connect to GeoClue2 bus, location tattle tale will not be available: %s", e.message);
            return null;
        }
    }
}
