/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.PopoverWidget : Gtk.Box {
    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    private const string FDO_ACCOUNTS_NAME = "org.freedesktop.Accounts";
    private const string FDO_ACCOUNTS_PATH = "/org/freedesktop/Accounts";

    private Gtk.Popover? popover;
    private Gtk.Stack stack;
    private Gtk.Box main_box;
    private UserList accounts_view;
    private Gtk.Button current_user_button;

    public PopoverWidget (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (server_type: server_type);
    }

    class construct {
        set_css_name ("quicksettings");
    }

    construct {
        var tattle_box = new TattleBox () {
            halign = CENTER
        };

        var screen_reader = new SettingsToggle (
            _("Screen Reader")
        ) {
            icon_name = "orca-symbolic",
            settings_uri = "settings://sound"
        };

        var onscreen_keyboard = new SettingsToggle (
            _("Onscreen Keyboard")
        ) {
            icon_name = "input-keyboard-symbolic",
            settings_uri = "settings://input/keyboard/behavior"
        };

        var prevent_sleep_toggle = new PreventSleepToggle ();

        var toggle_box = new Gtk.FlowBox () {
            column_spacing = 6,
            homogeneous = true,
            max_children_per_line = 3,
            row_spacing = 12,
            selection_mode = NONE
        };
        toggle_box.get_style_context ().add_class ("togglebox");
        toggle_box.add (prevent_sleep_toggle);

        var text_scale = new TextScale ();

        var scale_box = new Gtk.Box (VERTICAL, 0);

        var current_user = new AvatarButton ();

        current_user_button = new Gtk.Button () {
            child = current_user
        };
        current_user_button.get_style_context ().add_class ("circular");
        current_user_button.get_style_context ().add_class ("flat");
        current_user_button.get_style_context ().add_class ("no-padding");

        var session_box = new SessionBox (server_type) {
            halign = END,
            hexpand = true,
            margin_start = 6
        };

        var bottom_box = new Gtk.Box (HORIZONTAL, 0);
        bottom_box.add (current_user_button);
        bottom_box.add (session_box);
        bottom_box.get_style_context ().add_class ("togglebox");

        main_box = new Gtk.Box (VERTICAL, 0);
        main_box.add (tattle_box);
        main_box.add (toggle_box);
        main_box.add (scale_box);
        main_box.add (new Gtk.Separator (HORIZONTAL));
        main_box.add (bottom_box);

        accounts_view = new UserList ();

        stack = new Gtk.Stack () {
            vhomogeneous = false,
            hhomogeneous = true,
            transition_type = SLIDE_LEFT_RIGHT
        };

        stack.add (main_box);
        stack.add (accounts_view);

        add (stack);

        if (server_type == GREETER) {
            bottom_box.remove (current_user_button);
        }

        if (server_type != GREETER) {
            var darkmode_button = new DarkModeToggle ();
            toggle_box.add (darkmode_button);
            show_all ();
        }

        setup_sensor_proxy.begin ((obj, res) => {
            var sensor_proxy = setup_sensor_proxy.end (res);
            if (sensor_proxy.has_accelerometer) {
                var rotation_toggle = new RotationToggle ();
                toggle_box.add (rotation_toggle);
                show_all ();
            };
        });

        realize.connect (() => {
            popover = (Gtk.Popover) get_ancestor (typeof (Gtk.Popover));
        });

        var applications_settings = new Settings ("org.gnome.desktop.a11y.applications");
        applications_settings.bind ("screen-reader-enabled", screen_reader, "active", DEFAULT);

        var glib_settings = new Settings ("io.elementary.desktop.quick-settings");

        if (server_type == GREETER || glib_settings.get_boolean ("show-a11y")) {
            toggle_box.add (screen_reader);
            toggle_box.add (onscreen_keyboard);

            scale_box.add (text_scale);
        }

        glib_settings.changed["show-a11y"].connect (() => {
            if (glib_settings.get_boolean ("show-a11y") && screen_reader.parent == null) {
                toggle_box.add (screen_reader);
                toggle_box.add (onscreen_keyboard);

                scale_box.add (text_scale);
            } else {
                toggle_box.remove (screen_reader);
                toggle_box.remove (onscreen_keyboard);

                scale_box.remove (text_scale);
            }
        });

        current_user_button.clicked.connect (() => {
            stack.visible_child = accounts_view;
        });

        if (!(Gdk.Display.get_default () is Gdk.Wayland.Display)) {
            applications_settings.bind ("screen-keyboard-enabled", onscreen_keyboard, "active", DEFAULT);
        } else {
            onscreen_keyboard.notify["active"].connect (() => {
                if (!onscreen_keyboard.active) {
                    return;
                }

                onscreen_keyboard.active = false;

                var message_dialog = new Granite.MessageDialog (
                    _("On Screen keyboard is unavailable in the Secure session"),
                    _("Log out and select “Classic session” to use the On Screen Keyboard."),
                    new ThemedIcon ("onboard")
                ) {
                    badge_icon = new ThemedIcon ("system-log-out"),
                    transient_for = (Gtk.Window) get_toplevel ()
                };
                message_dialog.response.connect (message_dialog.destroy);
                message_dialog.present ();
            });
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

    public void reset_stack () {
        stack.visible_child = main_box;
    }

    public async void update_user_tooltip () {
        if (server_type != SESSION || is_running_in_demo_mode ()) {
            current_user_button.tooltip_text = _("Not logged in");
            return;
        }

        current_user_button.tooltip_markup = yield UserManager.get_loggedin_tooltip_markup ();
    }

    private bool is_running_in_demo_mode () {
        var proc_cmdline = File.new_for_path ("/proc/cmdline");
        try {
            var @is = proc_cmdline.read ();
            var dis = new DataInputStream (@is);

            var line = dis.read_line ();
            if ("boot=casper" in line || "boot=live" in line || "rd.live.image" in line) {
                return true;
            }
        } catch (Error e) {
            critical ("Couldn't detect if running in Demo Mode: %s", e.message);
        }

        return false;
    }
}
