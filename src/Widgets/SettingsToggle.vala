/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.SettingsToggle : Gtk.Box {
    public bool active { get; set; }
    public Icon icon { get; construct set; }
    public string label { get; construct; }
    public string settings_uri { get; set; default = "settings://"; }

    private Gtk.GestureMultiPress middle_click_gesture;

    public SettingsToggle (Icon icon, string label) {
        Object (
            icon: icon,
            label: label
        );
    }

    construct {
        var image = new Gtk.Image.from_gicon (icon, MENU);

        var button = new Gtk.ToggleButton () {
            halign = CENTER,
            image = image
        };

        var label_widget = new Gtk.Label (label) {
            ellipsize = MIDDLE,
            justify = CENTER,
            lines = 2,
            max_width_chars = 13
        };
        label_widget.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        hexpand = true;
        orientation = VERTICAL;
        spacing = 3;
        add (button);
        add (label_widget);

        button.bind_property ("active", this, "active", SYNC_CREATE | BIDIRECTIONAL);

        bind_property ("icon", image, "gicon");

        middle_click_gesture = new Gtk.GestureMultiPress (button) {
            button = Gdk.BUTTON_MIDDLE
        };
        middle_click_gesture.pressed.connect (() => {
            try {
                AppInfo.launch_default_for_uri (settings_uri, null);

                var popover = (Gtk.Popover) get_ancestor (typeof (Gtk.Popover));
                popover.popdown ();
            } catch (Error e) {
                critical ("Failed to open system settings: %s", e.message);
            }
        });
    }
}
