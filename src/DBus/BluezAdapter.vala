/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.bluez.Adapter1")]
public interface QuickSettings.BluezAdapter : Object {
    public abstract bool powered { get; set; }
}
