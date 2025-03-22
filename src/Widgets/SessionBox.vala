/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.SessionBox : Gtk.Box {
    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    private EndSessionDialog? current_dialog = null;
    private Gtk.Popover? popover;
    private SystemInterface system_interface;

    public SessionBox (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (server_type: server_type);
    }

    construct {
        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic") {
            tooltip_text = _("System Settings…")
        };
        settings_button.get_style_context ().add_class ("circular");

        var suspend_button = new Gtk.Button.from_icon_name ("system-suspend-symbolic") {
            tooltip_text = _("Suspend")
        };
        suspend_button.get_style_context ().add_class ("circular");

        var lock_button = new Gtk.Button.from_icon_name ("system-lock-screen-symbolic") {
            tooltip_text = _("Lock")
        };
        lock_button.get_style_context ().add_class ("circular");

        var shutdown_button = new Gtk.Button.from_icon_name ("system-shutdown-symbolic") {
            tooltip_text = _("Shut Down…")
        };
        shutdown_button.get_style_context ().add_class ("circular");

        spacing = 6;
        add (settings_button);
        add (suspend_button);
        add (lock_button);
        add (shutdown_button);

        realize.connect (() => {
            popover = (Gtk.Popover) get_ancestor (typeof (Gtk.Popover));
        });

        if (server_type == SESSION) {
            UserManager.setup_session_interface.begin ((obj, res) => {
                var session_interface = UserManager.setup_session_interface.end (res);

                shutdown_button.clicked.connect (() => {
                    popover.popdown ();

                    // Ask gnome-session to "reboot" which throws the EndSessionDialog
                    // Our "reboot" dialog also has a shutdown button to give the choice between reboot/shutdown
                    session_interface.reboot.begin ((obj, res) => {
                        try {
                            session_interface.reboot.end (res);
                        } catch (Error e) {
                            if (!(e is GLib.IOError.CANCELLED)) {
                                critical ("Unable to open shutdown dialog: %s", e.message);
                            }
                        }
                    });
                });
            });

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

            shutdown_button.clicked.connect (() => {
                popover.popdown ();
                show_dialog (EndSessionDialogType.RESTART, Gtk.get_current_event_time ());
            });
        }

        setup_system_interface.begin ((obj, res) => {
            system_interface = setup_system_interface.end (res);

            suspend_button.clicked.connect (() => {
                popover.popdown ();

                try {
                    system_interface.suspend (true);
                } catch (GLib.Error e) {
                    critical ("Unable to suspend: %s", e.message);
                }
            });
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

        EndSessionDialogServer.init ();
        EndSessionDialogServer.get_default ().show_dialog.connect (
            (type, timestamp) => show_dialog ((EndSessionDialogType) type, timestamp)
        );

        settings_button.clicked.connect (() => {
            popover.popdown ();

            try {
                AppInfo.launch_default_for_uri ("settings://", null);
            } catch (Error e) {
                critical ("Failed to open system settings: %s", e.message);
            }
        });
    }

    private async SystemInterface? setup_system_interface () {
        try {
            return yield Bus.get_proxy (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
        } catch (IOError e) {
            critical ("Unable to connect to the login interface: %s", e.message);
            return null;
        }
    }

    private async LockInterface? setup_lock_interface () {
        try {
            return yield Bus.get_proxy (BusType.SESSION, "org.gnome.ScreenSaver", "/org/gnome/ScreenSaver");
        } catch (IOError e) {
            critical ("Unable to connect to lock interface: %s", e.message);
            return null;
        }
    }

    private void show_dialog (EndSessionDialogType type, uint32 triggering_event_timestamp) {
        popover.popdown ();

        if (current_dialog != null) {
            if (current_dialog.dialog_type != type) {
                current_dialog.destroy ();
            } else {
                return;
            }
        }

        unowned var server = EndSessionDialogServer.get_default ();

        current_dialog = new EndSessionDialog (type) {
            transient_for = (Gtk.Window) get_toplevel ()
        };
        current_dialog.destroy.connect (() => {
            server.closed ();
            current_dialog = null;
        });

        current_dialog.cancelled.connect (() => {
            server.canceled ();
        });

        current_dialog.logout.connect (() => {
            server.confirmed_logout ();
        });

        current_dialog.shutdown.connect (() => {
            if (server_type == SESSION) {
                server.confirmed_shutdown ();
            } else {
                try {
                    system_interface.power_off (false);
                } catch (Error e) {
                    warning ("Unable to shutdown: %s", e.message);
                }
            }
        });

        current_dialog.reboot.connect (() => {
            if (server_type == SESSION) {
                server.confirmed_reboot ();
            } else {
                try {
                    system_interface.reboot (false);
                } catch (Error e) {
                    warning ("Unable to reboot: %s", e.message);
                }
            }
        });

        current_dialog.present_with_time (triggering_event_timestamp);
    }
}
