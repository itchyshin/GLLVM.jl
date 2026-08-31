"""Replay the demonstrated freeze gap against its archived parent, then verify repair."""
import hashlib,json,subprocess,sys,tempfile
from pathlib import Path
import core070_family_case_plan as plan
import core070_manifest_coverage as coverage
import core070_evidence as evidence

ROOT=Path(__file__).resolve().parents[1]
BASE='62e594416a9f885fdffa7d5d2268b5f5df34dffe'
STATE=ROOT/'.unlazy/core070-aghq/family-decomposition-01'

def verify():
    prior=subprocess.check_output(['git','show',BASE+':tools/core070_manifest_coverage.py'],cwd=ROOT)
    with tempfile.TemporaryDirectory(prefix='family-coverage-red-') as folder:
        root=Path(folder)
        (root/'core070_manifest_coverage.py').write_bytes(prior)
        test=(ROOT/'tools/test_core070_family_coverage.py').read_bytes()
        (root/'test_core070_family_coverage.py').write_bytes(test)
        command=[sys.executable,'-m','unittest',
            'test_core070_family_coverage.FamilyCoverage.test_entry_probe_cannot_freeze_family_coverage']
        red=subprocess.run(command,cwd=root,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
        assert red.returncode==1 and 'CoverageError not raised' in red.stdout and 'FAILED (failures=1)' in red.stdout
    print('ARCHIVED_FAMILY_SCOPE_GAP_REPRODUCED exit=1')
    for name,count in [('test_core070_family_coverage.py',5),('test_core070_manifest_coverage.py',6)]:
        result=subprocess.run([sys.executable,'-m','unittest','discover','-s','tools','-p',name],
            cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
        assert result.returncode==0 and f'Ran {count} tests' in result.stdout,result.stdout
        print(result.stdout)
    plan.verify()
    from core070_verify_link_refresh import verify as verify_bound_cases
    verify_bound_cases()
    from core070_verify_link_boundaries import verify as verify_links
    verify_links()
    index=coverage.build_index(ROOT)
    assert index==coverage.read_json(ROOT/coverage.INDEX)
    mapping=coverage.read_json(ROOT/coverage.MAPPING)
    assert len(mapping['rows'])==752 and all(not r['executable_case_ids'] for r in mapping['rows'])
    assert len([r for r in mapping['rows'] if r['classification']!='intentionally_excluded'])==698
    assert evidence.load_manifest(evidence.DEFAULT_MANIFEST)['status']=='DRAFT_INCOMPLETE_NOT_FROZEN'
    selftest=subprocess.run([sys.executable,'tools/core070_evidence.py','--self-test'],cwd=ROOT,
        text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
    assert selftest.returncode==0 and 'CORE070_EVIDENCE_SELFTEST_PASS' in selftest.stdout
    print('FAMILY_DECOMPOSITION_VERIFIED_NOT_FROZEN')

if __name__=='__main__':verify()
