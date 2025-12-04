# Sideload
[![Translation status](https://l10n.elementary.io/widgets/desktop/-/sideload/svg-badge.svg)](https://l10n.elementary.io/engage/desktop/?utm_source=widget)

Flatpak Installer

![screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* libflatpak-dev
* libgranite-7-dev (>= 7.7.0)
* libgtk-4-dev
* libxml2-dev
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.sideload`

    ninja install
    io.elementary.sideload
