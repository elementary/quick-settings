/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.PreventSleepToggle: SettingsToggle {
    private uint suspend_cookie = 0;
    private uint idle_cookie = 0;

    private SimpleAction inhibit_action;

    public PreventSleepToggle () {
        Object (
            label: _("Prevent Sleep")
        );
    }

    construct {
        action_name = "quick-settings.inhibit";
        icon_name = "system-suspend-symbolic";
        settings_uri = "settings://power";

        inhibit_action = new SimpleAction.stateful ("inhibit", null, new Variant.boolean (suspend_cookie > 0 && idle_cookie > 0));
        inhibit_action.activate.connect (toggle_inibit);

        map.connect (() => {
            var action_group = (SimpleActionGroup) get_action_group ("quick-settings");
            action_group.add_action (inhibit_action);
        });
    }

    private void toggle_inibit () {
        unowned var application = (Gtk.Application) GLib.Application.get_default ();

        if (suspend_cookie == 0 && idle_cookie == 0) {
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

            inhibit_action.set_state (new Variant.boolean (true));
            icon_name = "system-suspend-disabled-symbolic";
        } else if (suspend_cookie > 0 && idle_cookie > 0) {
            application.uninhibit (suspend_cookie);
            application.uninhibit (idle_cookie);

            inhibit_action.set_state (new Variant.boolean (false));
            icon_name = "system-suspend-symbolic";

            suspend_cookie = 0;
            idle_cookie = 0;
        }
    }
}
