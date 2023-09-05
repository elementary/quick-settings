/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "net.hadess.SensorProxy")]
private interface QuickSettings.SensorProxy : DBusProxy {
    public abstract bool has_accelerometer { get; }
}
