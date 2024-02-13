/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "net.hadess.PowerProfiles")]
public interface QuickSettings.PowerProfiles : Object {
    public abstract string active_profile { owned get; set; }
}
