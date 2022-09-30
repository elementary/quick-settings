/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.VolumeControls : Gtk.Box {
    construct {
        var image = new Gtk.Image.from_icon_name ("audio-volume-medium-symbolic") {
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

        margin_start = 12;
        margin_end = 12;
        append (overlay);
    }
}
