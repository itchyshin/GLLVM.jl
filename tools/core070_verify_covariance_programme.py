"""Verify the nine-case native subset without fabricating a frozen programme."""
import copy, json, math, os, subprocess, sys, tomllib
from pathlib import Path
import core070_evidence as e
import core070_covariance_programme as c
from core070_manifest_coverage import need
from core070_verify_covariance_fits import record_ok, negative_controls as mode_negatives, flat
from core070_verify_source_fixed import check_pair
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/covariance-programme-02'
MANIFEST=ROOT/'.unlazy/core070-aghq/aghq-public-poisson-env-01/attempt1/test/parity/Manifest.toml'
sha=e.digest

def check_run(run,cells,cases,execution):
    need(run['status']=='success' and run['exit_code']==0 and run['success_marker']=='CORE070_PARITY_SUCCESS','failed run')
    need(run['requested_case_ids']==c.IDS and run['completed_case_ids']==sorted(c.IDS),'missing or changed case')
    need(run['scope']=='subset' and run['selected_family_count']==0,'false scope')
    need(run['execution']==execution,'stale execution')
    pin=sha(e.DEFAULT_MANIFEST)
    need(run['contract_sha256']==pin,'stale contract')
    need(set(cells)==set(c.IDS) and run['cells']==cells,'omitted or mismatched cell')
    need(run['assertion_counting']=='execution_groups_v1','missing grouped accounting')
    for cid,cell in cells.items():
        group=c.FIXED if cid in c.FIXED else c.MODES
        need(cell['id']==cid and cell['run_id']==run['run_id'] and cell['status']=='success','transplanted or failed cell')
        need(cell['fixture']==cases[cid]['fixture'] and cell['fixture_sha256']==cases[cid]['fixture_sha256']==sha(ROOT/cell['fixture']),'fixture changed')
        need(cell['execution_case_ids']==sorted(group),'partial execution group')
        need(cell['assertions']==dict(passed=27 if cid in c.FIXED else 176,failed=0,errored=0,broken=0),'assertion failure or drift')
        need(cell['contract_sha256']==pin and cell['execution_manifest_sha256']==execution['manifest_sha256'],'stale cell')
    need(e.execution_assertion_counts(cells)==dict(passed=203,failed=0,errored=0,broken=0) and run['actual_assertions']==203,'inflated or incomplete total')

def readback(script,folder,marker):
    lines=subprocess.check_output(['Rscript','--vanilla',str(ROOT/script),str(folder)],text=True,timeout=30).splitlines()
    need(lines.pop()==marker,'raw R readback failed')
    return [line.split('\t') for line in lines]

def validate_payloads(folder,plan):
    """Independently verify native/R values reused by dependent interfaces."""
    modes=e.load_toml(folder/'covariance-modes-raw/result.toml');fixed=e.load_toml(folder/'covariance-fixed-raw/result.toml')
    need(modes['source']['reference_commit']==fixed['source']['reference_commit']==c.REFERENCE,'reference drift')
    need(modes['case_ids']==[r['id'] for r in modes['cases']]==c.MODES and modes['all_checks'] and not modes['failures'],'missing/failed mode')
    need([r['id'] for r in fixed['cases']]==c.FIXED,'missing fixed model')
    need(modes['control_policy']=='tight-control','control drift')
    need(modes['fixture_sha256']==sha(ROOT/'test/parity/fixtures/core070_covariance_fits.R') and modes['runner_sha256']==sha(ROOT/'tools/core070_covariance_mode_fits.jl'),'mode dependency drift')
    need(fixed['fixture_sha256']==sha(ROOT/'test/parity/fixtures/core070_covariance_modes.R'),'fixed fixture drift')
    for row in modes['cases']:record_ok(row);need(row['checks']['baseline_data_map_unchanged'],'baseline data/map changed')
    for row in fixed['cases']:check_pair(row)
    original=e.load_toml(ROOT/'.unlazy/core070-aghq/covariance-fits-01/attempt1/covariance-fits/result.toml')
    need([r['Y'] for r in original['cases']]==[r['Y'] for r in modes['cases']],'original fixture replaced')
    for ident in c.MODES:
        raw=ROOT/'.unlazy/core070-aghq/covariance-fits-01/attempt1/covariance-fits'/f'{ident}.rds'
        need(plan['pins'].get('baseline/'+raw.name)==sha(raw),'baseline unbound')
    byid={r['id']:r for r in modes['cases']};expected={}
    for row in modes['cases']:
        for field in ['loglik','objective','code','gradient','outer','beta','covariance','residual_sd','hessian_min']:
            for i,value in enumerate(flat(row['r'][field]),1):expected[row['id'],field,i]=float(value)
        for i,value in enumerate(flat(row['Y']),1):expected[row['id'],'Y',i]=float(value)
    for ident,field,i,value in readback('tools/core070_covariance_fits_readback.R',folder/'covariance-modes-raw','COVARIANCE_FITS_R_READBACK_PASS'):
        value=float(value)
        if field=='dense_objective':need(abs(value-byid[ident]['r']['objective'])<=1e-6,'normalization mismatch')
        else:
            old=expected.pop((ident,field,int(i)));need((math.isnan(old) and math.isnan(value)) or old==value,'raw/report mismatch')
    need(not expected,'omitted raw fields')
    actual=[(ident,field,int(i),float(value)) for ident,field,i,value in readback('tools/core070_source_fixed_readback.R',folder/'covariance-fixed-raw','FIXED_SOURCE_R_READBACK_PASS')]
    expected=[(row['id'],field,i,float(value)) for row in fixed['cases'] for field in ['r_loglik','r_objective','r_code','r_gradient','r_parameters','r_beta','r_source_sd','sigma_eps_fixed'] for i,value in enumerate(flat(row[field]),1)]
    need(actual==expected,'fixed raw/report mismatch')
    return modes,fixed

