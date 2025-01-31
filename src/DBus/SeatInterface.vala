/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */
 
[DBus (name = "org.freedesktop.DisplayManager.Seat")]
interface QuickSettings.SeatInterface : Object {
    public abstract bool has_guest_account { get; }
    public abstract void switch_to_guest (string session_name) throws GLib.Error;
    public abstract void switch_to_user (string username, string session_name) throws GLib.Error;
}