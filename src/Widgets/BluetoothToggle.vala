/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.BluetoothToggle: SettingsToggle {
    public DBusObjectManagerClient bluetooth_manager { get; construct; }

    public BluetoothToggle (DBusObjectManagerClient bluetooth_manager) {
        Object (
            bluetooth_manager: bluetooth_manager,
            icon: new ThemedIcon ("quick-settings-bluetooth-active-symbolic"),
            label: _("Bluetooth")
        );
    }

    construct {
        settings_uri = "settings://network/bluetooth";

        notify["active"].connect (() => {
            set_bluetooth_status.begin (active);
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
    }

    private void on_interface_added (GLib.DBusObject object, GLib.DBusInterface iface) {
        if (iface is Bluez.Adapter) {
            unowned var adapter = (Bluez.Adapter) iface;

            ((DBusProxy) adapter).g_properties_changed.connect ((changed, invalid) => {
                var powered = changed.lookup_value ("Powered", new VariantType ("b"));
                if (powered != null) {
                    get_bluetooth_status ();
                }
            });
        } else if (iface is Bluez.Device) {
            unowned var device = (Bluez.Device) iface;

            ((DBusProxy) device).g_properties_changed.connect ((changed, invalid) => {
                var connected = changed.lookup_value ("Connected", new VariantType ("b"));
                var paired = changed.lookup_value ("Paired", new VariantType ("b"));
                if (connected != null || paired != null) {
                    get_bluetooth_status ();
                }
            });
        }

        get_bluetooth_status ();
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

            if (((Bluez.Adapter) iface).powered) {
                powered = true;
                break;
            }
        }

        if (active != powered) {
            active = powered;
        }

        if (powered) {
            var paired = false;
            foreach (unowned var object in bluetooth_manager.get_objects ()) {
                DBusInterface? iface = object.get_interface ("org.bluez.Device1");
                if (iface == null) {
                    continue;
                }

                var device = (Bluez.Device) iface;
                if (device.connected) {
                    paired = true;
                }
            }

            if (paired) {
                icon = new ThemedIcon ("quick-settings-bluetooth-paired-symbolic");
            } else {
                icon = new ThemedIcon ("quick-settings-bluetooth-active-symbolic");
            }
        } else {
            icon = new ThemedIcon ("quick-settings-bluetooth-disabled-symbolic");
        }
    }

    private async void set_bluetooth_status (bool status) {
        foreach (unowned var object in bluetooth_manager.get_objects ()) {
            DBusInterface? iface = object.get_interface ("org.bluez.Adapter1");
            if (iface == null) {
                continue;
            }

            var adapter = (Bluez.Adapter) iface;
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

                var device = (Bluez.Device) iface;
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
