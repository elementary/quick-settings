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
            server_type: server_type,
            visible: true
        );
    }

    construct {
        GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");

        // Prevent a race that skips automatic resource loading
        // https://github.com/elementary/wingpanel-indicator-bluetooth/issues/203
        Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).add_resource_path ("/org/elementary/wingpanel/icons");
    }

    public override Gtk.Widget get_display_widget () {
        var indicator_icon = new Gtk.Image () {
            icon_name = "quick-settings-symbolic",
            pixel_size = 24
        };

        return indicator_icon;
    }

    public override Gtk.Widget? get_widget () {
        if (popover_widget == null) {
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("io/elementary/quick-settings/Indicator.css");

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            popover_widget = new PopoverWidget (server_type);
        }

        return popover_widget;
    }

    public override void opened () {
        if (popover_widget == null) {
            return;
        }

        popover_widget.update_user_tooltip.begin ();
    }

    public override void closed () {
        if (popover_widget == null) {
            return;
        }

        popover_widget.reset_stack ();
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    return new QuickSettings.Indicator (server_type);
}
