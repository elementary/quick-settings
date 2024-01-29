/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2019-2024 elementary, Inc. (https://elementary.io)
 *           2011-2015 Tom Beckmann
 */

/*
 * docs taken from unity indicator-session's
 * src/backend-dbus/org.gnome.SessionManager.EndSessionDialog.xml
 */
public enum Session.Widgets.EndSessionDialogType {
    LOGOUT = 0,
    SHUTDOWN = 1,
    RESTART = 2
}

public class Session.Widgets.EndSessionDialog : Hdy.Window {
    public signal void reboot ();
    public signal void shutdown ();
    public signal void logout ();
    public signal void cancelled ();

    public EndSessionDialogType dialog_type { get; construct; }

    public EndSessionDialog (Session.Widgets.EndSessionDialogType type) {
        Object (dialog_type: type);
    }

    construct {
        string icon_name, heading_text, button_text, content_text;

        switch (dialog_type) {
            case EndSessionDialogType.LOGOUT:
                icon_name = "system-log-out";
                heading_text = _("Are you sure you want to Log Out?");
                content_text = _("This will close all open applications.");
                button_text = _("Log Out");
                break;
            case EndSessionDialogType.SHUTDOWN:
            case EndSessionDialogType.RESTART:
                icon_name = "system-shutdown";
                heading_text = _("Are you sure you want to Shut Down?");
                content_text = _("This will close all open applications and turn off this device.");
                button_text = _("Shut Down");
                break;
            default:
                warn_if_reached ();
                break;
        }

        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.START
        };

        var primary_label = new Gtk.Label (heading_text) {
            hexpand = true,
            max_width_chars = 50,
            wrap = true,
            xalign = 0
        };
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        var secondary_label = new Gtk.Label (content_text) {
            max_width_chars = 50,
            wrap = true,
            xalign = 0
        };

        var cancel = new Gtk.Button.with_label (_("Cancel"));

        var confirm = new Gtk.Button.with_label (button_text);
        confirm.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var action_area = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL) {
            layout_style = Gtk.ButtonBoxStyle.END,
            margin_top = 16,
            spacing = 6
        };

        /*
         * the indicator does not have a separate item for restart, that's
         * why we show both shutdown and restart for the restart action
         * (which is sent for shutdown as described above)
         */
        if (dialog_type == EndSessionDialogType.RESTART) {
            var confirm_restart = new Gtk.Button.with_label (_("Restart"));
            confirm_restart.clicked.connect (() => {
                reboot ();
                destroy ();
            });

            action_area.add (confirm_restart);
        }

        action_area.add (cancel);
        action_area.add (confirm);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (action_area, 0, 2, 2, 1);

        deletable = false;
        resizable = false;
        skip_taskbar_hint = true;
        skip_pager_hint = true;
        type_hint = Gdk.WindowTypeHint.DIALOG;
        set_keep_above (true);
        window_position = Gtk.WindowPosition.CENTER;
        stick ();
        add (grid);

        cancel.grab_focus ();

        var cancel_action = new SimpleAction ("cancel", null);
        cancel_action.activate.connect (() => {
            cancelled ();
            destroy ();
        });

        cancel.clicked.connect (() => {
            cancel_action.activate (null);
        });

        key_press_event.connect ((event) => {
            if (Gdk.keyval_name (event.keyval) == "Escape") {
                cancel_action.activate (null);
            }

            return Gdk.EVENT_PROPAGATE;
        });

        confirm.clicked.connect (() => {
            if (dialog_type == EndSessionDialogType.RESTART || dialog_type == EndSessionDialogType.SHUTDOWN) {
                shutdown ();
            } else {
                logout ();
            }

            destroy ();
        });
    }
}
