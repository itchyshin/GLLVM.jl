#!/usr/bin/env python3
"""Frozen-R descriptor replay and Julia entry probes; deliberately no model fits."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time

import core070_family_admission as reference
from core070_student_input import JULIA, ENVIRONMENT, sha

ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/family-routes-01'
CONTRACT=ROOT/'docs/dev-log/core070/family-route-contract.json'
ADMISSION=ROOT/'docs/dev-log/core070/family-admission-subset.json'


def validate(contract):
    source=json.loads(ADMISSION.read_text())
    assert contract['reference_commit']==source['reference_commit']
    assert contract['status']=='FAMILY_ENTRY_CONTRACT_NOT_FULL_CAPABILITY_MANIFEST'
    rows=contract['rows']
    assert len(rows)==contract['expected_source_facts']==69
    assert [r['source_id'] for r in rows]==['family/'+c['id'] for c in source['cases']]
    for row,case in zip(rows,source['cases']):
        assert row['classification']==case['classification']
        assert row['reference_descriptor_call']==case['reference_descriptor_call']
        assert row['reference_expected']==case['expected']
        assert row['fitted_acceptance']=='UNPAID_NOT_PROVEN_BY_ENTRY_PROBE'
        assert row['formula_status']==row['bridge_status']=='UNPAID'
        required=case['classification'] in ('required_core','compatibility_adapter')
        assert (row['native_probe'] is not None)==required
        if required:
            assert row['native_probe']['id']=='ENTRY-'+case['id']
            assert row['native_probe']['expect']=='RESPONSE_READ_SENTINEL'
            assert (ROOT/row['existing_model_fixture']).is_file()
    assert sum(r['native_probe'] is not None for r in rows)==contract['expected_native_entry_probes']==22
    expected={'docs/dev-log/core070/family-admission-subset.json',
              'docs/dev-log/core070/family-model-catalogue.json'}
    expected.update(str(p.relative_to(ROOT)) for p in (ROOT/'src').rglob('*.jl'))
    assert set(contract['sources'])==expected
    for name,pin in contract['sources'].items():assert sha(ROOT/name)==pin,name


def run():
    contract=json.loads(CONTRACT.read_text()); validate(contract)
    destination=STATE/'execution2'; destination.mkdir(exist_ok=False)
    shutil.copy2(CONTRACT,destination/'contract-snapshot.json')
    shutil.copy2(__file__,destination/'runner-snapshot.py')
    reference_code=reference.run(ADMISSION,ROOT/'.unlazy/core070-aghq/oracle-source/readback',destination/'r')
    assert reference_code==0,'frozen R descriptor replay failed'
    package=destination/'julia'; package.mkdir()
    shutil.copytree(ROOT/'src',package/'src')
    shutil.copy2(ROOT/'Project.toml',package/'Project.toml')
    shutil.copy2(ENVIRONMENT/'Manifest.toml',package/'Manifest.toml')
    script='''using GLLVM, Test
@assert realpath(pathof(GLLVM)) == realpath(joinpath(@__DIR__,"src/GLLVM.jl"))
println("JULIA_VERSION ",VERSION)
struct FamilyResponseRead <: Exception end
struct FamilyMatrix <: AbstractMatrix{Int} end
Base.size(::FamilyMatrix)=(3,5)
Base.getindex(::FamilyMatrix,::Int,::Int)=throw(FamilyResponseRead())
struct FamilyLabels <: AbstractVector{Int} end
Base.size(::FamilyLabels)=(5,)
Base.getindex(::FamilyLabels,::Int)=throw(FamilyResponseRead())
Y=FamilyMatrix(); labels=FamilyLabels(); N=fill(5,3,5)
@testset "Frozen family Julia entry points" begin
'''
    for row in contract['rows']:
        probe=row['native_probe']
        if probe is None:continue
        script+='''observed=try
  '''+probe['call']+'''
  "UNEXPECTED_RETURN"
catch error
  error isa FamilyResponseRead ? "RESPONSE_READ_SENTINEL" : string(typeof(error),": ",sprint(showerror,error))
end
'''
        script+='println('+json.dumps(probe['id'])+', "\\t", observed)\n'
        script+='@test observed == "RESPONSE_READ_SENTINEL"\n'
    script+='end\nprintln("FAMILY_ENTRY_PROBES_PASS")\n'
    (package/'run.jl').write_text(script)
    env=dict(os.environ,JULIA_DEPOT_PATH=str(ENVIRONMENT/'depot')+':/Users/z3437171/.julia',
             JULIA_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',JULIA_PKG_OFFLINE='true',JULIA_PKG_PRECOMPILE_AUTO='0')
    argv=[str(JULIA),'--startup-file=no','--project=.','run.jl']
    start=time.monotonic(); timed_out=False
    with (package/'output.log').open('wb') as log:
        try:
            result=subprocess.run(argv,cwd=package,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=60)
            code=result.returncode
        except subprocess.TimeoutExpired:timed_out=True;code=None
    record=dict(scope='ENTRY_ONLY_NO_FITS',exit_code=code,timeout=timed_out,
        elapsed_seconds=time.monotonic()-start,contract_sha256=sha(CONTRACT),
        argv=argv,cwd=str(package),runtime_sha256=sha(JULIA),
        project_sha256=sha(package/'Project.toml'),manifest_sha256=sha(package/'Manifest.toml'),
        source_unchanged=all(sha(ROOT/p)==pin for p,pin in contract['sources'].items()),
        log_sha256=sha(package/'output.log'),script_sha256=sha(package/'run.jl'))
    (destination/'receipt.json').write_text(json.dumps(record,indent=2)+'\n')
    print((package/'output.log').read_text());print(json.dumps(record))
    return code if code is not None else 1


def verify():
    contract=json.loads(CONTRACT.read_text()); validate(contract)
    destination=STATE/'execution2'; package=destination/'julia'
    record=json.loads((destination/'receipt.json').read_text())
    assert record['exit_code']==0 and not record['timeout'] and record['source_unchanged']
    assert record['contract_sha256']==sha(CONTRACT)
    assert sha(destination/'contract-snapshot.json')==sha(CONTRACT)
    assert record['runtime_sha256']==sha(JULIA)
    for field,file in [('project','Project.toml'),('manifest','Manifest.toml'),('script','run.jl'),('log','output.log')]:
        assert sha(package/file)==record[field+'_sha256']
    for name,pin in contract['sources'].items():
        if name.startswith('src/'):assert sha(package/name)==pin
    text=(package/'output.log').read_text()
    actual=[line for line in text.splitlines() if line.startswith('ENTRY-')]
    expected=[r['native_probe']['id']+'\tRESPONSE_READ_SENTINEL' for r in contract['rows'] if r['native_probe']]
    assert actual==expected
    assert re.search(r'Frozen family Julia entry points\s*\|\s*22\s+22\s+',text)
    receipt=json.loads((destination/'r/receipt.json').read_text())
    assert receipt['status']=='PASS' and receipt['actual_exit']==0 and receipt['source_unchanged']
    assert receipt['manifest_sha256']==sha(ADMISSION)
    for field,file in [('script','replay.R'),('raw','raw.tsv'),('diagnostics','diagnostics.log')]:
        assert sha(destination/'r'/file)==receipt[field+'_sha256']
    cases=json.loads(ADMISSION.read_text())['cases']
    assert receipt['expected_case_ids']==[c['id'] for c in cases]
    raw=(destination/'r/raw.tsv').read_text().splitlines()
    assert raw==[c['id']+'\t'+(','.join(map(str,c['expected'])) if isinstance(c['expected'],list) else c['expected'])+'\tPASS' for c in cases]
    for name,pin in receipt['source_pins'].items():
        assert sha(ROOT/'.unlazy/core070-aghq/oracle-source/readback'/name)==pin
    first=STATE/'execution'
    original=json.loads((first/'receipt.json').read_text())
    assert original['exit_code']==1 and not original['timeout']
    assert sha(first/'contract-snapshot.json')==original['contract_sha256']==contract['supersedes_sha256']
    assert sha(first/'julia/output.log')==original['log_sha256']
    assert sha(first/'julia/run.jl')==original['script_sha256']
    first_text=(first/'julia/output.log').read_text()
    assert re.search(r'Frozen family Julia entry points\s*\|\s*21\s+1\s+22\s+',first_text)
    assert 'CloglogLink' in first_text and 'UndefVarError' in first_text


def negatives():
    contract=json.loads(CONTRACT.read_text()); count=0
    for change in ('omitted','duplicate','reference','promotion','scope','native-omitted'):
        copy=json.loads(json.dumps(contract))
        if change=='omitted':copy['rows'].pop()
        elif change=='duplicate':copy['rows'][1]=copy['rows'][0]
        elif change=='reference':copy['reference_commit']='stale'
        elif change=='promotion':copy['rows'][0]['fitted_acceptance']='PASS'
        elif change=='scope':copy['rows'][0]['classification']='intentionally_excluded'
        else:copy['rows'][0]['native_probe']=None
        try:validate(copy)
        except AssertionError:count+=1
        else:raise AssertionError('invalid contract accepted: '+change)
    assert count==6
    print('FAMILY_ROUTE_NEGATIVE_CONTROLS 6 PASS')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run',action='store_true');parser.add_argument('--verify',action='store_true')
    args=parser.parse_args()
    if args.run:raise SystemExit(run())
    if not args.verify:parser.error('use --run or --verify')
    verify();negatives()
    print('FAMILY_ROUTE_CONTRACT_VERIFIED_NOT_FITTED_PARITY')
