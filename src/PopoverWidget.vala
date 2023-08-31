/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.PopoverWidget : Gtk.Box {
    public signal void close ();

    class construct {
        set_css_name ("quicksettings");
    }

    construct {
        Pantheon.AccountsService? pantheon_act = null;

        string? user_path = null;
        try {
            FDO.Accounts? accounts_service = GLib.Bus.get_proxy_sync (
                GLib.BusType.SYSTEM,
               "org.freedesktop.Accounts",
               "/org/freedesktop/Accounts"
            );

            user_path = accounts_service.find_user_by_name (Environment.get_user_name ());
        } catch (Error e) {
            critical (e.message);
        }

        if (user_path != null) {
            try {
                pantheon_act = GLib.Bus.get_proxy_sync (
                    GLib.BusType.SYSTEM,
                    "org.freedesktop.Accounts",
                    user_path,
                    GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES
                );
            } catch (Error e) {
                warning ("Unable to get AccountsService proxy, color scheme preference may be incorrect");
            }
        }

        if (((DBusProxy) pantheon_act).get_cached_property ("PrefersColorScheme") != null) {
            var darkmode_button = new Gtk.ToggleButton () {
                halign = CENTER,
                image =  new Gtk.Image.from_icon_name ("dark-mode-symbolic", MENU)
            };
            darkmode_button.get_style_context ().add_class ("circular");

            var darkmode_label = new Gtk.Label (_("Dark Mode")) {
                ellipsize = MIDDLE,
                max_width_chars = 16
            };
            darkmode_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

            var darkmode_box = new Gtk.Box (VERTICAL, 3);
            darkmode_box.add (darkmode_button);
            darkmode_box.add (darkmode_label);

            add (darkmode_box);

            switch (pantheon_act.prefers_color_scheme) {
                case Granite.Settings.ColorScheme.DARK:
                    break;
                default:
                    break;
            }

            darkmode_button.toggled.connect (() => {
                if (darkmode_button.active) {
                    pantheon_act.prefers_color_scheme = Granite.Settings.ColorScheme.DARK;
                } else {
                    pantheon_act.prefers_color_scheme = Granite.Settings.ColorScheme.NO_PREFERENCE;
                }
            });

            ((DBusProxy) pantheon_act).g_properties_changed.connect ((changed, invalid) => {
                var color_scheme = changed.lookup_value ("PrefersColorScheme", new VariantType ("i"));
                if (color_scheme != null) {
                    switch ((Granite.Settings.ColorScheme) color_scheme.get_int32 ()) {
                        case Granite.Settings.ColorScheme.DARK:

                            break;
                        default:

                            break;
                    }
                }
            });
        }


        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic", MENU) {
            halign = START,
            hexpand = true,
            tooltip_text = _("System Settings…")
        };
        settings_button.get_style_context ().add_class ("circular");

        orientation = VERTICAL;
        spacing = 6;
        add (new Gtk.Separator (HORIZONTAL));
        add (settings_button);

        settings_button.clicked.connect (() => {
            close ();

            try {
                AppInfo.launch_default_for_uri ("settings://", null);
            } catch (Error e) {
                critical ("Failed to open system settings: %s", e.message);
            }
        });
    }
}
