"""Check retained desktop/mobile evidence of the executed fixed-noise guide."""
import hashlib,json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
base=root/'.unlazy/core070-aghq/source-fixed-residual-docs-03'
plan=json.loads((base/'plan.json').read_text())
for name in ['docs/make.jl','docs/src/structured-dependence.md','docs/src/low-level-reference.md','src/source_fit.jl']:
    assert hashlib.sha256((root/name).read_bytes()).hexdigest()==plan['pins'][name]
rows=json.loads((base/'visual/visual.json').read_text())
assert [r['label'] for r in rows]==['desktop','mobile']
assert [r['width'] for r in rows]==[1440,390]
for row in rows:
    assert row['body'] and not row['errors'] and not row['brokenAnchors']
    assert row['scrollWidth']==row['width']
    for kind in ['top','source','example']:
        assert (base/'visual'/f"{row['label']}-{kind}.png").stat().st_size>1000
prior=json.loads((root/'.unlazy/core070-aghq/source-fixed-residual-docs-02/visual/visual.json').read_text())
assert all(len(r['errors'])==1 and '/versions.js: net::ERR_ABORTED' in r['errors'][0] for r in prior)
print('FIXED_SOURCE_DESKTOP_MOBILE_AND_VERSION_REPAIR_VERIFIED')
