/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.PreventSleepToggle: SettingsToggle {
    private uint suspend_cookie = 0;
    private uint idle_cookie = 0;

    public PreventSleepToggle () {
        Object (
            label: _("Prevent Sleep")
        );
    }

    construct {
        icon_name = "system-suspend-symbolic";
        settings_uri = "settings://power";

        notify["active"].connect ((obj, pspec) => {
            var _prevent_sleep_toggle = (SettingsToggle) obj;
            unowned var application = (Gtk.Application) GLib.Application.get_default ();

            if (_prevent_sleep_toggle.active && suspend_cookie == 0 && idle_cookie == 0) {
                suspend_cookie = application.inhibit (
                    (Gtk.Window) get_toplevel (),
                    Gtk.ApplicationInhibitFlags.SUSPEND,
                    "Prevent session from suspending"
                );
                idle_cookie = application.inhibit (
                    (Gtk.Window) get_toplevel (),
                    Gtk.ApplicationInhibitFlags.IDLE,
                    "Prevent session from idle"
                );

                icon_name = "system-suspend-disabled-symbolic";
            } else if (!_prevent_sleep_toggle.active && suspend_cookie > 0 && idle_cookie > 0) {
                application.uninhibit (suspend_cookie);
                application.uninhibit (idle_cookie);

                icon_name = "system-suspend-symbolic";

                suspend_cookie = 0;
                idle_cookie = 0;
            }
        });
    }
}
