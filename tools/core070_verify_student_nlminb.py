"""Verify the unchanged original Student model under one public nlminb continuation."""
import argparse, copy, hashlib, json, subprocess, tarfile, tomllib
from pathlib import Path
from core070_verify_student_warmstart import checks, retained_attempt

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'.unlazy/core070-aghq'
STATE=BASE/'student-nlminb-warmstart-02'
MANIFEST=BASE/'aghq-public-poisson-env-01/attempt1/test/parity/Manifest.toml'
TOOL='tools/core070_student_nlminb_warmstart.jl'
REFERENCE='b4d5fee64def88bc768dda1f1f77c29b295edd86'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def archive_check(state):
    plan=json.loads((state/'plan.json').read_text())
    process=json.loads((state/'attempt1/process/process-receipt.json').read_text())
    assert process['plan_sha256']==sha(state/'plan.json')
    assert process['source_pins']==plan['pins'] and process['source_unchanged']
    assert process['environment_overrides']==plan['env'] and process['supervisor_error'] is None
    assert [r['id'] for r in process['results']]==['oracle-before','student-warmstart','oracle-after']
    for row,command in zip(process['results'],plan['commands']):
        assert row['argv']==command['argv'] and row['supervisor_error'] is None
        assert sha(state/'attempt1/process'/row['log'])==row['log_sha256']
    with tarfile.open(state/'source.tar') as archive:
        names=[]
        for member in archive.getmembers():
            if member.isfile():
                name=member.name.removeprefix('./');names.append(name)
                pin=sha(state/'plan.json') if name=='plan.json' else plan['pins'][name]
                assert hashlib.sha256(archive.extractfile(member).read()).hexdigest()==pin,name
        assert len(names)==len(set(names)) and set(names)==set(plan['pins'])|{'plan.json'}
    assert process['results'][0]['exit_code']==process['results'][2]['exit_code']==0
    return plan,process

def whole_fit_readback(record,state):
    output=subprocess.check_output(['Rscript','--vanilla',str(ROOT/'tools/core070_student_warmstart_readback.R'),
        str(state/'attempt1/diagnostic/whole-fits.rds')],text=True,timeout=30)
    lines=output.splitlines();assert lines.pop()=='R_WHOLE_FIT_READBACK_PASS'
    expected=[]
    for kind in ['original','warm','final']:
        for field in ['loglik','objective','code','gradient','parameters','df','sigma']:
            value=record[kind][field];values=value if isinstance(value,list) else [value]
            expected.extend((kind,field,i+1,float(v)) for i,v in enumerate(values))
    actual=[]
    for line in lines:
        kind,field,i,value=line.split('\t');actual.append((kind,field,int(i),float(value)))
    assert actual==expected,'serialized full fits differ from report'

def negatives(record):
    changes=[('reported_'+key,lambda r,k=key:r['checks'].__setitem__(k,not r['checks'][k]))
             for key in record['checks'] if key!='same_data_map']
    changes.extend([
      ('missing_check',lambda r:r['checks'].pop('likelihood')),
      ('gradient_max',lambda r:r['final'].__setitem__('gradient_max',-1)),
      ('likelihood_delta',lambda r:r.__setitem__('loglik_delta',1234)),
      ('density_delta',lambda r:r.__setitem__('samepoint_delta',1234)),
      ('missing_parameter',lambda r:r['final']['parameters'].pop())])
    for name,change in changes:
        bad=copy.deepcopy(record);change(bad)
        try:checks(bad)
        except (AssertionError,KeyError):continue
        raise AssertionError('Accepted damaged report: '+name)
    return len(changes)

def verify(require_health=False):
    plan,process=archive_check(STATE)
    assert plan['commands'][1]['argv'][-3:]==[TOOL,'retained.toml','diagnostic']
    assert plan['timeout_seconds']==300 and plan['commands'][1]['timeout_seconds']==240
    for key in ['JULIA_NUM_THREADS','OPENBLAS_NUM_THREADS']:assert plan['env'][key]=='1'
    for name,pin in plan['pins'].items():
        path=ROOT/name
        if name=='retained.toml':path=BASE/'student-refinement/attempt2/refinement/result.toml'
        if name=='test/parity/Manifest.toml':path=MANIFEST
        assert sha(path)==pin,name
    record=tomllib.loads((STATE/'attempt1/diagnostic/result.toml').read_text())
    assert record['scope']=='ORIGINAL_STUDENT_PUBLIC_FIXED_TO_FREE_NLMINB'
    assert record['source']['reference_commit']==REFERENCE
    assert record['fixture_sha256']==sha(ROOT/'test/parity/test_studentt_parity.jl')
    assert record['data_sha256']=='2c8ac438e655b3ec39209799676f689c8a875ba300ec0df032c76ee506a94365'
    whole_fit_readback(record,STATE)
    verdict=checks(record);assert len(verdict)==13
    failed=sorted(k for k,v in verdict.items() if not v);healthy=not failed
    assert process['status']==('PASS' if healthy else 'FAIL')
    assert [r['exit_code'] for r in process['results']]==[0,0 if healthy else 1,0]
    n=negatives(record)
    # Preserve the preceding numerical failure against its historical snapshot.
    historical=BASE/'student-warmstart-02';retained_attempt(historical)
    old=tomllib.loads((historical/'attempt1/diagnostic/result.toml').read_text())
    whole_fit_readback(old,historical)
    assert sorted(k for k,v in checks(old).items() if not v)==['r_gradient','samepoint_density_accuracy']
    _,setup=archive_check(BASE/'student-nlminb-warmstart-01')
    assert setup['status']=='FAIL' and setup['results'][1]['exit_code']==1
    assert 'does not have SHA in its dependencies' in (BASE/'student-nlminb-warmstart-01/attempt1/process/01.log').read_text()
    result=dict(status='ORIGINAL_STUDENT_NLMINB_HEALTH_PASS' if healthy else 'ORIGINAL_STUDENT_NLMINB_FAILED_RESULT_VERIFIED',
      reference_commit=REFERENCE,failed_checks=failed,checks=verdict,negative_controls=n,
      loglik_delta=record['loglik_delta'],r_gradient_max=record['final']['gradient_max'],
      native_gradient_max=max(map(abs,record['native_gradient'])),samepoint_density_delta=record['samepoint_delta'],
      r_df=record['final']['df'],elapsed_seconds=process['results'][1]['elapsed_seconds'],
      process_sha256=sha(STATE/'attempt1/process/process-receipt.json'),result_sha256=sha(STATE/'attempt1/diagnostic/result.toml'),
      tools={p:sha(ROOT/p) for p in [TOOL,'tools/core070_verify_student_nlminb.py','tools/core070_verify_student_warmstart.py','tools/core070_student_warmstart_readback.R']},
      scope='ORIGINAL_REQUIRED_FIXTURE_ONLY_NOT_FULL_STUDENT_FAMILY',independent_review='NOT_RUN')
    if require_health:assert healthy,'Original Student health gate remains unpaid: '+','.join(failed)
    print(result['status'],json.dumps(failed),'negative_controls',n)
    return result

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--require-health',action='store_true')
    parser.add_argument('--output',type=Path)
    args=parser.parse_args();result=verify(args.require_health)
    if args.output:
        with args.output.open('x') as f:json.dump(result,f,indent=2);f.write('\n')
