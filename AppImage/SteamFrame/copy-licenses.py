#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Include distro license notices for libraries deployed into an AppDir."""
from pathlib import Path
import shutil
import subprocess
import sys

appdir = Path(sys.argv[1])
names = {p.name for p in (appdir / 'usr').rglob('*') if '.so' in p.name and p.is_file()}
originals = sorted({str(p) for p in Path('/usr/lib').rglob('*') if p.name in names and p.is_file()})
destination = appdir / 'usr/share/licenses'

if shutil.which('pacman'):
    if not originals:
        raise RuntimeError('No host library origins found for deployed dependencies')
    owners = subprocess.run(['pacman', '-Qoq', *originals], text=True, capture_output=True, check=False)
    for package in sorted(set(owners.stdout.splitlines())):
        source = Path('/usr/share/licenses') / package
        if source.is_dir():
            shutil.copytree(source, destination / package, dirs_exist_ok=True)
elif shutil.which('dpkg-query'):
    if not originals:
        raise RuntimeError('No host library origins found for deployed dependencies')
    # dpkg can record /lib paths even when merged-/usr exposes them under /usr/lib.
    candidates = sorted(set(originals + [p.removeprefix('/usr') for p in originals]))
    owners = subprocess.run(['dpkg-query', '-S', *candidates], text=True, capture_output=True, check=False)
    packages = set()
    for line in owners.stdout.splitlines():
        if ': ' in line:
            owner, _ = line.split(': ', 1)
            packages.update(p.strip().split(':')[0] for p in owner.split(','))
    if not packages:
        raise RuntimeError('dpkg could not identify any deployed dependency packages')
    for package in sorted(packages):
        source = Path('/usr/share/doc') / package / 'copyright'
        if source.is_file():
            target = destination / package / 'copyright'
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
else:
    print('Include your distribution dependency license notices before redistributing this AppImage.', file=sys.stderr)
