# Steam Frame AppImage validation

Tested on 1 November 2026 over SSH to a Steam Frame running SteamOS 0.5.6,
build `20261022.6153909`, on native ARM64 hardware.

Build environment: glibc 2.39, GCC 15.1.1, Qt 6.8.0. The emulator code
includes the build fixes through `611f2c58c4`, with AppImage packaging in this
branch.
Packaging tools and their exact SHA-256 hashes are recorded in `tools.lock.json`
and copied into the image under `usr/share/doc/dolphinxr/`.

## Checks

- Native Release build of `dolphin-emu` and `dolphin-tool` completed.
- The build/packaging entry point `build.sh` was run end to end on the Frame.
- Normal FUSE-mounted execution returned `Dolphin 2609.0`, exit 0.
- `--appimage-extract-and-run --version` returned the same result, exit 0.
- Persistent `--appimage-extract` followed by `squashfs-root/AppRun --version`
  returned the same result, exit 0.
- Running a relocated image from a directory and filename containing spaces
  succeeded.
- The GUI produced a visible 1920x1080 X11 window and remained running for a
  12-second smoke test. The test then terminated it deliberately.
- The running GUI executable was inside the AppImage FUSE mount. Its PID
  namespace matched the host's PID namespace.
- With the image's bundled library directory in `LD_LIBRARY_PATH`, `vulkaninfo`
  enumerated `Turnip Adreno (TM) 750`, Vulkan 1.4.362, using the host Mesa
  26.3.0-devel driver (git-e07916b45f).
- An OpenXR probe linked to the same build's loader and using the image's
  bundled library environment returned `xrCreateInstance=0`, identified
  `SteamVR/OpenXR`, and returned `xrGetSystem=0` with a valid headset system ID.
- No graphics driver/loader libraries, glibc, or ELF interpreter were found in
  the bundled library directory. The executable RUNPATH is `$ORIGIN/../lib`.
- The relocatable `usr/bin/Sys` link resolves to the packaged resource tree,
  including `GC/font_western.bin`. The Qt deployment uses its relative
  `usr/bin/qt.conf` for plugins and imports.
- Bash/POSIX shell syntax, Python parsing, JSON parsing, tooling checksums and
  Git whitespace checks passed.
- SteamVR remained active after the tests.

The OpenXR probe establishes instance creation and headset discovery. It does
not establish a working stereo game session. No game image was supplied, so
controller mapping, gameplay rendering, audio during gameplay and performance
remain untested.

Through SSH, GUI/version checks used `DISPLAY=:0`. The GUI smoke test used an
isolated `DOLPHIN_EMU_USERPATH` directory.
