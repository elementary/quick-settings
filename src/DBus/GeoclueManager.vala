/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2011-2024 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.freedesktop.GeoClue2.Manager")]
interface QuickSettings.GeoclueManager : DBusProxy {
    public abstract bool in_use { get; }
}
