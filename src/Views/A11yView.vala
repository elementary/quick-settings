/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.A11yView : Gtk.Box {
    private Gtk.Button zoom_in_button;
    private Gtk.Button zoom_out_button;
    private Settings interface_settings;

    construct {
        var back_button = new Gtk.Button.with_label (_("Back")) {
            halign = START
        };
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        zoom_out_button = new Gtk.Button.from_icon_name ("format-text-smaller-symbolic", MENU) {
            tooltip_text = _("Decrease text size")
        };

        var zoom_adjustment = new Gtk.Adjustment (-1, 0.75, 1.75, 0.05, 0, 0);

        var zoom_scale = new Gtk.Scale (HORIZONTAL, zoom_adjustment) {
            draw_value = false,
            hexpand = true
        };
        zoom_scale.add_mark (1, BOTTOM, null);
        zoom_scale.add_mark (1.5, BOTTOM, null);

        zoom_in_button = new Gtk.Button.from_icon_name ("format-text-larger-symbolic", MENU) {
            tooltip_text = _("Increase text size")
        };

        var screen_reader = new SettingsToggle (
            new ThemedIcon ("orca-symbolic"),
            _("Screen Reader")
        ) {
            settings_uri = "settings://sound"
        };

        var onscreen_keyboard = new SettingsToggle (
            new ThemedIcon ("input-keyboard-symbolic"),
            _("Onscreen Keyboard")
        ) {
            settings_uri = "settings://input/keyboard/behavior"
        };

        var toggle_box = new Gtk.Box (HORIZONTAL, 6) {
            homogeneous = true
        };
        toggle_box.get_style_context ().add_class ("togglebox");
        toggle_box.add (screen_reader);
        toggle_box.add (onscreen_keyboard);

        var font_size_box = new Gtk.Box (HORIZONTAL, 0);
        font_size_box.get_style_context ().add_class ("font-size");
        font_size_box.add (zoom_out_button);
        font_size_box.add (zoom_scale);
        font_size_box.add (zoom_in_button);

        var slow_keys = new Granite.SwitchModelButton (_("Slow Keys"));

        var bounce_keys = new Granite.SwitchModelButton (_("Bounce Keys"));

        var sticky_keys = new Granite.SwitchModelButton (_("Sticky Keys"));

        var hover_click = new Granite.SwitchModelButton (_("Dwell Click"));

        orientation = VERTICAL;
        add (back_button);
        add (toggle_box);
        add (font_size_box);
        add (new Gtk.Separator (HORIZONTAL));
        add (slow_keys);
        add (bounce_keys);
        add (sticky_keys);
        add (hover_click);

        back_button.clicked.connect (() => {
            var deck = (Hdy.Deck) get_ancestor (typeof (Hdy.Deck));
            deck.navigate (BACK);
        });

        zoom_in_button.clicked.connect (() => {
            zoom_adjustment.value += 0.05;
        });

        zoom_out_button.clicked.connect (() => {
            zoom_adjustment.value += -0.05;
        });

        var applications_settings = new Settings ("org.gnome.desktop.a11y.applications");
        applications_settings.bind ("screen-keyboard-enabled", onscreen_keyboard, "active", DEFAULT);
        applications_settings.bind ("screen-reader-enabled", screen_reader, "active", DEFAULT);

        interface_settings = new Settings ("org.gnome.desktop.interface");
        interface_settings.bind ("text-scaling-factor", zoom_adjustment, "value", DEFAULT);
        interface_settings.changed["text-scaling-factor"].connect (update_zoom_buttons);
        update_zoom_buttons ();

        var keyboard_settings = new Settings ("org.gnome.desktop.a11y.keyboard");
        keyboard_settings.bind ("bouncekeys-enable", bounce_keys, "active", DEFAULT);
        keyboard_settings.bind ("slowkeys-enable", slow_keys, "active", DEFAULT);
        keyboard_settings.bind ("stickykeys-enable", sticky_keys, "active", DEFAULT);

        var mouse_settings = new Settings ("org.gnome.desktop.a11y.mouse");
        mouse_settings.bind ("dwell-click-enabled", hover_click, "active", DEFAULT);
    }

    private void update_zoom_buttons () {
        var scaling_factor = interface_settings.get_double ("text-scaling-factor");
        zoom_in_button.sensitive = scaling_factor < 1.75;
        zoom_out_button.sensitive = scaling_factor > 0.75;
    }
}
