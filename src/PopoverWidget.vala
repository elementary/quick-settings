/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.PopoverWidget : Gtk.Box {
    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    private const string FDO_ACCOUNTS_NAME = "org.freedesktop.Accounts";
    private const string FDO_ACCOUNTS_PATH = "/org/freedesktop/Accounts";

    private Gtk.Popover? popover;
    private Hdy.Deck deck;
    private EndSessionDialog? current_dialog = null;
    private SystemInterface system_interface;

    public PopoverWidget (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (server_type: server_type);
    }

    class construct {
        set_css_name ("quicksettings");
    }

    construct {
        var toggle_box = new Gtk.Box (HORIZONTAL, 6);
        toggle_box.get_style_context ().add_class ("togglebox");

        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic") {
            halign = CENTER,
            tooltip_text = _("System Settings…")
        };
        settings_button.get_style_context ().add_class ("circular");

        var a11y_button = new Gtk.Button.from_icon_name ("preferences-desktop-accessibility-symbolic") {
            halign = CENTER,
            tooltip_text = _("Accessiblity Settings…")
        };
        a11y_button.get_style_context ().add_class ("circular");

        var a11y_revealer = new Gtk.Revealer () {
            halign = START,
            hexpand = true,
            child = a11y_button,
            transition_type = SLIDE_LEFT
        };

        var logout_button = new Gtk.Button.from_icon_name ("system-log-out-symbolic") {
            tooltip_text = _("Log Out…")
        };
        logout_button.get_style_context ().add_class ("circular");

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

        var session_box = new Gtk.Box (HORIZONTAL, 6);
        session_box.add (settings_button);
        session_box.add (a11y_revealer);
        session_box.add (logout_button);
        session_box.add (suspend_button);
        session_box.add (lock_button);
        session_box.add (shutdown_button);
        session_box.get_style_context ().add_class ("togglebox");

        var main_box = new Gtk.Box (VERTICAL, 0);
        main_box.add (toggle_box);
        main_box.add (new Gtk.Separator (HORIZONTAL));
        main_box.add (session_box);

        deck = new Hdy.Deck () {
            can_swipe_back = true,
            vhomogeneous = false,
            interpolate_size = true
        };
        deck.add (main_box);

        add (deck);

        if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
            setup_session_interface.begin ((obj, res) => {
                var session_interface = setup_session_interface.end (res);

                logout_button.clicked.connect (() => {
                    popover.popdown ();

                    session_interface.logout.begin (0, (obj, res) => {
                        try {
                            session_interface.logout.end (res);
                        } catch (Error e) {
                            if (!(e is GLib.IOError.CANCELLED)) {
                                warning ("Unable to open logout dialog: %s", e.message);
                            }
                        }
                    });
                });

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
            session_box.remove (settings_button);
            session_box.remove (logout_button);
            session_box.remove (suspend_button);

            shutdown_button.clicked.connect (() => {
                popover.popdown ();
                show_dialog (EndSessionDialogType.RESTART, Gtk.get_current_event_time ());
            });
        }

        setup_accounts_services.begin ((obj, res) => {
            var pantheon_service = setup_accounts_services.end (res);
            if (pantheon_service != null &&
                ((DBusProxy) pantheon_service).get_cached_property ("PrefersColorScheme") != null
            ) {
                var darkmode_button = new DarkModeToggle (pantheon_service);
                toggle_box.add (darkmode_button);
                show_all ();
            }
        });

        setup_sensor_proxy.begin ((obj, res) => {
            var sensor_proxy = setup_sensor_proxy.end (res);
            if (sensor_proxy.has_accelerometer) {
                var rotation_toggle = new RotationToggle ();
                toggle_box.add (rotation_toggle);
                show_all ();
            };
        });

        setup_system_interface.begin ((obj, res) => {
            system_interface = setup_system_interface.end (res);

            suspend_button.clicked.connect (() => {
                popover.popdown ();

                try {
                    system_interface.suspend (true);
                } catch (GLib.Error e) {
                    critical ("Unable to lock: %s", e.message);
                }
            });

            if (server_type == GREETER) {
                lock_button.clicked.connect (() => {
                    popover.popdown ();

                    try {
                        system_interface.suspend (true);
                    } catch (GLib.Error e) {
                        critical ("Unable to lock: %s", e.message);
                    }
                });
            }
        });

        realize.connect (() => {
            popover = (Gtk.Popover) get_ancestor (typeof (Gtk.Popover));
            popover.closed.connect (() => {
                deck.navigate (BACK);
            });
        });

        a11y_button.clicked.connect (() => {
            var a11y_view = new A11yView ();

            deck.add (a11y_view);
            show_all ();
            deck.visible_child = a11y_view;
        });

        settings_button.clicked.connect (() => {
            popover.popdown ();

            try {
                AppInfo.launch_default_for_uri ("settings://", null);
            } catch (Error e) {
                critical ("Failed to open system settings: %s", e.message);
            }
        });

        deck.notify["visible-child"].connect (update_navigation);
        deck.notify["transition-running"].connect (update_navigation);

        var glib_settings = new Settings ("io.elementary.desktop.quick-settings");
        glib_settings.bind ("show-a11y", a11y_revealer, "reveal-child", GET);

        var keybinding_settings = new Settings ("org.gnome.settings-daemon.plugins.media-keys");
        logout_button.tooltip_markup = Granite.markup_accel_tooltip (
            keybinding_settings.get_strv ("logout"), _("Log Out…")
        );
        lock_button.tooltip_markup = Granite.markup_accel_tooltip (
            keybinding_settings.get_strv ("screensaver"), _("Lock")
        );

        keybinding_settings.changed["logout"].connect (() => {
            logout_button.tooltip_markup = Granite.markup_accel_tooltip (
                keybinding_settings.get_strv ("logout"), _("Log Out…")
            );
        });

        keybinding_settings.changed["screensaver"].connect (() => {
            lock_button.tooltip_markup = Granite.markup_accel_tooltip (
                keybinding_settings.get_strv ("screensaver"), _("Lock")
            );
        });
    }

    private void update_navigation () {
        if (!deck.transition_running) {
            while (deck.get_adjacent_child (FORWARD) != null) {
                var next_child = deck.get_adjacent_child (FORWARD);
                next_child.destroy ();
            }
        }
    }

    private async Pantheon.AccountsService? setup_accounts_services () {
        unowned GLib.DBusConnection connection;
        string path;

        try {
            connection = yield GLib.Bus.get (SYSTEM);

            var reply = yield connection.call (
                FDO_ACCOUNTS_NAME, FDO_ACCOUNTS_PATH,
                FDO_ACCOUNTS_NAME, "FindUserByName",
                new Variant.tuple ({ new Variant.string (Environment.get_user_name ()) }),
                new VariantType ("(o)"),
                NONE,
                -1
            );
            reply.get_child (0, "o", out path);
        } catch {
            critical ("Could not connect to AccountsService");
            return null;
        }

        try {
            return yield connection.get_proxy (FDO_ACCOUNTS_NAME, path, GET_INVALIDATED_PROPERTIES);
        } catch {
            critical ("Unable to get Pantheon's AccountsService proxy, Dark mode toggle will not be available");
            return null;
        }
    }

    private async SensorProxy? setup_sensor_proxy () {
        try {
            return yield Bus.get_proxy (BusType.SYSTEM, "net.hadess.SensorProxy", "/net/hadess/SensorProxy");
        } catch (Error e) {
            info ("Unable to connect to SensorProxy bus, probably means no accelerometer supported: %s", e.message);
            return null;
        }
    }

    private async SessionInterface? setup_session_interface () {
        try {
            return yield Bus.get_proxy (BusType.SESSION, "org.gnome.SessionManager", "/org/gnome/SessionManager");
        } catch (IOError e) {
            critical ("Unable to connect to GNOME session interface: %s", e.message);
            return null;
        }
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
            if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
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
            if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
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
