# Quick Settings Indicator
Prototype quick settings menu

## Building and Installation

You'll need the following dependencies:

* libgtk-3-dev
* libgranite-dev >=6.0.0
* libhandy-1-dev >=1.0
* libwingpanel-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    ninja install
