/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.PopoverWidget : Gtk.Box {
    private const string FDO_ACCOUNTS_NAME = "org.freedesktop.Accounts";
    private const string FDO_ACCOUNTS_PATH = "/org/freedesktop/Accounts";

    private Gtk.Popover? popover;
    private Hdy.Deck deck;
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
}
