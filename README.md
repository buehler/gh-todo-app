# GitHub Todos

TODO :)

[![Codemagic build status](https://api.codemagic.io/apps/69de322591d586c661c2ecc8/69de322591d586c661c2ecc7/status_badge.svg)](https://codemagic.io/app/69de322591d586c661c2ecc8/69de322591d586c661c2ecc7/latest_build)

Here is a concise, technical summary you can copy and paste directly to the AI developer or project maintainer to get this fixed in the source repository:

📋 Bug Report: Flutter AppImage Crash on Immutable Linux (Bazzite/Fedora)

Issue Summary:
The AppImage crashes immediately upon launch with a libepoxy initialization error: No provider of eglGetPlatformDisplayEXT found. Requires one of: EGL_EXT_platform_base.
The Root Cause:
The application is bundled using an environment that packages a hardcoded or partial copy of libepoxy inside the AppImage. When running on modern immutable/atomic Linux distributions like Bazzite or Fedora Silverblue, this bundled libepoxy hijacks the runtime OpenGL/EGL function lookups. It attempts to resolve graphics drivers using the internal AppImage paths rather than passing the context to the host system's hardware drivers, resulting in an immediate core dump.
Environment Context:
• OS: Bazzite (Linux / Fedora-based Immutable OS)
• Framework: Flutter (GTK embedding)
• Display Server: Wayland (with XWayland fallback)
Workarounds that bypass the issue:
• Extracting the AppImage via --appimage-extract and manually deleting libepoxy.so* from the payload forces the app to correctly fall back to the host system’s graphics stack and fixes the crash entirely.
Requested Action / Permanent Fix for Devs:
Please update the AppImage packaging pipeline (e.g., appimagetool or your workflow scripts) to explicitly exclude libepoxy, libEGL, and related rendering libraries from being bundled inside the final .AppImage payload. These should instead be treated as dynamic host dependencies so Flutter can safely hook into the user's native GPU drivers at runtime.
If the developer asks for how you successfully bypassed it on your end, let me know which of the previous workarounds worked best for you so we can give them exact details!
