/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */
 
[DBus (name = "org.freedesktop.login1.User")]
interface QuickSettings.UserInterface : Object {
    public abstract string state { owned get; }
}