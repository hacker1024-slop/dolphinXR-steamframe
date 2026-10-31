#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Fetch and verify the AppImage tooling pinned in tools.lock.json."""
import hashlib
import json
from pathlib import Path
import sys
import urllib.request


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    destination = Path(sys.argv[1])
    destination.mkdir(parents=True, exist_ok=True)
    lock = json.loads(Path(__file__).with_name('tools.lock.json').read_text())
    for tool in lock['tools']:
        target = destination / tool['file']
        if not target.exists() or digest(target) != tool['sha256']:
            temporary = target.with_suffix(target.suffix + '.part')
            try:
                request = urllib.request.Request(tool['url'], headers={'User-Agent': 'DolphinXR-AppImage-build'})
                with urllib.request.urlopen(request, timeout=60) as response, temporary.open('wb') as stream:
                    while chunk := response.read(1024 * 1024):
                        stream.write(chunk)
                if digest(temporary) != tool['sha256']:
                    raise RuntimeError(f"Checksum mismatch for {tool['file']}; review tools.lock.json before updating a pin")
                temporary.replace(target)
            finally:
                temporary.unlink(missing_ok=True)
        target.chmod(0o755)
        print(f"Verified {tool['file']}")


if __name__ == '__main__':
    main()
