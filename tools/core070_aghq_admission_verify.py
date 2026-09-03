"""Verify all declared admission receipts without hiding numerical failures."""
import argparse,hashlib,json,math,tarfile,tomllib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/aghq-admission-03'
CONTRACT='test/parity/core070_aghq_admission_cases.toml'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def need(value,message):
    if not value:raise ValueError(message)
def load(path):return json.loads(path.read_text())
def verify_attempt(state, current=True):
    """Historical receipts prove retained outcomes, never current-source parity."""
    plan=load(state/'plan.json');directory=state/'attempt1'
    process=load(directory/'process/process-receipt.json')
    need(process['status']=='PASS' and process['source_unchanged'] and not process['supervisor_error'],'failed or stale process')
    need(process['plan_sha256']==sha(state/'plan.json')==sha(directory/'process/execution-plan.json'),'stale execution plan')
    need(process['source_pins']==plan['pins'] and process['environment_overrides']==plan['env'],'unbound execution')
    need(plan['env']['JULIA_NUM_THREADS']==plan['env']['OPENBLAS_NUM_THREADS']==plan['env']['OMP_NUM_THREADS']=='1','thread contract mismatch')
    need(process['expected_ids']==[c['id'] for c in plan['commands']]==['oracle-before','admission','oracle-after'],'missing process stages')
    need(len(process['results'])==3,'missing process result')
    for result,command in zip(process['results'],plan['commands']):
        need(result['id']==command['id'] and result['argv']==command['argv'] and result['exit_code']==0 and not result['supervisor_error'],'nonzero or mismatched command')
        need(sha(directory/'process'/result['log'])==result['log_sha256'],'changed process log')
    required={str(p.relative_to(ROOT)) for p in ROOT.glob('src/**/*.jl')}|{CONTRACT,'Project.toml','test/parity/Project.toml','test/parity/Manifest.toml','tools/core070_aghq_admission_run.jl','tools/core070_targeted_run.py','tools/core070_build_oracle.py'}
    need(required<=set(plan['pins']),'missing dependency pins')
    with tarfile.open(state/'source.tar') as archive:
        members=archive.getmembers()
        need(len({m.name for m in members})==len(members),'duplicate archived source')
        need({m.name for m in members}==set(plan['pins'])|{'plan.json'},'archive dependency inventory differs')
        for name,pin in {**plan['pins'],'plan.json':sha(state/'plan.json')}.items():
            member=archive.getmember(name)
            need(member.isfile(),'nonregular archived source '+name)
            need(hashlib.sha256(archive.extractfile(member).read()).hexdigest()==pin,'archived source changed '+name)
    if current:
        for name,pin in plan['pins'].items():
            path=ROOT/name if name!='test/parity/Manifest.toml' else ROOT/'.unlazy/core070-aghq/aghq-public-poisson-env-01/attempt1/test/parity/Manifest.toml'
            need(sha(path)==pin,'source or runtime changed '+name)
    path=directory/'admission.toml';record=tomllib.loads(path.read_text())
    log=(directory/'process'/process['results'][1]['log']).read_text()
    need('ADMISSION_RECEIPT_SHA256 '+sha(path) in log,'receipt detached from process')
    spec=tomllib.loads((ROOT/CONTRACT).read_text())
    need(record['contract_sha256']==sha(ROOT/CONTRACT),'changed model contract')
    need(record['package_root']==plan['cwd'] and record['julia_version']=='1.12.6' and record['threads']==1,'wrong loaded source/runtime')
    ids=[x['id'] for x in spec['cases']]
    need([x['id'] for x in record['cases']]==ids and len(set(ids))==3,'missing/duplicate required case')
    expected_artifacts={'.fixtures.toml','.gaussian.rds','.poisson.rds','.binomial.rds','.unique.rds','.unique.toml'}
    need(set(record['artifacts'])==expected_artifacts,'missing model artifacts')
    for suffix,pin in record['artifacts'].items():need(sha(Path(str(path)+suffix))==pin,'changed fit artifact '+suffix)
    fixtures=tomllib.loads(Path(str(path)+'.fixtures.toml').read_text())['cases']
    need([f['id'] for f in fixtures]==ids,'missing realized fixture')
    for f,s in zip(fixtures,spec['cases']):
        need(f['seed']==s['seed'] and (f['p'],f['n'],f['K'])==(spec['p'],spec['n'],spec['K']),'fixture shape/seed changed')
        need(len(f['responses'])==len(f['trials'])==spec['p']*spec['n'] and all(t==spec['binomial_trials'] for t in f['trials']),'fixture trials changed')
        need(all(math.isfinite(x) for x in f['responses']),'invalid realized data')
    for r,s in zip(record['cases'],spec['cases']):
        need(r['family']==s['family'] and r['r_random']==['z_B'],'different family/random model')
        if current:
            need(r['r_design_matches'] and r['r_trials_preserved'],'R data design/trials differ')
            need(r['r_optimizer_policy']==('optim_BFGS_reltol1e-14_maxit2000' if r['family']=='gaussian' else 'reference_default'),'R optimization policy differs')
        need(r['r_fixed_columns']==(0 if r['family']=='gaussian' else spec['p']),'different fixed-effect design')
        need(r['native_objective_rebuild_delta']<=1e-6,'native gradient uses another objective')
        need(all(math.isfinite(x) for k in ['native_parameters','r_parameters'] for x in r[k]),'nonfinite fitted parameter')
        delta=abs(r['native_loglik']-r['r_loglik']);need(delta==r['delta_loglik'],'inconsistent likelihood delta')
        expected=[]
        for engine in ['native','r']:
            g=r[engine+'_gradient_max'];v=r[engine+'_loglik']
            need(g>=0,'invalid gradient norm')
            good=bool(r[engine+'_converged']) and math.isfinite(v) and math.isfinite(g) and (g<=spec['absolute_gradient_tolerance'] or g/max(1,abs(v))<=spec['relative_gradient_tolerance'])
            need(r[engine+'_health']==good,'inconsistent health flag');expected.append(good)
        numerical=all(expected) and delta<=spec['absolute_loglik_tolerance'] and delta/max(1,abs(r['r_loglik']))<=spec['relative_loglik_tolerance']
        need(r['numerical_pass']==numerical,'hidden numerical failure')
        no_warning='AGHQ' not in r['native_warnings']+r['formula_warnings'] and all('AGHQ' not in x for x in r['r_warnings'])
        need(r['no_ignored_warning']==no_warning,'hidden ignored-request warning')
        route=all(r[k] for k in ['native_route','r_route','native_exact_baseline','r_exact_baseline','no_ignored_warning']) and r['formula_actual']=='laplace'
        need(r['routing_pass']==route,'inconsistent routing flag')
    unique=tomllib.loads(Path(str(path)+'.unique.toml').read_text())
    need(not unique['r_used'] and unique['r_exact_baseline'] and set(unique['r_random'])=={'z_B','s_B'},'R default-unique fallback differs')
    need(any('AGHQ' in x and 'Laplace' in x for x in unique['r_warnings']) and 's_B' in unique['r_reason'],'R fallback missing warning/reason')
    need(unique['r_sigma_mapped'] and unique['r_sigma']>0,'R residual suppression missing')
    need(unique['native_status']=='BLOCKED_UNMATCHED_PARAMETER_CONTRACT','unmatched default-unique model promoted')
    return record

