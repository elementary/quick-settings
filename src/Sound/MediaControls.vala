/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.MediaControls : Gtk.Grid {
    construct {
        var album_image = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        album_image.append (
            new Gtk.Image.from_icon_name ("audio-x-generic-symbolic") {
                height_request = 40,
                width_request = 40
            }
        );
        album_image.add_css_class (Granite.STYLE_CLASS_CARD);
        album_image.add_css_class (Granite.STYLE_CLASS_ROUNDED);
        album_image.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var title_label = new Gtk.Label (_("Music")) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            halign = Gtk.Align.START,
            valign = Gtk.Align.END
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var artist_label = new Gtk.Label (_("Not playing")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START
        };
        artist_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var previous_button = new Gtk.Button.from_icon_name ("media-skip-backward-symbolic") {
            sensitive = false,
        };
        previous_button.add_css_class (Granite.STYLE_CLASS_CIRCULAR);

        var play_pause_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic") ;
        play_pause_button.add_css_class (Granite.STYLE_CLASS_CIRCULAR);

        var next_button = new Gtk.Button.from_icon_name ("media-skip-forward-symbolic") {
            sensitive = false
        };
        next_button.add_css_class (Granite.STYLE_CLASS_CIRCULAR);

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.CENTER
        };
        button_box.append (previous_button);
        button_box.append (play_pause_button);
        button_box.append (next_button);

        margin_start = 12;
        margin_end = 12;
        column_spacing = 12;
        attach (album_image, 0, 0, 1, 2);
        attach (title_label, 1, 0);
        attach (artist_label, 1, 1);
        attach (button_box, 2, 0, 1, 2);
    }
}
