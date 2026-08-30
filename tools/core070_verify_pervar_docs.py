"""Verify the exact example and strict local build at their recorded scope."""
import argparse,hashlib,json,re,tomllib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None,build=False):
    if e is None:e=json.loads((ROOT/'docs/dev-log/core070/pervar-docs-evidence.json').read_text())
    assert e['scope']=='EXECUTED_EXAMPLE_AND_STRICT_LOCAL_BUILD_NOT_DOCS_COMPLETE'
    for path,digest in e['artifacts'].items():assert sha(ROOT/path)==digest,path
    key='build' if build else 'example'
    p=ROOT/e['process'][key];r=json.loads(p.read_text())
    assert str(p.relative_to(ROOT)) in e['artifacts']
    assert r['status']=='PASS' and r['source_unchanged']
    assert r['supervisor_error'] is None
    assert sha(p.parent/'execution-plan.json')==r['plan_sha256']
    assert all(x['exit_code']==0 and x['supervisor_error'] is None for x in r['results'])
    for x in r['results']:assert sha(p.parent/x['log'])==x['log_sha256']
    for path,digest in r['source_pins'].items():
        if not build and not (path.startswith('src/') or path in ['Project.toml','Manifest.toml','tools/core070_pervar_example.jl','docs/src/response-families.md','test/test_aicbic_newfits.jl']):continue
        if path=='Manifest.toml':f=ROOT/'.unlazy/core070-aghq/pervar-docs/Manifest.toml'
        elif path.startswith('.docenv/'):f=ROOT/'.unlazy/core070-aghq/pervar-docs/setup'/path
        else:f=ROOT/path
        assert sha(f)==digest,path
    if build:
        assert r['results'][0]['argv'][-2:]==['docs/make.jl','--local']
        log=(p.parent/'00.log').read_text()
        assert 'building Vitepress site 1 of 1' in log and 'build complete in' in log
        assert 'encountered errors' not in log and '┌ Error:' not in log
        source=(ROOT/'docs/make.jl').read_text()
        assert 'warnonly = false' in source and 'if !("--local" in ARGS)' in source
        hashes=json.loads((ROOT/e['site_hashes']).read_text())
        assert len(hashes)==94
        site=ROOT/'.unlazy/core070-aghq/pervar-docs/site'
        for name,digest in hashes.items():assert sha(site/name)==digest,name
        for name in ['index.html','response-families.html','low-level-reference.html']:
            assert name in hashes
        assert '5-element Vector' in (site/'response-families.html').read_text()
        assert e['presentation_warnings_remaining'] and not e['deployed']
        print('PERVAR_STRICT_LOCAL_DOCS_VERIFIED')
    else:
        assert [x['id'] for x in r['results']]==['unit','adjacent']
        assert r['results'][0]['argv'][-1]=='tools/core070_pervar_example.jl'
        assert 'PERVAR_DOCUMENTED_EXAMPLE_PASS' in (p.parent/'00.log').read_text()
        assert '|   18     18' in (p.parent/'01.log').read_text()
        d=tomllib.loads((ROOT/e['example_result']).read_text())
        assert d==e['example_metrics'] and d['assertions']==6 and d['converged']
        page=ROOT/'docs/src/response-families.md';assert sha(page)==d['page_sha256']
        blocks=re.findall(r'```@example pervar_design\n(.*?)\n```',page.read_text(),re.S)
        assert len(blocks)==1 and hashlib.sha256(blocks[0].encode()).hexdigest()==d['code_sha256']
        assert len(d['coefficients'])==5 and d['nparams']==13
        print('PERVAR_DOCUMENTED_EXAMPLE_VERIFIED')
if __name__=='__main__':
    p=argparse.ArgumentParser();g=p.add_mutually_exclusive_group(required=True);g.add_argument('--example',action='store_true');g.add_argument('--build',action='store_true');verify(build=p.parse_args().build)