def verify():
    folder=STATE/'attempt1/receipts';run,cells=e._load_receipts(folder)
    manifest=e.load_manifest(e.DEFAULT_MANIFEST);c.validate_registry(manifest)
    need(manifest['status']=='DRAFT_INCOMPLETE_NOT_FROZEN','unearned programme promotion')
    cases={r['id']:r for r in manifest['executable_case']}
    execution=e.execution_inventory(cases,c.IDS,e.DEFAULT_MANIFEST)
    need(not any(r['path']=='test/parity/Manifest.toml' for r in execution['entries']),'unexpected local parity manifest')
    entries=execution['entries']+[dict(path='test/parity/Manifest.toml',sha256=sha(MANIFEST))]
    entries.sort(key=lambda r:r['path']);execution=dict(entries=entries,manifest_sha256=e._hash_inventory(entries))
    check_run(run,cells,cases,execution);e._validate_source(run['source'],manifest,execution,folder)
    need(run['source']['julia_threads']==run['source']['blas_threads']==1,'thread budget drift')
    path=STATE/'attempt1/process/process-receipt.json'
    e.verify_process(folder,path,execution)
    process=json.loads(path.read_text());plan=json.loads((STATE/'plan.json').read_text())
    need(process['plan_sha256']==sha(STATE/'plan.json') and process['environment_overrides']==plan['env'],'plan/environment drift')
    need(plan['env']['CORE070_PARITY_CASE_IDS']==','.join(c.IDS) and plan['env']['CORE070_PARITY_REQUIRED']==plan['env']['GLLVM_PARITY_TESTS']=='1','wrong or optional run')
    need([r['id'] for r in process['results']]==['oracle-before','registry','pair','oracle-after'],'missing process checks')
    need(plan['commands'][2]['argv'][-1]=='test/parity/runparity.jl','wrong entrypoint')
    modes,fixed=validate_payloads(folder,plan)
    controls=sum(mode_negatives(row) for row in modes['cases'])
    for mutation in ['omit','exit','stale','missing_receipt','group','count']:
        r,b=copy.deepcopy(run),copy.deepcopy(cells)
        if mutation=='omit':r['completed_case_ids'].pop()
        elif mutation=='exit':r['exit_code']=1
        elif mutation=='stale':r['contract_sha256']='stale'
        elif mutation=='missing_receipt':b.pop(c.IDS[0])
        elif mutation=='group':b[c.IDS[0]]['execution_case_ids']=[c.IDS[0]]
        else:r['actual_assertions']=27*2+176*7
        try:check_run(r,b,cases,execution)
        except (ValueError,RuntimeError,KeyError,AssertionError):controls+=1;continue
        raise AssertionError('damaged run accepted: '+mutation)
    missing=subprocess.run([sys.executable,str(Path(__file__).resolve())],env=dict(os.environ,PATH='/nonexistent-core070-dependency'),capture_output=True,text=True,timeout=30)
    need(missing.returncode!=0 and 'FileNotFoundError' in missing.stderr and 'Rscript' in missing.stderr,'missing dependency was accepted')
    controls+=1
    print('CORE070_COVARIANCE_PROGRAMME_VERIFIED',json.dumps(dict(status='NINE_NATIVE_CASE_SUBSET_PASS_NOT_PROGRAMME',case_count=9,assertions=203,negative_controls=controls,process_sha256=sha(path),elapsed_seconds=process['results'][2]['elapsed_seconds'],max_absolute_delta_loglik=max([abs(r['native']['loglik']-r['r']['loglik']) for r in modes['cases']]+[abs(r['native_loglik']-r['r_loglik']) for r in fixed['cases']]))))
if __name__=='__main__':verify()
