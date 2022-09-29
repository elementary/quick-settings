/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

public class QuickSettings.DisplayWidget : Gtk.Box {
    construct {
        var settings_icon = new Gtk.Image.from_icon_name ("open-menu-symbolic");

        append (settings_icon);
    }
}
