/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.DisplayWidget : Gtk.Box {
    construct {
        var volume = new Gtk.Image.from_icon_name ("audio-volume-medium-symbolic") {
            pixel_size = 24
        };

        var network = new Gtk.Image.from_icon_name ("network-wired-symbolic") {
            pixel_size = 24
        };

        var battery = new Gtk.Image.from_icon_name ("battery-good-symbolic") {
            pixel_size = 24
        };

        spacing = 6;
        append (volume);
        append (network);
        append (battery);
    }
}
