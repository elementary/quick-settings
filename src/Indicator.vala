/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.Indicator : Wingpanel.Indicator {
    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    private PopoverWidget? popover_widget;

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
        if (popover_widget == null) {
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("io/elementary/quick-settings/Indicator.css");

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            popover_widget = new PopoverWidget ();

            popover_widget.close.connect (() => close ());
        }

        return popover_widget;
    }

    public override void opened () {}

    public override void closed () {}
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    return new QuickSettings.Indicator (server_type);
}
