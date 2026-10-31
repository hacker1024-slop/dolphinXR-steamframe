#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Include Arch/SteamOS package licenses for libraries deployed into an AppDir."""
from pathlib import Path
import shutil
import subprocess
import sys

appdir = Path(sys.argv[1])
if shutil.which('pacman'):
    names = {p.name for p in (appdir / 'usr').rglob('*') if '.so' in p.name and p.is_file()}
    originals = []
    for root in (Path('/usr/lib'),):
        for path in root.rglob('*'):
            if path.name in names and path.is_file():
                originals.append(str(path))
    if not originals:
        raise RuntimeError('No host library origins found for deployed dependencies')
    owners = subprocess.run(['pacman', '-Qoq', *originals], text=True, capture_output=True, check=False)
    for package in sorted(set(owners.stdout.splitlines())):
        source = Path('/usr/share/licenses') / package
        if source.is_dir():
            shutil.copytree(source, appdir / 'usr/share/licenses' / package, dirs_exist_ok=True)
else:
    print('Include your distribution dependency license notices before redistributing this AppImage.', file=sys.stderr)
