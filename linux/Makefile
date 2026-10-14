ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
APPDIR := $(ROOT)/build/linux/appimage/gh_todos.AppDir
VERSION := $(shell awk '/^version:/ { print $$2; exit }' "$(ROOT)/pubspec.yaml")
OUTPUT := $(ROOT)/build/linux/gh_todos-linux-x86_64.AppImage
APP_ID := ch.cbue.gh_todos

.DEFAULT_GOAL := build
.PHONY: build pkg

build:
	@test "$$(uname -s)/$$(uname -m)" = Linux/x86_64 || \
		{ echo "Build on Linux x86_64 (for example, the x64 GitHub Actions runner)." >&2; exit 1; }
	cd "$(ROOT)" && flutter build linux --release

pkg: build
	@command -v appimagetool >/dev/null 2>&1 || \
		{ echo "Install the x86_64 appimagetool from https://github.com/AppImage/appimagetool/releases and put it on PATH." >&2; exit 1; }
	rm -rf "$(APPDIR)"
	mkdir -p "$(APPDIR)"
	cp -a "$(ROOT)/build/linux/x64/release/bundle/." "$(APPDIR)/"
	@set -eu; \
		libdir="$$(pkg-config --variable=libdir libsecret-1)"; \
		dependencies="$$(LC_ALL=C ldd "$$libdir/libsecret-1.so.0")"; \
		if printf '%s\n' "$$dependencies" | grep -q 'not found'; then \
			printf 'Unresolved libsecret dependencies:\n%s\n' "$$dependencies" >&2; exit 1; \
		fi; \
		cp -L "$$libdir/libsecret-1.so.0" "$(APPDIR)/lib/libsecret-1.so.0"; \
		for library in libgcrypt.so.20 libgpg-error.so.0; do \
			path="$$(printf '%s\n' "$$dependencies" | awk -v name="$$library" '$$1 == name && $$2 == "=>" { print $$3; exit }')"; \
			if [ -n "$$path" ]; then cp -L "$$path" "$(APPDIR)/lib/$$library"; fi; \
		done
	# Use the host graphics stack, including its GPU drivers.
	find "$(APPDIR)" \( -type f -o -type l \) \( \
		-name 'libepoxy.so*' -o -name 'libEGL.so*' -o -name 'libEGL_*.so*' -o \
		-name 'libGL.so*' -o -name 'libGLX.so*' -o -name 'libGLX_*.so*' -o \
		-name 'libGLdispatch.so*' -o -name 'libOpenGL.so*' -o \
		-name 'libGLESv1_CM.so*' -o -name 'libGLESv2.so*' -o \
		-name 'libgbm.so*' -o -name 'libglapi.so*' -o -name 'libgallium*.so*' -o \
		-name 'libdrm*.so*' -o -name '*_dri.so*' -o -name 'libnvidia-*.so*' -o \
		-name 'libvulkan.so*' -o -name 'libvulkan_*.so*' \) -delete
	printf '%s\n' '#!/bin/sh' 'set -eu' \
		'APPDIR="$$(CDPATH= cd -- "$$(dirname -- "$$0")" && pwd)"' \
		'export LD_LIBRARY_PATH="$$APPDIR/lib$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}"' \
		'exec "$$APPDIR/gh_todos" "$$@"' > "$(APPDIR)/AppRun"
	chmod +x "$(APPDIR)/AppRun"
	printf '%s\n' '[Desktop Entry]' 'Type=Application' \
		'Name=GitHub Todos' 'GenericName=Todo application' 'Exec=gh_todos' \
		'Icon=$(APP_ID)' 'Terminal=false' 'Categories=Office;' \
		'Keywords=GitHub;Projects;Tasks;' 'StartupNotify=true' \
		'StartupWMClass=$(APP_ID)' > "$(APPDIR)/$(APP_ID).desktop"
	cp "$(ROOT)/assets/icon.png" "$(APPDIR)/$(APP_ID).png"
	ln -s "$(APP_ID).png" "$(APPDIR)/.DirIcon"
	mkdir -p "$(APPDIR)/usr/share/icons/hicolor/1024x1024/apps"
	cp "$(APPDIR)/$(APP_ID).png" "$(APPDIR)/usr/share/icons/hicolor/1024x1024/apps/$(APP_ID).png"
	ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 appimagetool "$(APPDIR)" "$(OUTPUT)"
