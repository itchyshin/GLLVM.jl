"""Reject false link support, missing scope and damaged run evidence."""
import copy,contextlib,io,shutil,tempfile
from pathlib import Path
from unittest.mock import patch
import core070_verify_link_boundaries as gate

def negatives():
    c=gate.read(gate.CONTRACT)
    changes=[lambda x:x['rows'].pop(),
      lambda x:next(r for r in x['rows'] if r['disposition']=='ADMITTED_UNVALIDATED').update(disposition='documented_extension'),
      lambda x:next(r for r in x['rows'] if r['julia_call']).update(julia_call='wrong_model(Y)'),
      lambda x:x.update(fixture_sha256='0'*64)]
    for change in changes:
        bad=copy.deepcopy(c);change(bad)
        try:gate.validate(bad)
        except AssertionError:pass
        else:raise AssertionError('accepted false link contract')
    damage=[lambda d:(d/'attempt1/links.toml').unlink(),
      lambda d:(d/'attempt1/links.toml').write_text('scope="FIT_PARITY"\n'),
      lambda d:(d/'attempt1/process/01.log').write_text('PASS\n'),
      lambda d:(d/'plan.json').write_text('{}\n'),
      lambda d:(d/'source.tar').unlink()]
    for change in damage:
        with tempfile.TemporaryDirectory(prefix='link-negative-') as tmp:
            d=Path(tmp)/'copy';d.mkdir()
            for file in ['plan.json','source.tar']:shutil.copy2(gate.STATE/file,d/file)
            shutil.copytree(gate.STATE/'attempt1',d/'attempt1');change(d)
            with patch.object(gate,'STATE',d),contextlib.redirect_stdout(io.StringIO()):
                try:gate.verify()
                except (AssertionError,FileNotFoundError,KeyError):pass
                else:raise AssertionError('accepted corrupted link evidence')
    print('CORE070_LINK_NEGATIVES_PASS 4 contract + 5 artifact corruptions')
if __name__=='__main__':negatives()
