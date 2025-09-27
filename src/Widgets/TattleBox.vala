/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2011-2024 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.TattleBox : Gtk.Bin {
    class construct {
        set_css_name ("tattlebox");
    }

    construct {
        var location_image = new Gtk.Image.from_icon_name ("location-active-symbolic", MENU);
        location_image.get_style_context ().add_class (Granite.STYLE_CLASS_ACCENT);
        location_image.get_style_context ().add_class ("purple");

        var location_label = new Gtk.Label (_("Location services in use"));

        var location_box = new Gtk.Box (HORIZONTAL, 3);
        location_box.add (location_image);
        location_box.add (location_label);

        var location_revealer = new Gtk.Revealer () {
            child = location_box
        };

        child = location_revealer;

        setup_geoclue_manager.begin ((obj, res) => {
            var geoclue_manager = setup_geoclue_manager.end (res);
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
