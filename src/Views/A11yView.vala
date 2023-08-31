/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.A11yView : Gtk.Box {
    private Gtk.Button zoom_default_button;
    private Gtk.Button zoom_in_button;
    private Gtk.Button zoom_out_button;
    private Settings interface_settings;

    construct {
        var back_button = new Gtk.Button.with_label (_("Back")) {
            halign = START
        };
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", MENU) {
            tooltip_text = _("Decrease text size")
        };

        zoom_default_button = new Gtk.Button.with_label ("100%") {
            tooltip_text = _("Default text size")
        };

        zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", MENU) {
            tooltip_text = _("Increase text size")
        };

        var font_size_box = new Gtk.Box (HORIZONTAL, 0) {
            homogeneous = true,
            hexpand = true
        };
        font_size_box.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        font_size_box.add (zoom_out_button);
        font_size_box.add (zoom_default_button);
        font_size_box.add (zoom_in_button);

        var screen_reader = new Granite.SwitchModelButton (_("Screen Reader"));

        var onscreen_keyboard = new Granite.SwitchModelButton (_("Onscreen Keyboard"));

        var slow_keys = new Granite.SwitchModelButton (_("Slow Keys"));

        var bounce_keys = new Granite.SwitchModelButton (_("Bounce Keys"));

        var sticky_keys = new Granite.SwitchModelButton (_("Sticky Keys"));

        var hover_click = new Granite.SwitchModelButton (_("Dwell Click"));

        orientation = VERTICAL;
        add (back_button);
        add (new Gtk.Separator (HORIZONTAL));
        add (font_size_box);
        add (screen_reader);
        add (onscreen_keyboard);
        add (slow_keys);
        add (bounce_keys);
        add (sticky_keys);
        add (hover_click);

        back_button.clicked.connect (() => {
            var deck = (Hdy.Deck) get_ancestor (typeof (Hdy.Deck));
            deck.navigate (BACK);
        });

        zoom_default_button.clicked.connect (() => {
            interface_settings.reset ("text-scaling-factor");
        });

        zoom_in_button.clicked.connect (() => {
            var scaling_factor = interface_settings.get_double ("text-scaling-factor");
            interface_settings.set_double ("text-scaling-factor", scaling_factor + 0.25);
        });

        zoom_out_button.clicked.connect (() => {
            var scaling_factor = interface_settings.get_double ("text-scaling-factor");
            interface_settings.set_double ("text-scaling-factor", scaling_factor - 0.25);
        });

        var applications_settings = new Settings ("org.gnome.desktop.a11y.applications");
        applications_settings.bind ("screen-keyboard-enabled", onscreen_keyboard, "active", DEFAULT);
        applications_settings.bind ("screen-reader-enabled", screen_reader, "active", DEFAULT);

        interface_settings = new Settings ("org.gnome.desktop.interface");
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
        zoom_in_button.sensitive = scaling_factor < 1.5;
        zoom_out_button.sensitive = scaling_factor > 0.75;
        zoom_default_button.label = "%.0f%%".printf (scaling_factor * 100);
    }
}
