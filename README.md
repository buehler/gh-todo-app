# GitHub Todos

[![Codemagic build status](https://api.codemagic.io/apps/69de322591d586c661c2ecc8/69de322591d586c661c2ecc7/status_badge.svg)](https://codemagic.io/app/69de322591d586c661c2ecc8/69de322591d586c661c2ecc7/latest_build)

## Linux x64

Build on Linux x86_64 with Flutter, Make, Clang, CMake, Ninja, pkg-config,
GTK 3 development headers, liblzma development headers, the C++ development
runtime, and libsecret development headers installed. Packaging also requires
[appimagetool](https://github.com/AppImage/appimagetool/releases) on `PATH`.
CI installs these dependencies on Ubuntu 22.04.

```sh
flutter pub get
dart run build_runner build
make -C linux build
make -C linux pkg
```

`pkg` builds before packaging. `make -f linux/Makefile pkg` also works from
the repository root. Staging stays in `build/linux/appimage/gh_todos.AppDir`;
the output is `dist/<pubspec-version>/gh_todos-<pubspec-version>-linux-x86_64.AppImage`.

The AppImage includes Flutter's bundle, libsecret, and libgcrypt/libgpg-error
when linked by libsecret. The host must provide compatible GTK 3,
GLib/GIO/GObject, C/C++ runtimes, graphics libraries and GPU drivers, and a
running session Secret Service provider (such as GNOME Keyring or KWallet
with Secret Service support). Host ABI compatibility is required; building
on Ubuntu 22.04 does not guarantee support for every Linux installation.

Verify the CI artifact on Ubuntu and Bazzite KDE: startup and window icon,
external links, PAT persistence after reopening, and logout. Inspect the
AppDir under `build/` to confirm libsecret is included and the graphics
libraries excluded by the Makefile are absent.
