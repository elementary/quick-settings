/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.MainWidget : Gtk.Box {
    construct {
        var media_controls = new MediaControls () {
            margin_bottom = 9
        };

        var volume_controls = new VolumeControls ("audio-volume-medium-symbolic", "computer-symbolic") {
            margin_bottom = 0
        };

        var mic_controls = new VolumeControls ("audio-input-microphone-symbolic", "audio-card-symbolic") {
            margin_bottom = 6
        };

        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic") {
            halign = Gtk.Align.START,
            hexpand = true,
            tooltip_text = _("System Settings…")
        };
        settings_button.add_css_class (Granite.STYLE_CLASS_CIRCULAR);

        var lock_button = new Gtk.Button.from_icon_name ("system-lock-screen-symbolic") {
            tooltip_text = _("Lock")
        };
        lock_button.add_css_class (Granite.STYLE_CLASS_CIRCULAR);

        // FIXME:no symbolic logout icon
        var logout_button = new Gtk.Button.from_icon_name ("go-next-symbolic") {
            tooltip_text = _("Log out…")
        };
        logout_button.add_css_class (Granite.STYLE_CLASS_CIRCULAR);

        var shutdown_button = new Gtk.Button.from_icon_name ("system-shutdown-symbolic") {
            tooltip_text = _("Shut down…")
        };
        shutdown_button.add_css_class (Granite.STYLE_CLASS_CIRCULAR);

        var actions_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_top = 6,
            margin_end = 12,
            margin_bottom = 6,
            margin_start = 12
        };
        actions_box.append (settings_button);
        actions_box.append (lock_button);
        actions_box.append (logout_button);
        actions_box.append (shutdown_button);

        orientation = Gtk.Orientation.VERTICAL;
        spacing = 3;
        margin_top = 12;
        margin_bottom = 3;
        append (media_controls);
        append (volume_controls);
        append (mic_controls);
        append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        append (actions_box);

        settings_button.clicked.connect (() => {
            var appinfo = new DesktopAppInfo ("io.elementary.settings.desktop");
            try {
                appinfo.launch (null, null);
                ((Gtk.Popover) get_ancestor (typeof (Gtk.Popover))).popdown ();
            } catch (Error e) {
                critical ("couldn't launch settings: %s", e.message);
            }

        });
    }
}
