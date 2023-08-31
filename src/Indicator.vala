/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.Indicator : Wingpanel.Indicator {
    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    public Indicator (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (
            code_name: "quick-settings",
            server_type: server_type
        );
    }

    construct {
        visible = true;
        GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
    }

    public override Gtk.Widget get_display_widget () {
        var indicator_icon = new Gtk.Image () {
            icon_name = "system-shutdown-symbolic",
            pixel_size = 24
        };

        return indicator_icon;
    }

    public override Gtk.Widget? get_widget () {
        var label = new Gtk.Label ("Hello World");

        var box = new Gtk.Box (VERTICAL, 0);
        box.add (label);

        return box;
    }

    public override void opened () {}

    public override void closed () {}
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    return new QuickSettings.Indicator (server_type);
}
