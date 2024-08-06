# Quick Settings Indicator
[![Translation status](https://l10n.elementary.io/widget/wingpanel/quick-settings/svg-badge.svg)](https://l10n.elementary.io/engage/wingpanel/)

![](https://raw.githubusercontent.com/elementary/quick-settings/main/data/screenshot.png)

## Building and Installation

You'll need the following dependencies:

* libgranite-dev
* libhandy-1-dev
* libwingpanel-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    ninja install
