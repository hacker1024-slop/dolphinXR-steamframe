#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Package an existing native ARM64 CMake build, without rebuilding Dolphin.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
script_dir=$PWD
repo_root=$(cd ../.. && pwd -P)
build_dir=$(realpath "${1:?Usage: package.sh CMAKE_BUILD_DIR OUTPUT_DIR}")
output_dir=$(realpath -m "${2:?Usage: package.sh CMAKE_BUILD_DIR OUTPUT_DIR}")
case "$output_dir/" in
  "$repo_root/"*) echo 'OUTPUT_DIR must be outside the source checkout.' >&2; exit 1 ;;
esac
[[ $(uname -m) == aarch64 ]] || { echo 'Package on native ARM64 Linux.' >&2; exit 1; }
appdir="$output_dir/DolphinXR.AppDir"
tools="$output_dir/tools"
mkdir -p "$output_dir"
python3 "$script_dir/fetch-tools.py" "$tools"
# Only this script's named staging directory is replaced.
rm -rf -- "$appdir"
mkdir -p "$appdir"
DESTDIR="$appdir" cmake --install "$build_dir"
# Dolphin first looks for Sys beside its executable, making resources relocatable.
ln -s ../share/dolphin-emu/Sys "$appdir/usr/bin/Sys"
rm -f "$appdir/usr/share/applications/dolphin-emu.desktop"
install -Dm644 "$script_dir/dolphinxr.desktop" "$appdir/usr/share/applications/dolphinxr.desktop"
install -Dm644 "$appdir/usr/share/icons/hicolor/scalable/apps/dolphin-emu.svg" \
  "$appdir/usr/share/icons/hicolor/scalable/apps/dolphinxr.svg"
export PATH="$tools:$PATH"
export QMAKE="${QMAKE:-$(command -v qmake6 || command -v qmake)}"
export EXTRA_QT_MODULES=svg
export APPIMAGE_EXTRACT_AND_RUN=1
# Host graphics loaders and drivers must match SteamOS and SteamVR.
"$tools/linuxdeploy-aarch64.AppImage" --appimage-extract-and-run \
  --appdir "$appdir" --executable "$appdir/usr/bin/dolphin-emu" \
  --executable "$appdir/usr/bin/dolphin-tool" \
  --desktop-file "$appdir/usr/share/applications/dolphinxr.desktop" \
  --icon-file "$appdir/usr/share/icons/hicolor/scalable/apps/dolphinxr.svg" \
  --exclude-library='libvulkan*' --exclude-library='libEGL*' \
  --exclude-library='libGL*' --exclude-library='libdrm*' --exclude-library='libgbm*' \
  --plugin qt
# Replace linuxdeploy's entry point with the Frame-specific, namespace-free launcher.
rm -f "$appdir/AppRun"
install -m755 "$script_dir/AppRun" "$appdir/AppRun"
install -Dm644 "$repo_root/COPYING" "$appdir/usr/share/licenses/dolphinxr/COPYING"
cp -a "$repo_root/LICENSES" "$appdir/usr/share/licenses/dolphinxr/"
python3 "$script_dir/copy-licenses.py" "$appdir"
cp -a "$script_dir/licenses/Qt" "$script_dir/licenses/ICU" "$appdir/usr/share/licenses/"
install -Dm644 "$script_dir/tools.lock.json" "$appdir/usr/share/doc/dolphinxr/AppImage-tools.lock.json"
qt_prefix=$("$QMAKE" -query QT_INSTALL_PREFIX)
if [[ -d "$qt_prefix/sbom" ]]; then
  cp -a "$qt_prefix/sbom" "$appdir/usr/share/doc/dolphinxr/qt-sbom"
fi
# Build a standard Type 2 image by appending SquashFS to the pinned runtime.
filesystem="$output_dir/DolphinXR.squashfs"
mksquashfs "$appdir" "$filesystem" -noappend -all-root -no-xattrs \
  -comp zstd -Xcompression-level 15 -processors "${JOBS:-4}"
image="$output_dir/DolphinXR-SteamFrame-aarch64.AppImage"
cat "$tools/runtime-aarch64" "$filesystem" > "$image.part"
chmod 755 "$image.part"
mv -f "$image.part" "$image"
rm -f "$filesystem"
(cd "$output_dir" && sha256sum "$(basename "$image")" > "$(basename "$image").sha256")
printf 'AppImage: %s\n' "$image"
