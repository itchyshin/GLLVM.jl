"""Reject omitted boundaries, disguised extensions, and corrupted run artifacts."""
import contextlib, copy, io, json, shutil, tempfile
from pathlib import Path
from unittest.mock import patch
import core070_verify_shape_boundaries as gate

def negatives():
    original=gate.read(gate.CONTRACT)
    changes=[lambda c:c['rows'].pop(),
             lambda c:c['rows'].append(copy.deepcopy(c['rows'][0])),
             lambda c:next(r for r in c['rows'] if r['fixture']).update(julia_call='wrong_model(Y)'),
             lambda c:c.update(source_manifest_sha256='0'*64),
             lambda c:c.update(fixture_sha256='0'*64),
             lambda c:c.update(status='FULL_FAMILY_PARITY'),
             lambda c:next(r for r in c['rows'] if r['disposition']=='documented_extension').update(disposition='reject'),
             lambda c:next(r for r in c['rows'] if r['disposition']=='UNRESOLVED').update(disposition='reject')]
    for change in changes:
        c=copy.deepcopy(original);change(c)
        try:gate.validate(c)
        except AssertionError:pass
        else:raise AssertionError('Accepted corrupted boundary contract')
    def receipt(d,key,value):
        p=d/'attempt1/process/process-receipt.json';v=gate.read(p);v[key]=value;p.write_text(json.dumps(v))
    damage=[lambda d:(d/'attempt1/boundary.toml').unlink(),
            lambda d:(d/'attempt1/boundary.toml').write_text('status="PASS"\n'),
            lambda d:(d/'r/raw.tsv').write_text('PASS\n'),
            lambda d:(d/'r/receipt.json').unlink(),
            lambda d:(d/'attempt1/process/01.log').write_text('PASS\n'),
            lambda d:receipt(d,'source_unchanged',False),
            lambda d:receipt(d,'results',[]),
            lambda d:(d/'source.tar').unlink()]
    for change in damage:
        with tempfile.TemporaryDirectory(prefix='shape-negative-') as folder:
            d=Path(folder)/'copy';d.mkdir()
            for f in ('plan.json','source.tar'):shutil.copy2(gate.STATE/f,d/f)
            for f in ('r','attempt1'):shutil.copytree(gate.STATE/f,d/f)
            change(d)
            with patch.object(gate,'STATE',d),contextlib.redirect_stdout(io.StringIO()):
                try:gate.verify()
                except (AssertionError,FileNotFoundError):pass
                else:raise AssertionError('Accepted corrupted boundary evidence')
    print('CORE070_SHAPE_NEGATIVES_PASS 8 contract + 8 artifact corruptions')
if __name__=='__main__':negatives()
