/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2011-2024 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "io.elementary.wingpanel.session.EndSessionDialog")]
public class QuickSettings.EndSessionDialogServer : Object {
    private static EndSessionDialogServer? instance;

    [DBus (visible = false)]
    public static void init () {
        Bus.own_name (BusType.SESSION, "io.elementary.wingpanel.session.EndSessionDialog", BusNameOwnerFlags.NONE,
            (connection) => {
                try {
                    connection.register_object ("/io/elementary/wingpanel/session/EndSessionDialog", get_default ());
                } catch (Error e) {
                    warning (e.message);
                }
            },
            () => {},
            () => warning ("Could not acquire name"));
    }

    public static unowned EndSessionDialogServer get_default () {
        if (instance == null) {
            instance = new EndSessionDialogServer ();
        }

        return instance;
    }

    [DBus (visible = false)]
    public signal void show_dialog (uint type, uint32 triggering_event_timestamp);

    public signal void confirmed_logout ();
    public signal void confirmed_reboot ();
    public signal void confirmed_shutdown ();
    public signal void canceled ();
    public signal void closed ();

    private EndSessionDialogServer () {

    }

    public void open (uint type, uint timestamp, uint open_length, ObjectPath[] inhibiters) throws Error {
        if (type > (int) EndSessionDialogType.RESTART) {
            throw new DBusError.NOT_SUPPORTED ("Hibernate, suspend and hybrid sleep are not supported actions yet");
        }

        show_dialog (type, timestamp);
    }
}
