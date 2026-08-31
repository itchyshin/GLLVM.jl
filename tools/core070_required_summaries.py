"""Derive the current scoped summaries from preserved receipts without changing history."""
import json,tomllib
from pathlib import Path
from core070_verify_poisson_beta_required import ROOT,sha
PREFIX=Path('docs/dev-log/core070')
BASE=Path('.unlazy/core070-aghq')
def read(p):return json.loads((ROOT/p).read_text())
def toml(p):return tomllib.loads((ROOT/p).read_text())
def files(state):
    root=ROOT/BASE/state
    paths=[root/'plan.json',root/'source.tar']
    paths += [p for sub in ['attempt1','r'] for p in (root/sub).rglob('*') if p.is_file()]
    return {str(p.relative_to(ROOT)):sha(p) for p in sorted(paths)}
def build():
    output={}
    transforms=[('nb2-formula-required-link-refresh.json','nb2-formula-required-pb-refresh.json','nb2-formula-required-04'),
        ('family-boundary-link-refresh.json','family-boundary-pb-refresh.json','family-boundaries-04'),
        ('family-link-boundary-evidence.json','family-link-boundary-pb-refresh.json','link-boundaries-green-03')]
    for old,new,state in transforms:
        d=read(PREFIX/old);s=BASE/state;p=read(s/'attempt1/process/process-receipt.json');plan=read(s/'plan.json')
        d['files']=files(state)
        d['supersedes_for_current_source']=old
        d['refresh_reason']='Required Poisson/Beta wrappers and shared harness inventory changed; original fitted models, controls and boundary contracts unchanged.'
        if state.startswith('nb2'):
            run=toml(s/'attempt1/receipts/run.toml')
            for key in ['source','contract_sha256']:d[key]=run[key]
            d['execution_manifest_sha256']=run['execution']['manifest_sha256']
            d['elapsed_seconds']=p['results'][1]['elapsed_seconds']
        else:
            d['source_pins']=plan['pins']
            d['julia_elapsed_seconds' if state.startswith('family') else 'elapsed_seconds']=p['results'][1]['elapsed_seconds']
        if state.startswith('link'):
            d['files'].update(files('ordinal-link-parity-02'))
            d['ordinal_diagnostic']['elapsed_seconds']=read(BASE/'ordinal-link-parity-02/attempt1/process/process-receipt.json')['results'][1]['elapsed_seconds']
        output[str(PREFIX/new)]=d
    state='poisson-beta-required-01';s=BASE/state
    run=toml(s/'attempt1/receipts/run.toml');contract=read(PREFIX/'poisson-beta-required-contract.json')
    d=dict(status='ORIGINAL_POISSON_BETA_REQUIRED_CASES_VERIFIED_NOT_FULL_PARITY',
        reference_commit=contract['reference_commit'],source=run['source'],case_ids=run['completed_case_ids'],
        assertions_total=run['actual_assertions'],independent_executions=2,
        elapsed_seconds=read(s/'attempt1/process/process-receipt.json')['results'][1]['elapsed_seconds'],
        execution_manifest_sha256=run['execution']['manifest_sha256'],contract_sha256=run['contract_sha256'],
        model_contract_sha256=sha(ROOT/PREFIX/'poisson-beta-required-contract.json'),
        controls=contract['controls'],scope=contract['scope'],full_manifest_status='DRAFT_INCOMPLETE_NOT_FROZEN',
        independent_review='Prior qualified body reviewed by Noether; identical body verified during integration; no full completion panel',
        cases=contract['cases'],health={f:toml(s/'attempt1/receipts'/f'{f}-health.toml') for f in ['poisson','beta']},files=files(state))
    output[str(PREFIX/'poisson-beta-required-evidence.json')]=d
    return output

def verify():
    for path,expected in build().items():assert read(path)==expected,path
    print('CORE070_REQUIRED_SUMMARIES_VERIFIED 4 current scoped summaries')
if __name__=='__main__':verify()
