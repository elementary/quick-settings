/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.Indicator : Gtk.Application {
    public Indicator () {
        Object (
            application_id: "io.elementary.quick-settings",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    protected override void activate () {
        if (active_window == null) {
            var display_widget = new DisplayWidget ();

            var main_widget = new MainWidget ();

            var popover = new Gtk.Popover () {
                child = main_widget
            };

            var menu_button = new Gtk.MenuButton () {
                child = display_widget,
                halign = Gtk.Align.CENTER,
                popover = popover,
                valign = Gtk.Align.CENTER,
                margin_top = 24,
                margin_bottom = 24,
                margin_start = 24,
                margin_end = 24
            };

            var main_window = new Gtk.ApplicationWindow (this) {
                child = menu_button,
            };
        }

        active_window.present_with_time (Gdk.CURRENT_TIME);
    }

    public static int main (string[] args) {
        return new QuickSettings.Indicator ().run (args);
    }
}
