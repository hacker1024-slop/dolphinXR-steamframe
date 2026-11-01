#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
repo_root=$(cd ../.. && pwd -P)
build_root=$(realpath -m "${BUILD_ROOT:-${XDG_CACHE_HOME:-$HOME/.cache}/dolphinxr-appimage}")
case "$build_root/" in
  "$repo_root/"*) echo 'BUILD_ROOT must be outside the source checkout.' >&2; exit 1 ;;
esac
if [[ $(uname -m) != aarch64 ]]; then
  echo 'Build on native ARM64 Linux with a Steam Frame-compatible glibc baseline.' >&2
  exit 1
fi
for tool in cmake ninja python3 mksquashfs patchelf strip; do command -v "$tool" >/dev/null; done
export QMAKE="${QMAKE:-$(command -v qmake6 || command -v qmake)}"
command -v "$QMAKE" >/dev/null
qt_prefix=$("$QMAKE" -query QT_INSTALL_PREFIX)
# Verify external tools before spending time compiling Dolphin.
python3 ./fetch-tools.py "$build_root/tools"
cmake -S "$repo_root" -B "$build_root/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_PREFIX_PATH="$qt_prefix" \
  -DENABLE_VR=ON -DENABLE_VULKAN=ON -DENABLE_ALSA=OFF \
  -DENABLE_SDL=ON -DENABLE_EVDEV=ON -DENABLE_TESTS=OFF -DENABLE_AUTOUPDATE=OFF \
  -DUSE_DISCORD_PRESENCE=OFF -DUSE_SYSTEM_SDL3=OFF -DUSE_SYSTEM_FMT=OFF \
  -DUSE_SYSTEM_MBEDTLS=OFF -DUSE_SYSTEM_LIBMGBA=OFF \
  -DBUILD_LOADER_WITH_EXCEPTION_HANDLING=ON -DBUILD_WITH_SYSTEM_JSONCPP=OFF \
  -DUSE_AUDIOTRACK=OFF -DUSE_OPENSL=OFF \
  -DDISTRIBUTOR=dolphinXR-Steam-Frame-AppImage
cmake --build "$build_root/build" --target dolphin-emu dolphin-tool --parallel "${JOBS:-4}"
./package.sh "$build_root/build" "$build_root"
