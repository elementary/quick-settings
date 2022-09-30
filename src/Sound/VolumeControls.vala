/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.VolumeControls : Gtk.Box {
    public string icon_name { get; construct; }
    public string device_icon { get; construct; }

    public VolumeControls (string icon_name, string device_icon) {
        Object (
            icon_name: icon_name,
            device_icon: device_icon
        );
    }

    construct {
        var image = new Gtk.Image.from_icon_name (icon_name) {
            can_target = false,
            halign = Gtk.Align.START,
            margin_start = 4,
        };
        image.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1) {
            hexpand = true,
        };
        scale.set_value (65);

        var overlay = new Gtk.Overlay () {
            child = scale
        };
        overlay.add_overlay (image);

        var device_button = new Gtk.Button.from_icon_name (device_icon) {
            valign = Gtk.Align.CENTER
        };
        device_button.add_css_class (Granite.STYLE_CLASS_CIRCULAR);
        device_button.add_css_class ("submenu");

        spacing = 6;
        margin_start = 12;
        margin_end = 12;
        append (overlay);
        append (device_button);
    }
}
