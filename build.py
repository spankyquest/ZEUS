#!/usr/bin/env python3
"""Build the installable ZEUS and ZEUS Olympus ZIPs from this repository.

Shared addon code lives once in src/. editions/<name>/ adds that edition's TOC,
Edition.lua, documentation, and edition-only modules; a path may exist in only
one of the two places. @VERSION@ in .toc and .lua files is replaced with the
contents of VERSION.

Usage: python3 build.py [output directory]      (default: dist/ in this folder)
Requires only Python 3.
"""
from pathlib import Path
import hashlib
import re
import shutil
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parent
# edition -> installed addon folder (and TOC name)
EDITIONS = {'general': 'ZEUS', 'olympus': 'ZEUS_Olympus'}
SUFFIX = {'general': '', 'olympus': '-olympus'}
STAMPED = {'.toc', '.lua'}


def version():
    value = (ROOT / 'VERSION').read_text().strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+', value):
        raise SystemExit('Invalid VERSION: ' + value)
    return value


def edition_version(edition):
    return version() + SUFFIX[edition]


def sources(edition):
    """Return {installed relative path: source file} for one edition."""
    files = {'LICENSE': ROOT / 'LICENSE'}
    for base in (ROOT / 'src', ROOT / 'editions' / edition):
        for path in sorted(base.rglob('*')):
            if not path.is_file() or path.name.startswith('.'):
                continue
            rel = path.relative_to(base).as_posix()
            if rel in files:
                raise SystemExit(f'{edition}: {rel} is defined twice ({files[rel]} and {path})')
            files[rel] = path
    return files


def toc_entries(addon):
    """Files listed in an assembled addon folder's TOC, in load order."""
    toc = addon / (addon.name + '.toc')
    return [line.strip() for line in toc.read_text().splitlines()
            if line.strip() and not line.startswith('#')]


def assemble(edition, parent):
    """Write the installable addon folder for one edition into parent/."""
    addon = parent / EDITIONS[edition]
    if addon.exists():
        shutil.rmtree(addon)
    stamp = version().encode()
    for rel, src in sources(edition).items():
        dest = addon / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        data = src.read_bytes()
        if src.suffix in STAMPED:
            data = data.replace(b'@VERSION@', stamp)
        dest.write_bytes(data)
    for entry in toc_entries(addon):
        if not (addon / entry).is_file():
            raise SystemExit(f'{edition}: TOC lists missing file {entry}')
    return addon


def build(out):
    out.mkdir(parents=True, exist_ok=True)
    for stale in out.glob('ZEUS-*-beta.zip'):
        stale.unlink()
    with tempfile.TemporaryDirectory() as tmp:
        for edition, folder in EDITIONS.items():
            addon = assemble(edition, Path(tmp) / edition)
            dest = out / f'ZEUS-{edition_version(edition)}-beta.zip'
            # Fixed timestamps and permissions make rebuilds byte-identical.
            with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
                for path in sorted(addon.rglob('*')):
                    if path.is_file():
                        name = folder + '/' + path.relative_to(addon).as_posix()
                        info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0))
                        info.external_attr = 0o100644 << 16
                        info.compress_type = zipfile.ZIP_DEFLATED
                        archive.writestr(info, path.read_bytes())
            with zipfile.ZipFile(dest) as archive:
                assert archive.testzip() is None
                assert f'{folder}/{folder}.toc' in archive.namelist()
            print(dest)
    zips = sorted(out.glob(f'ZEUS-{version()}*-beta.zip'))
    (out / 'SHA256SUMS.txt').write_text(''.join(
        hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + p.name + '\n' for p in zips))


if __name__ == '__main__':
    build(Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / 'dist')
