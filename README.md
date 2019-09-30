# Sideload
[![Translation status](https://l10n.elementary.io/widgets/desktop/-/sideload/svg-badge.svg)](https://l10n.elementary.io/engage/desktop/?utm_source=widget)

Flatpak Installer

## Building, Testing, and Installation

You'll need the following dependencies:
* libflatpak-dev
* libgranite-dev (>=5)
* libgtk-3-dev
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.sideload`

    ninja install
    io.elementary.sideload
