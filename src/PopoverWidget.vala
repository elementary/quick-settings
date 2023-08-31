/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.PopoverWidget : Gtk.Box {
    public signal void close ();

    private const string FDO_ACCOUNTS_NAME = "org.freedesktop.Accounts";
    private const string FDO_ACCOUNTS_PATH = "/org/freedesktop/Accounts";

    private Pantheon.AccountsService? pantheon_service = null;

    class construct {
        set_css_name ("quicksettings");
    }

    construct {
        var toggle_box = new Gtk.Box (HORIZONTAL, 6);

        setup_accounts_services.begin ((obj, res) => {
            setup_accounts_services.end (res);

            if (((DBusProxy) pantheon_service).get_cached_property ("PrefersColorScheme") != null) {
                var darkmode_button = new SettingsToggle (
                    new ThemedIcon ("dark-mode-symbolic"),
                    _("Dark Mode")
                );

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

        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic", MENU) {
            halign = START,
            hexpand = true,
            tooltip_text = _("System Settings…")
        };
        settings_button.get_style_context ().add_class ("circular");

        var session_box = new Gtk.Box (HORIZONTAL, 6);
        session_box.add (settings_button);

        orientation = VERTICAL;
        add (toggle_box);
        add (new Gtk.Separator (HORIZONTAL));
        add (session_box);

        settings_button.clicked.connect (() => {
            close ();

            try {
                AppInfo.launch_default_for_uri ("settings://", null);
            } catch (Error e) {
                critical ("Failed to open system settings: %s", e.message);
            }
        });
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
