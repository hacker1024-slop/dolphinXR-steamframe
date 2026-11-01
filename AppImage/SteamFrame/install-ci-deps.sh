#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Ubuntu 24.04 build dependencies; Qt is supplied separately by the workflow.
set -euo pipefail
if [[ $(id -u) == 0 ]]; then as_root=(); else as_root=(sudo); fi
"${as_root[@]}" apt-get update
"${as_root[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential g++-14 cmake ninja-build pkg-config git ca-certificates curl \
  python3-venv patchelf squashfs-tools binutils file gettext xvfb xauth \
  libgl1-mesa-dev libegl1-mesa-dev libvulkan-dev libgbm-dev \
  libx11-dev libxext-dev libxrandr-dev libxi-dev libxrender-dev \
  libxkbcommon-dev libxkbcommon-x11-0 libxcb-cursor0 \
  libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxcb-xinerama0 \
  libxcb-randr0 libxcb-shape0 libxcb-shm0 libxcb-sync1 libxcb-xfixes0 libxcb-xkb1 \
  libfontconfig1-dev libfreetype6-dev libglib2.0-dev libsm6 libice6 libx11-xcb1 \
  libavcodec-dev libavformat-dev libavutil-dev libswresample-dev libswscale-dev \
  libudev-dev libevdev-dev libasound2-dev libpulse-dev libspeexdsp-dev \
  libbluetooth-dev libhidapi-dev libsystemd-dev libdbus-1-dev libusb-1.0-0-dev \
  libcurl4-openssl-dev libenet-dev libbz2-dev liblzma-dev liblzo2-dev \
  liblz4-dev libzstd-dev libxxhash-dev libpugixml-dev libspng-dev \
  zlib1g-dev libsfml-dev libminiupnpc-dev
