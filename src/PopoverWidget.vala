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

    public PopoverWidget (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (server_type: server_type);
    }

    class construct {
        set_css_name ("quicksettings");
    }

    construct {
        var powermode_toggle = new PowerModeToggle ();

        var toggle_box = new Gtk.Box (HORIZONTAL, 6);
        toggle_box.get_style_context ().add_class ("togglebox");
        toggle_box.add (powermode_toggle);

        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic") {
            halign = CENTER,
            tooltip_text = _("System Settings…")
        };
        settings_button.get_style_context ().add_class ("circular");

        var a11y_button = new Gtk.Button.from_icon_name ("preferences-desktop-accessibility-symbolic") {
            halign = CENTER,
            margin_start = 6,
            tooltip_text = _("Accessiblity Settings…")
        };
        a11y_button.get_style_context ().add_class ("circular");

        var a11y_revealer = new Gtk.Revealer () {
            halign = START,
            hexpand = true,
            child = a11y_button,
            transition_type = SLIDE_LEFT
        };

        var session_box = new SessionBox (server_type) {
            margin_start = 6
        };

        var bottom_box = new Gtk.Box (HORIZONTAL, 0);
        bottom_box.add (settings_button);
        bottom_box.add (a11y_revealer);
        bottom_box.add (session_box);
        bottom_box.get_style_context ().add_class ("togglebox");

        var main_box = new Gtk.Box (VERTICAL, 0);
        main_box.add (toggle_box);
        main_box.add (new Gtk.Separator (HORIZONTAL));
        main_box.add (bottom_box);

        deck = new Hdy.Deck () {
            can_swipe_back = true,
            vhomogeneous = false,
            interpolate_size = true
        };
        deck.add (main_box);

        add (deck);

        if (server_type == GREETER) {
            remove (settings_button);
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
}
