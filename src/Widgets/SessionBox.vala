/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.SessionBox : Gtk.Box {
    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    private Gtk.Popover? popover;

    public SessionBox (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (server_type: server_type);
    }

    construct {
        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic") {
            tooltip_text = _("System Settings…")
        };
        settings_button.add_css_class (Granite.CssClass.CIRCULAR);

        var suspend_button = new Gtk.Button.from_icon_name ("system-suspend-symbolic") {
            tooltip_text = _("Suspend")
        };
        suspend_button.add_css_class (Granite.CssClass.CIRCULAR);

        var lock_button = new Gtk.Button.from_icon_name ("system-lock-screen-symbolic") {
            tooltip_text = _("Lock")
        };
        lock_button.add_css_class (Granite.CssClass.CIRCULAR);

        var shutdown_button = new Gtk.Button.from_icon_name ("system-shutdown-symbolic") {
            tooltip_text = _("Shut Down…")
        };
        shutdown_button.add_css_class (Granite.CssClass.CIRCULAR);

        spacing = 6;
        append (settings_button);
        append (suspend_button);
        append (lock_button);
        append (shutdown_button);

        realize.connect (() => {
            popover = (Gtk.Popover) get_ancestor (typeof (Gtk.Popover));
        });

        if (server_type == SESSION) {
            setup_lock_interface.begin ((obj, res) => {
                var lock_interface = setup_lock_interface.end (res);

                lock_button.clicked.connect (() => {
                    popover.popdown ();

                    try {
                        lock_interface.lock ();
                    } catch (GLib.Error e) {
                        critical ("Unable to lock: %s", e.message);
                    }
                });
            });
        } else {
            remove (settings_button);
            remove (lock_button);
        }

        shutdown_button.clicked.connect (() => {
            popover.popdown ();
            EndSessionDialogServer.get_default ().show_dialog (EndSessionDialogType.RESTART);
        });

        suspend_button.clicked.connect (() => {
            popover.popdown ();

            try {
                Login1Manager.get_default ().proxy.suspend (true);
            } catch (GLib.Error e) {
                critical ("Unable to suspend: %s", e.message);
            }
        });

        var keybinding_settings = new Settings ("org.gnome.settings-daemon.plugins.media-keys");

        lock_button.tooltip_markup = Granite.markup_accel_tooltip (
            keybinding_settings.get_strv ("screensaver"), _("Lock")
        );

        keybinding_settings.changed["screensaver"].connect (() => {
            lock_button.tooltip_markup = Granite.markup_accel_tooltip (
                keybinding_settings.get_strv ("screensaver"), _("Lock")
            );
        });

        settings_button.clicked.connect (() => {
            popover.popdown ();

            try {
                AppInfo.launch_default_for_uri ("settings://", null);
            } catch (Error e) {
                critical ("Failed to open system settings: %s", e.message);
            }
        });
    }

    private async LockInterface? setup_lock_interface () {
        try {
            return yield Bus.get_proxy (BusType.SESSION, "org.gnome.ScreenSaver", "/org/gnome/ScreenSaver");
        } catch (IOError e) {
            critical ("Unable to connect to lock interface: %s", e.message);
            return null;
        }
    }
}
