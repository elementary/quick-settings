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

    public PopoverWidget (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (server_type: server_type);
    }

    class construct {
        set_css_name ("quicksettings");
    }

    construct {
        var screen_reader = new SettingsToggle (
            new ThemedIcon ("orca-symbolic"),
            _("Screen Reader")
        ) {
            settings_uri = "settings://sound"
        };

        var onscreen_keyboard = new SettingsToggle (
            new ThemedIcon ("input-keyboard-symbolic"),
            _("Onscreen Keyboard")
        ) {
            settings_uri = "settings://input/keyboard/behavior"
        };

        var toggle_box = new Gtk.FlowBox () {
            column_spacing = 6,
            homogeneous = true,
            max_children_per_line = 3,
            row_spacing = 12,
            selection_mode = NONE
        };
        toggle_box.get_style_context ().add_class ("togglebox");

        var text_scale = new TextScale ();

        var scale_box = new Gtk.Box (VERTICAL, 0);

        var current_user = new CurrentUser.avatar_only ();

        var current_user_button = new Gtk.Button () {
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

        setup_accounts_services.begin ((obj, res) => {
            var pantheon_service = setup_accounts_services.end (res);
            if (pantheon_service != null &&
                ((DBusProxy) pantheon_service).get_cached_property ("PrefersColorScheme") != null
            ) {
                if (server_type != GREETER) {
                    var darkmode_button = new DarkModeToggle (pantheon_service);
                    toggle_box.add (darkmode_button);
                    show_all ();
                }
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

        realize.connect (() => {
            popover = (Gtk.Popover) get_ancestor (typeof (Gtk.Popover));
        });

        var applications_settings = new Settings ("org.gnome.desktop.a11y.applications");
        applications_settings.bind ("screen-keyboard-enabled", onscreen_keyboard, "active", DEFAULT);
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
    }

    private async PantheonAccountsService? setup_accounts_services () {
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

    public void reset_stack () {
        stack.visible_child = main_box;
    }
}
