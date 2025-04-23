/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.SettingsToggle : Gtk.FlowBoxChild {
    public bool active { get; set; }
    public Icon icon { get; construct set; }
    public string label { get; construct; }
    public string settings_uri { get; set; default = "settings://"; }

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
            max_width_chars = 13,
            mnemonic_widget = button
        };
        label_widget.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var box = new Gtk.Box (VERTICAL, 3);
        box.add (button);
        box.add (label_widget);

        can_focus = false;
        child = box;

        button.bind_property ("active", this, "active", SYNC_CREATE | BIDIRECTIONAL);

        bind_property ("icon", image, "gicon");

        var middle_click_gesture = new Gtk.GestureClick () {
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

        button.add_controller (middle_click_gesture);
    }
}
