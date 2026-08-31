"""Hash the installed bridge runtime without installing or changing dependencies."""
import hashlib
import json
from pathlib import Path
import sys

def snapshot(package, julia_home):
    package = Path(package).resolve(strict=True)
    home = Path(julia_home).resolve(strict=True)
    files = sorted(p for p in package.rglob('*') if p.is_file())
    files += [home / 'julia', home.parent / 'lib/julia/libunwind.so.8']
    return {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}

if __name__ == '__main__':
    result = snapshot(sys.argv[1], sys.argv[2])
    target = Path(sys.argv[3])
    with target.open('x') as handle:
        json.dump(result, handle, indent=2, sort_keys=True)
        handle.write('\n')
    print(hashlib.sha256(target.read_bytes()).hexdigest())
