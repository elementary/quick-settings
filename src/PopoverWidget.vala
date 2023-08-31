/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.PopoverWidget : Gtk.Box {
    private const string FDO_ACCOUNTS_NAME = "org.freedesktop.Accounts";
    private const string FDO_ACCOUNTS_PATH = "/org/freedesktop/Accounts";

    private Gtk.Popover? popover;
    private Hdy.Deck deck;
    private SettingsToggle bluetooth_toggle;

    private DBusObjectManagerClient? bluetooth_manager = null;
    private Pantheon.AccountsService? pantheon_service = null;

    class construct {
        set_css_name ("quicksettings");
    }

    construct {
        var toggle_box = new Gtk.Box (HORIZONTAL, 6);
        toggle_box.get_style_context ().add_class ("togglebox");

        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic", MENU) {
            halign = CENTER,
            tooltip_text = _("System Settings…")
        };
        settings_button.get_style_context ().add_class ("circular");

        var a11y_button = new Gtk.Button.from_icon_name ("preferences-desktop-accessibility-symbolic", MENU) {
            halign = CENTER,
            tooltip_text = _("Accessiblity Settings…")
        };
        a11y_button.get_style_context ().add_class ("circular");

        var a11y_revealer = new Gtk.Revealer () {
            child = a11y_button,
            transition_type = SLIDE_LEFT
        };

        var session_box = new Gtk.Box (HORIZONTAL, 6);
        session_box.add (settings_button);
        session_box.add (a11y_revealer);
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

        setup_accounts_services.begin ((obj, res) => {
            setup_accounts_services.end (res);

            if (((DBusProxy) pantheon_service).get_cached_property ("PrefersColorScheme") != null) {
                var darkmode_button = new SettingsToggle (
                    new ThemedIcon ("dark-mode-symbolic"),
                    _("Dark Mode")
                ) {
                    settings_uri = "settings://desktop/appearance"
                };

                toggle_box.add (darkmode_button);
                show_all ();

                darkmode_button.active = pantheon_service.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

                var settings = new Settings ("io.elementary.settings-daemon.prefers-color-scheme");

                darkmode_button.notify["active"].connect (() => {
                    settings.set_string ("prefer-dark-schedule", "disabled");

                    if (darkmode_button.active) {
                        pantheon_service.prefers_color_scheme = Granite.Settings.ColorScheme.DARK;
                    } else {
                        pantheon_service.prefers_color_scheme = Granite.Settings.ColorScheme.NO_PREFERENCE;
                    }
                });

                ((DBusProxy) pantheon_service).g_properties_changed.connect ((changed, invalid) => {
                    var color_scheme = changed.lookup_value ("PrefersColorScheme", new VariantType ("i"));
                    if (color_scheme != null) {
                        darkmode_button.active = (Granite.Settings.ColorScheme) color_scheme.get_int32 () == Granite.Settings.ColorScheme.DARK;
                    }
                });
            }
        });

        setup_bluetooth.begin ((obj, res) => {
            setup_bluetooth.end (res);

            if (bluetooth_manager == null) {
                return;
            }

            bluetooth_toggle = new SettingsToggle (
                new ThemedIcon ("quicksettings-bluetooth-active-symbolic"),
                _("Bluetooth")
            ) {
                settings_uri = "settings://network/bluetooth"
            };

            toggle_box.add (bluetooth_toggle);
            show_all ();

            bluetooth_toggle.notify["active"].connect (() => {
                set_bluetooth_status.begin (bluetooth_toggle.active);
            });

            bluetooth_manager.get_objects ().foreach ((object) => {
                object.get_interfaces ().foreach ((iface) => on_interface_added (object, iface));
            });
            bluetooth_manager.interface_added.connect (on_interface_added);
            bluetooth_manager.interface_removed.connect (on_interface_removed);
            bluetooth_manager.object_added.connect ((object) => {
                object.get_interfaces ().foreach ((iface) => on_interface_added (object, iface));
            });
            bluetooth_manager.object_removed.connect ((object) => {
                object.get_interfaces ().foreach ((iface) => on_interface_removed (object, iface));
            });

            get_bluetooth_status ();
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
    }

    private void update_navigation () {
        if (!deck.transition_running) {
            while (deck.get_adjacent_child (FORWARD) != null) {
                var next_child = deck.get_adjacent_child (FORWARD);
                next_child.destroy ();
            }
        }
    }

    private async void setup_accounts_services () {
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
            return;
        }

        try {
            pantheon_service = yield connection.get_proxy (FDO_ACCOUNTS_NAME, path, GET_INVALIDATED_PROPERTIES);
        } catch {
            critical ("Unable to get Pantheon's AccountsService proxy, Dark mode toggle will not be available");
        }
    }

    private async void setup_bluetooth () {
        try {
            bluetooth_manager = yield new GLib.DBusObjectManagerClient.for_bus.begin (
                BusType.SYSTEM,
                NONE,
                "org.bluez",
                "/",
                object_manager_get_proxy_type,
                null
            );
        } catch (Error e) {
            critical (e.message);
        }
    }

    //TODO: Do not rely on this when it is possible to do it natively in Vala
    [CCode (cname="quick_settings_bluez_adapter_proxy_get_type")]
    extern static GLib.Type get_adapter_proxy_type ();

    //TODO: Do not rely on this when it is possible to do it natively in Vala
    [CCode (cname="quick_settings_bluez_device_proxy_get_type")]
    extern static GLib.Type get_device_proxy_type ();

    private GLib.Type object_manager_get_proxy_type (DBusObjectManagerClient manager, string object_path, string? interface_name) {
        if (interface_name == null) {
            return typeof (GLib.DBusObjectProxy);
        }

        switch (interface_name) {
            case "org.bluez.Device1":
                return get_device_proxy_type ();
            case "org.bluez.Adapter1":
                return get_adapter_proxy_type ();
            default:
                return typeof (GLib.DBusProxy);
        }
    }

    private void on_interface_added (GLib.DBusObject object, GLib.DBusInterface iface) {
        if (iface is QuickSettings.BluezAdapter) {
            unowned var adapter = (QuickSettings.BluezAdapter) iface;

            ((DBusProxy) adapter).g_properties_changed.connect ((changed, invalid) => {
                var powered = changed.lookup_value ("Powered", new VariantType ("b"));
                if (powered != null) {
                    get_bluetooth_status ();
                }
            });

            get_bluetooth_status ();
        }
    }

    private void on_interface_removed (GLib.DBusObject object, GLib.DBusInterface iface) {
        get_bluetooth_status ();
    }

    private void get_bluetooth_status () {
        var powered = false;
        foreach (unowned var object in bluetooth_manager.get_objects ()) {
            DBusInterface? iface = object.get_interface ("org.bluez.Adapter1");
            if (iface == null) {
                continue;
            }

            if (((QuickSettings.BluezAdapter) iface).powered) {
                powered = true;
                break;
            }
        }

        if (bluetooth_toggle.active != powered) {
            bluetooth_toggle.active = powered;
        }

        if (powered) {
            bluetooth_toggle.icon = new ThemedIcon ("quicksettings-bluetooth-active-symbolic");
        } else {
            bluetooth_toggle.icon = new ThemedIcon ("quicksettings-bluetooth-disabled-symbolic");
        }
    }

    private async void set_bluetooth_status (bool status) {
        foreach (unowned var object in bluetooth_manager.get_objects ()) {
            DBusInterface? iface = object.get_interface ("org.bluez.Adapter1");
            if (iface == null) {
                continue;
            }

            var adapter = (QuickSettings.BluezAdapter) iface;
            if (adapter.powered != status) {
                adapter.powered = status;
            }
        }

        if (!status) {
            foreach (unowned var object in bluetooth_manager.get_objects ()) {
                DBusInterface? iface = object.get_interface ("org.bluez.Device1");
                if (iface == null) {
                    continue;
                }

                var device = (QuickSettings.BluezDevice) iface;
                if (device.connected) {
                    try {
                        yield device.disconnect ();
                    } catch (Error e) {
                        critical (e.message);
                    }
                }
            }
        }
    }
}
