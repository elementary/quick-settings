/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2019-2024 elementary, Inc. (https://elementary.io)
 *           2011-2015 Tom Beckmann
 */

/*
 * docs taken from unity indicator-session's
 * src/backend-dbus/org.gnome.SessionManager.EndSessionDialog.xml
 */
public enum QuickSettings.EndSessionDialogType {
    LOGOUT = 0,
    SHUTDOWN = 1,
    RESTART = 2
}

public class QuickSettings.EndSessionDialog : Granite.MessageDialog {
    public signal void reboot ();
    public signal void shutdown ();
    public signal void logout ();
    public signal void cancelled ();

    public EndSessionDialogType dialog_type { get; construct; }

    private Gtk.CheckButton? updates_check_button;
    private Gtk.EventControllerKey key_controller;

    public EndSessionDialog (QuickSettings.EndSessionDialogType type) {
        Object (dialog_type: type);
    }

    construct {
        string button_text;
        switch (dialog_type) {
            case EndSessionDialogType.LOGOUT:
                image_icon = new ThemedIcon ("system-log-out");
                primary_text = _("Are you sure you want to Log Out?");
                secondary_text = _("This will close all open applications.");
                button_text = _("Log Out");
                break;
            case EndSessionDialogType.SHUTDOWN:
            case EndSessionDialogType.RESTART:
                image_icon = new ThemedIcon ("system-shutdown");
                primary_text = _("Are you sure you want to Shut Down?");
                secondary_text = _("This will close all open applications and turn off this device.");
                button_text = _("Shut Down");
                break;
            default:
                warn_if_reached ();
                break;
        }

        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.START
        };

        /*
         * the indicator does not have a separate item for restart, that's
         * why we show both shutdown and restart for the restart action
         * (which is sent for shutdown as described above)
         */
        if (dialog_type == EndSessionDialogType.RESTART) {
            var confirm_restart = (Gtk.Button) add_button (_("Restart"), 1);
            confirm_restart.clicked.connect (() => {
                set_offline_trigger (REBOOT); // This will just do nothing if no updates are available
                reboot ();
                destroy ();
            });
        }

        var cancel = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var confirm = (Gtk.Button) add_button (button_text, Gtk.ResponseType.ACCEPT);
        confirm.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        if (dialog_type != LOGOUT) {
            bool has_prepared_updates = false;
            try {
                has_prepared_updates = Pk.offline_get_prepared_ids ().length > 0;
            } catch (Error e) {
                warning ("Failed to check for prepared updates, assuming no: %s", e.message);
            }

            if (has_prepared_updates) {
                updates_check_button = new Gtk.CheckButton () {
                    active = true,
                    label = _("Install pending system updates"),
                };
                updates_check_button.show ();

                custom_bin.add (updates_check_button);
            }
        }

        cancel.grab_focus ();

        var cancel_action = new SimpleAction ("cancel", null);
        cancel_action.activate.connect (() => {
            cancelled ();
            destroy ();
        });

        cancel.clicked.connect (() => {
            cancel_action.activate (null);
        });

        key_controller = new Gtk.EventControllerKey (this);
        key_controller.key_released.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Escape) {
                cancel_action.activate (null);
            }
        });

        confirm.clicked.connect (() => {
            if (dialog_type == EndSessionDialogType.RESTART || dialog_type == EndSessionDialogType.SHUTDOWN) {
                if (set_offline_trigger (POWER_OFF)) {
                    reboot ();
                } else {
                    shutdown ();
                }
            } else {
                logout ();
            }

            destroy ();
        });

        realize.connect (() => Idle.add_once (() => init_wl ()));
    }

    private bool set_offline_trigger (Pk.OfflineAction action) {
        if (updates_check_button == null) {
            return false;
        }

        if (updates_check_button.active) {
            try {
                Pk.offline_trigger (action);
                return true;
            } catch (Error e) {
                critical ("Failed to set offline trigger for updates: %s", e.message);
            }
        } else {
            try {
                if (Pk.offline_get_action () != UNSET) {
                    Pk.offline_cancel ();
                }
            } catch (Error e) {
                critical ("Failed to check/cancel offline trigger for updates: %s", e.message);
            }
        }

        return false;
    }

    public void registry_handle_global (Wl.Registry wl_registry, uint32 name, string @interface, uint32 version) {
        if (@interface == "io_elementary_pantheon_shell_v1") {
            var desktop_shell = wl_registry.bind<PantheonDesktop.Shell> (name, ref PantheonDesktop.Shell.iface, uint32.min (version, 1));
            unowned var window = get_window ();
            if (window is Gdk.Wayland.Window) {
                unowned var wl_surface = ((Gdk.Wayland.Window) window).get_wl_surface ();
                var extended_behavior = desktop_shell.get_extended_behavior (wl_surface);
                extended_behavior.set_keep_above ();
                extended_behavior.make_centered ();
                extended_behavior.make_modal (1);
            }
        }
    }

    private static Wl.RegistryListener registry_listener;
    private void init_wl () {
        registry_listener.global = registry_handle_global;
        unowned var display = Gdk.Display.get_default ();
        if (display is Gdk.Wayland.Display) {
            unowned var wl_display = ((Gdk.Wayland.Display) display).get_wl_display ();
            var wl_registry = wl_display.get_registry ();
            wl_registry.add_listener (
                registry_listener,
                this
            );

            if (wl_display.roundtrip () < 0) {
                return;
            }
        }
    }
}
