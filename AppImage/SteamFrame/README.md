# DolphinXR AppImage for Steam Frame

Builds a native ARM64 Type 2 AppImage containing DolphinXR, Qt and application
library dependencies. SteamVR, the Vulkan loader and graphics drivers are supplied
by SteamOS. The application runs directly with the current user's normal host
access.

## Run on the Frame

Copy `DolphinXR-SteamFrame-aarch64.AppImage` to a persistent location such as
`~/Applications`, make it executable and run it:

```sh
chmod +x DolphinXR-SteamFrame-aarch64.AppImage
./DolphinXR-SteamFrame-aarch64.AppImage
```

For a non-Steam shortcut, use the AppImage itself as the executable and leave
Proton disabled. Keep SteamVR running when starting a game. Vulkan is selected
on first launch. Game images can be opened from the host filesystem normally.

The default user directory is `~/.local/share/dolphinxr/`, or
`$XDG_DATA_HOME/dolphinxr` if `XDG_DATA_HOME` is set. Configuration is under its
`Config` directory. Set `DOLPHIN_EMU_USERPATH` to select another user directory.

`XR_RUNTIME_JSON` and `VR_PATHREG_OVERRIDE` environment overrides are respected;
on Steam Frame the launcher selects its registered SteamVR paths by default.

If FUSE mounting is unavailable, the pinned runtime supports extraction:

```sh
./DolphinXR-SteamFrame-aarch64.AppImage --appimage-extract-and-run
```

For a persistent extraction instead:

```sh
./DolphinXR-SteamFrame-aarch64.AppImage --appimage-extract
./squashfs-root/AppRun
```

## GitHub Actions builds

The **Steam Frame AppImage** workflow builds on native `ubuntu-24.04-arm`
using GCC 14 and the official Qt 6.8.3 ARM64 SDK, including its ICU libraries.
Ubuntu 24.04 provides the Frame's glibc 2.39 baseline.

Push this branch to your GitHub fork. Relevant source and packaging changes
trigger builds on pushes and pull requests. To use **Actions → Steam Frame
AppImage → Run workflow**, first put the workflow on the fork's default branch.

A successful run uploads `DolphinXR-SteamFrame-aarch64-<commit SHA>` containing
the AppImage and its `.sha256` file, retained for 14 days. Download and extract
the artifact ZIP, then verify and enable execution:

```sh
sha256sum -c DolphinXR-SteamFrame-aarch64.AppImage.sha256
chmod +x DolphinXR-SteamFrame-aarch64.AppImage
```

The job verifies the checksum and runs `--version` using extraction and Xvfb.
Headset, graphics and gameplay checks still require a Frame. Actions use pinned
commit revisions and a read-only repository token; no secrets are needed.
The workflow uploads build artifacts without publishing a GitHub Release.

## Build

Build on native ARM64 Linux with glibc compatible with the target Frame. Building
on the tested SteamOS 0.5.6 image uses glibc 2.39, GCC 15.1.1 and Qt 6.8.0.
The C library and loader are not bundled, so building on a newer glibc can make
an image incompatible with older systems. This is a Steam Frame package, not a
promise of compatibility with all ARM64 Linux distributions.

Install the normal Dolphin Linux development dependencies, including Qt base
and SVG development files, then initialize the repository's Linux submodules.
The build/packaging scripts additionally need Bash, CMake, Ninja, Python 3.11+,
qmake6 (or qmake), patchelf, strip and squashfs-tools with Zstandard support.

From the repository root:

```sh
git -c submodule.Externals/Qt.update=none \
    -c submodule.Externals/FFmpeg-bin.update=none \
    -c submodule.Externals/wil.update=none \
    submodule update --init --recursive --depth 1 --jobs 8
./AppImage/SteamFrame/build.sh
```

On Ubuntu 24.04, `./AppImage/SteamFrame/install-ci-deps.sh` installs the CI
build dependencies using apt and sudo. Install Qt 6.8 separately as shown in
the workflow; Ubuntu's packaged Qt 6.4 is too old for this source. Set
`QMAKE=/path/to/Qt/bin/qmake` to select a Qt SDK. The scripts use its prefix
for CMake and its deployment tools for packaging.

The default build/output directory is `~/.cache/dolphinxr-appimage/`.
Override it with `BUILD_ROOT` (outside the checkout) and set `JOBS` to adjust
parallelism; the default is four jobs. The build uses the current source tree.
To package an existing compatible CMake build without recompiling:

```sh
./AppImage/SteamFrame/package.sh /path/to/cmake-build /path/to/output
```

That build must enable VR/Vulkan, install to `/usr`, use `lib` as its install
library directory, and contain both `dolphin-emu` and `dolphin-tool` targets.
The scripts stage the install without root access, use linuxdeploy with its Qt
plugin, add a relocatable `Sys` link, and append a SquashFS filesystem to the
AppImage runtime. Graphics drivers and loaders are excluded from bundling.

`tools.lock.json` pins SHA-256 hashes for linuxdeploy, its Qt plugin and the
AppImage runtime. Downloads are verified before execution and cached under the
output directory. Downloads use GitHub release asset IDs instead of mutable
`continuous` URLs.
If upstream deletes a pinned asset, the download fails instead of selecting a
replacement. Tool hashes are also verified before compilation. Review and
update the lock file deliberately when upgrading.

On Arch/SteamOS and Debian/Ubuntu, dependency package license notices are
copied into the image. Qt SDK and ICU notices are included, along with the
SDK SBOM when available. For other build distributions, include the corresponding
dependency license notices before redistributing the resulting image. Dolphin source is licensed
GPL-2.0-or-later; dependency licenses remain applicable.

The build disables cubeb's Android audio autodetection because the Frame's
Android development headers can otherwise introduce a native Linux dependency
on Android `liblog`. It also uses the loader's bundled JSON implementation.

## Diagnostics

```sh
XR_LOADER_DEBUG=all ./DolphinXR-SteamFrame-aarch64.AppImage 2>&1 | tee dolphinxr.log
```

When running GUI or version checks through SSH, set `DISPLAY=:0` for the
Frame's gamescope X11 session.

The resource directory and bundled libraries are resolved relative to the
AppImage mount or extraction directory. See `VALIDATION.md` for target testing.