def verify_history(state=STATE):
    """Keep both unsuccessful qualifications and compare realized fixture bytes."""
    records=[]
    for i in range(1,4):
        directory=state.parent/f'aghq-admission-{i:02}'
        record=verify_attempt(directory,current=(i==3));records.append(record)
        need([r['numerical_pass'] for r in record['cases']]==([False,True,True] if i<3 else [True]*3),'historical outcome changed')
        need(all(r['routing_pass'] for r in record['cases']),'historical routing outcome changed')
    need(len({r['artifacts']['.fixtures.toml'] for r in records})==1,'realized fixtures changed between attempts')
    need(len({r['contract_sha256'] for r in records})==1,'acceptance/model contract changed between attempts')
    print('CORE070_AGHQ_ADMISSION_HISTORY_VERIFIED 3 attempts; unchanged fixtures; Gaussian failures retained')
    return records

def verify(require_pairs=False):
    history=verify_history(STATE);record=history[-1]
    summary=load(ROOT/'docs/dev-log/core070/aghq-admission-evidence.json')
    need(summary['status']=='VERIFIED_BOUNDED_PAIRS_FULL_MANIFEST_NOT_FROZEN','unearned manifest promotion')
    need(summary['verifier_sha256']==sha(Path(__file__)) and summary['runner_sha256']==sha(ROOT/'tools/core070_aghq_admission_run.jl'),'stale summary code pins')
    need(len(summary['attempts'])==3,'summary omits attempt')
    for i,(entry,retained) in enumerate(zip(summary['attempts'],history),1):
        state=STATE.parent/f'aghq-admission-{i:02}'
        need(entry['id']==state.name and entry['receipt_sha256']==sha(state/'attempt1/admission.toml'),'summary receipt differs')
        need(entry['source_archive_sha256']==sha(state/'source.tar') and entry['plan_sha256']==sha(state/'plan.json'),'summary archive differs')
        need(entry['elapsed_seconds']==load(state/'attempt1/process/process-receipt.json')['results'][1]['elapsed_seconds'],'summary duration differs')
        need(entry['fixture_sha256']==retained['artifacts']['.fixtures.toml'],'summary fixture differs')
        need(len(entry['cases'])==3,'summary case omitted')
        for compact,case in zip(entry['cases'],retained['cases']):
            need(all(case[k]==v for k,v in compact.items()) and compact['id']==case['id'],'summary numerical evidence differs')
    spec=tomllib.loads((ROOT/CONTRACT).read_text())
    need(summary['contract']==CONTRACT and summary['contract_sha256']==sha(ROOT/CONTRACT) and summary['reference_commit']==spec['reference_commit'],'summary model contract differs')
    need([b['id'] for b in summary['case_bindings']]==[s['id']+'-'+surface.upper() for s in spec['cases'] for surface in ['native','formula']],'summary surface omitted')
    for b in summary['case_bindings']:
        s=next(x for x in spec['cases'] if x['id']==b['model_contract_id'])
        need(b['julia_call']==s[b['interface']+'_call'] and b['r_formula']==s['r_formula'],'summary call differs')
        need(b['fixture']==CONTRACT and b['fixture_sha256']==sha(ROOT/CONTRACT) and b['realized_fixture_sha256']==record['artifacts']['.fixtures.toml'],'summary bound fixture differs')
        need(b['status']=='PASS_BOUNDED_K1_PAIR' and b['obligation_discharge'].startswith('PARTIAL:'),'summary promotes full obligation')
    print(json.dumps([dict(id=r['id'],routing=r['routing_pass'],numerical=r['numerical_pass'],delta_loglik=r['delta_loglik']) for r in record['cases']]))
    if require_pairs:
        need(all(r['routing_pass'] and r['numerical_pass'] for r in record['cases']),'required k1 routing/numerical pairs remain unmet')
        print('CORE070_AGHQ_K1_PAIRS_PASS')
    else:print('CORE070_AGHQ_ADMISSION_EVIDENCE_VERIFIED default-unique native and public R bridge remain unpaid')
    return record
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--require-pairs',action='store_true');args=p.parse_args();verify(args.require_pairs)
