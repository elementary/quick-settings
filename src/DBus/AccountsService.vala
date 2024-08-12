/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "io.elementary.pantheon.AccountsService")]
public interface QuickSettings.PantheonAccountsService : Object {
    public abstract int prefers_color_scheme { get; set; }
}
