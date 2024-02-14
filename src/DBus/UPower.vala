/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.freedesktop.UPower")]
public interface QuickSettings.UPower : Object {
    public abstract bool on_battery { owned get; }
}
