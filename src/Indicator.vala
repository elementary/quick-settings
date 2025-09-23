/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.Indicator : Wingpanel.Indicator {
    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    private EndSessionDialog? current_dialog;
    private PopoverWidget? popover_widget;

    public Indicator (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (
            code_name: "quick-settings",
            server_type: server_type,
            visible: true
        );
    }

    construct {
        GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");

        // Prevent a race that skips automatic resource loading
        // https://github.com/elementary/wingpanel-indicator-bluetooth/issues/203
        Gtk.IconTheme.get_default ().add_resource_path ("/org/elementary/wingpanel/icons");

        EndSessionDialogServer.init ();
        EndSessionDialogServer.get_default ().show_dialog.connect (
            (type) => show_dialog ((EndSessionDialogType) type)
        );
    }

    private void show_dialog (EndSessionDialogType type) {
        unowned var popover = (Gtk.Popover) popover_widget?.get_ancestor (typeof (Gtk.Popover));
        popover?.popdown ();

        if (current_dialog != null) {
            if (current_dialog.dialog_type != type) {
                current_dialog.destroy ();
            } else {
                return;
            }
        }

        unowned var server = EndSessionDialogServer.get_default ();

        current_dialog = new EndSessionDialog (type);
        current_dialog.destroy.connect (() => {
            server.closed ();
            current_dialog = null;
        });

        current_dialog.cancelled.connect (() => server.canceled ());
        current_dialog.logout.connect (() => server.confirmed_logout ());
        current_dialog.shutdown.connect (() => {
            try {
                // See https://www.freedesktop.org/software/systemd/man/latest/org.freedesktop.login1.html for flags values
                // #define SD_LOGIND_ROOT_CHECK_INHIBITORS (UINT64_C(1) << 0) == 1
                Login1Manager.get_default ().object.power_off_with_flags (1);
            } catch (Error e) {
                warning ("Unable to shutdown: %s", e.message);
            }
        });

        current_dialog.reboot.connect (() => {
            try {
                // See https://www.freedesktop.org/software/systemd/man/latest/org.freedesktop.login1.html for flags values
                // #define SD_LOGIND_KEXEC_REBOOT (UINT64_C(1) << 1) == 2
                Login1Manager.get_default ().object.reboot_with_flags (2);
            } catch (Error e) {
                warning ("Unable to reboot: %s", e.message);
            }
        });

        current_dialog.present ();
    }

    public override Gtk.Widget get_display_widget () {
        var indicator_icon = new Gtk.Image () {
            icon_name = "quick-settings-symbolic",
            pixel_size = 24
        };

        return indicator_icon;
    }

    public override Gtk.Widget? get_widget () {
        if (popover_widget == null) {
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("io/elementary/quick-settings/Indicator.css");

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            popover_widget = new PopoverWidget (server_type);
        }

        return popover_widget;
    }

    public override void opened () {
        if (popover_widget == null) {
            return;
        }

        popover_widget.update_user_tooltip.begin ();
    }

    public override void closed () {
        if (popover_widget == null) {
            return;
        }

        popover_widget.reset_stack ();
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    return new QuickSettings.Indicator (server_type);
}
