/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.Indicator : Gtk.Application {
    public const string STYLESHEET = """
    .image-button.circular {
        border: none;
        box-shadow: none;
        padding: 8px;
    }

    scale slider {
        opacity: 0;
    }

    scale trough {
        min-height: 22px;
    }

    scale highlight {
        background-color: @base_color;
        border: none;
        box-shadow:
            inset 0 -1px 0 0 alpha(@highlight_color, 0.2),
            inset 0 1px 0 0 alpha(@highlight_color, 0.3),
            inset 1px 0 0 0 alpha(@highlight_color, 0.07),
            inset -1px 0 0 0 alpha(@highlight_color, 0.07),
            0 0 0 1px #dcdcdc,
            0 1px 3px alpha(black, 0.12),
            0 2px 3px alpha(black, 0.1);
        border-radius: 12px 12px 12px 12px;
        min-width: 24px;
        margin: 0 -1px 0 -1px;
    }
    """;


    public Indicator () {
        Object (
            application_id: "io.elementary.quick-settings",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    protected override void startup () {
        base.startup ();

        var provider = new Gtk.CssProvider ();
        provider.load_from_data (STYLESHEET.data);
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    protected override void activate () {
        if (active_window == null) {
            var display_widget = new DisplayWidget ();

            var main_widget = new MainWidget ();

            var popover = new Gtk.Popover () {
                child = main_widget,
                margin_end = 6
            };

            var menu_button = new Gtk.MenuButton () {
                child = display_widget,
                halign = Gtk.Align.END,
                has_frame = false,
                popover = popover,
                valign = Gtk.Align.START,
                margin_top = 12,
                margin_bottom = 12,
                margin_start = 12,
                margin_end = 12
            };

            var main_window = new Gtk.ApplicationWindow (this) {
                child = menu_button,
            };
            main_window.maximize ();
        }

        active_window.present_with_time (Gdk.CURRENT_TIME);
    }

    public static int main (string[] args) {
        return new QuickSettings.Indicator ().run (args);
    }
}
