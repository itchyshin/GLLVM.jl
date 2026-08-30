"""Fresh local gate for source-to-case closure, without claiming scope complete."""
import json,re,subprocess,sys,tempfile
from pathlib import Path
import core070_evidence as evidence
import core070_manifest_coverage as coverage
ROOT=Path(__file__).resolve().parents[1]

def run(argv,count=None):
    p=subprocess.run(argv,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=40)
    assert p.returncode==0,p.stdout
    if count is not None:assert re.search(r'Ran '+str(count)+r' tests? in ',p.stdout),p.stdout
    print(p.stdout)

if __name__=='__main__':
    index=coverage.build_index(ROOT)
    assert index==coverage.read_json(ROOT/coverage.INDEX)
    mapping=coverage.read_json(ROOT/coverage.MAPPING)
    assert len(index['facts'])==752 and len(mapping['rows'])==752
    assert {r['source_id'] for r in mapping['rows']}=={r['id'] for r in index['facts']}
    assert sum(f['classification']!='intentionally_excluded' for f in index['facts'])==698
    for pattern,count in [('test_core070_manifest_coverage.py',6),('test_core070_collection.py',9),('test_core070_assertion_groups.py',4),('test_core070_process_evidence.py',5)]:
        run([sys.executable,'-m','unittest','discover','-s','tools','-p',pattern],count)
    run([sys.executable,'tools/core070_evidence.py','--self-test'])
    assert evidence.load_manifest(evidence.DEFAULT_MANIFEST)['status']=='DRAFT_INCOMPLETE_NOT_FROZEN'
    with tempfile.TemporaryDirectory() as folder:
        path=Path(folder)/'false-frozen.toml'
        path.write_text(evidence.DEFAULT_MANIFEST.read_text().replace('status = "DRAFT_INCOMPLETE_NOT_FROZEN"','status = "FROZEN"',1))
        try:evidence.load_manifest(path)
        except evidence.EvidenceError as error:assert 'SOURCE_COVERAGE' in str(error)
        else:raise AssertionError('label-only freeze accepted')
    record=coverage.read_json(ROOT/'docs/dev-log/core070/manifest-coverage-evidence.json')
    assert record['status']=='FREEZE_GAP_REPAIRED_CONTRACT_STILL_DRAFT'
    assert (record['source_facts'],record['nonexcluded_unmapped'],record['test_count'])==(752,698,24)
    required={'tools/core070_evidence.py','tools/core070_manifest_coverage.py','tools/core070_data_case_index.R',
      'tools/test_core070_manifest_coverage.py','tools/test_core070_collection.py','tools/core070_verify_manifest_coverage.py',coverage.INDEX,coverage.MAPPING,
      '.unlazy/core070-aghq/manifest-coverage-01/verification.log','.unlazy/core070-aghq/manifest-coverage-01/binomial-existing-evidence.log'}
    assert set(record['artifacts'])==required
    for name,pin in record['artifacts'].items():assert coverage.sha(ROOT/name)==pin,name
    print('SOURCE_CASE_COVERAGE_GATE_VERIFIED_FULL_MANIFEST_UNFROZEN')
