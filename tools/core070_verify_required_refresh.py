"""Refresh prior NB2/shape bindings and retain the original ordinal diagnostic."""
from unittest.mock import patch
import tomllib
import core070_verify_link_boundaries as links
import core070_verify_nb2_formula_required as nb2
import core070_verify_shape_boundaries as shape
import core070_evidence as evidence
ROOT=links.ROOT
def verify():
    with patch.object(nb2,'STATE',ROOT/'.unlazy/core070-aghq/nb2-formula-required-04'):nb2.verify()
    with patch.object(shape,'STATE',ROOT/'.unlazy/core070-aghq/family-boundaries-04'):shape.verify()
    with patch.object(links,'STATE',ROOT/'.unlazy/core070-aghq/link-boundaries-green-03'):links.verify()
    state=ROOT/'.unlazy/core070-aghq/ordinal-link-parity-02'
    plan,p,log=links.process(state,True,0)
    folder=state/'attempt1/receipts';run=tomllib.loads((folder/'run.toml').read_text())
    case='NATIVE-15-ORDINAL-PROBIT'
    assert run['requested_case_ids']==run['completed_case_ids']==[case]
    assert run['actual_assertions']==5 and run['status']=='success' and run['exit_code']==0
    cell=tomllib.loads((folder/('cell-'+case+'.toml')).read_text())
    assert cell==run['cells'][case] and cell['run_id']==run['run_id']
    assert cell['assertions']==dict(passed=5,failed=0,errored=0,broken=0)
    assert cell['fixture_sha256']==links.sha(ROOT/'test/parity/test_ordinal_probit_parity.jl')
    evidence.verify_process(folder,state/'attempt1/process/process-receipt.json',run['execution'])
    assert run['source']['julia_threads']==run['source']['blas_threads']==1
    assert run['source']['reference_commit']==evidence.load_manifest(evidence.DEFAULT_MANIFEST)['reference_commit']
    print('CORE070_LINK_REFRESH_VERIFIED NB2 58; shapes 50; original ordinal diagnostic 5 (not full health/recovery)')
if __name__=='__main__':verify()
