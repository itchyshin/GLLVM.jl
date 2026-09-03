"""Whole-fit qualification of the original Student public warm-start attempt."""
import argparse,copy,hashlib,json,math,subprocess,tarfile
from pathlib import Path
import tomllib

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'.unlazy/core070-aghq'
STATE=BASE/'student-warmstart-02'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def checks(record):
    f,w=record['final'],record['warm']
    finite=lambda x:all(math.isfinite(v) for v in x)
    names=[s for s in ['b_fix','theta_rr_B','log_sigma_student','log_df_student'] for _ in range(5)]
    assert len(f['parameters'])==len(f['gradient'])==len(f['names'])==20
    assert len(record['native_gradient'])==len(record['native_parameters'])==20
    assert len(w['df'])==len(f['df'])==len(f['sigma'])==5
    assert math.isclose(max(map(abs,f['gradient'])),f['gradient_max'],abs_tol=1e-12)
    calculated={
      'same_data_map':record['checks']['same_data_map'],
      'twenty_free_parameters':f['names']==names,
      'fixed_warm_df':all(math.isclose(a,b,rel_tol=1e-12) for a,b in zip(w['df'],[100000,5,4,4,10])),
      'r_code':f['code']==0,'r_gradient':max(map(abs,f['gradient']))<=1e-4,
      'native_converged':record['native_converged'],
      'native_gradient':max(map(abs,record['native_gradient']))<=1e-4,
      'finite_parameters':finite(f['parameters']) and finite(record['native_parameters']),
      'df_domain':finite(f['df']) and min(f['df'])>1,
      'scale_domain':finite(f['sigma']) and min(f['sigma'])>0,
      'likelihood':math.isfinite(f['loglik']) and math.isfinite(record['native_loglik']) and abs(record['native_loglik']-f['loglik'])<=0.001,
      'reported_objective':abs(f['loglik']+f['objective'])<=1e-8,
      'samepoint_density_accuracy':math.isfinite(record['samepoint_native_nll']) and abs(record['samepoint_native_nll']-f['objective'])<=1e-6}
    assert calculated==record['checks'],'reported checks do not match numerical fields'
    assert math.isclose(record['loglik_delta'],record['native_loglik']-f['loglik'],abs_tol=1e-12)
    assert math.isclose(record['samepoint_delta'],record['samepoint_native_nll']-f['objective'],abs_tol=1e-12)
    return calculated

def retained_attempt(state):
    plan=json.loads((state/'plan.json').read_text())
    process=json.loads((state/'attempt1/process/process-receipt.json').read_text())
    assert process['plan_sha256']==sha(state/'plan.json')
    assert process['source_pins']==plan['pins'] and process['source_unchanged']
    assert process['environment_overrides']==plan['env'] and process['supervisor_error'] is None
    assert [r['id'] for r in process['results']]==['oracle-before','student-warmstart','oracle-after']
    assert process['status']=='FAIL'
    assert [r['exit_code'] for r in process['results']]==[0,1,0]
    for row,command in zip(process['results'],plan['commands']):
        assert row['argv']==command['argv'] and row['supervisor_error'] is None
        assert sha(state/'attempt1/process'/row['log'])==row['log_sha256']
    with tarfile.open(state/'source.tar') as archive:
        for member in archive.getmembers():
            if member.isfile():
                name=member.name.removeprefix('./')
                pin=sha(state/'plan.json') if name=='plan.json' else plan['pins'][name]
                assert hashlib.sha256(archive.extractfile(member).read()).hexdigest()==pin,name
    return process

def negative_controls(r):
    changes=[('false_green',lambda x:x['checks'].update(r_gradient=True)),
      ('missing_case',lambda x:x['checks'].pop('likelihood')),
      ('wrong_gradient_max',lambda x:x['final'].update(gradient_max=0)),
      ('wrong_likelihood_delta',lambda x:x.update(loglik_delta=0)),
      ('wrong_density_delta',lambda x:x.update(samepoint_delta=0)),
      ('omitted_coordinate',lambda x:x['final']['parameters'].pop()),
      ('altered_warm_df',lambda x:x['warm']['df'].__setitem__(0,1000)),
      ('altered_optimizer_code',lambda x:x['final'].update(code=1))]
    for name,change in changes:
        damaged=copy.deepcopy(r);change(damaged)
        try: checks(damaged)
        except (AssertionError,KeyError): continue
        raise AssertionError('Failed to reject '+name)
    print('WARMSTART_NEGATIVE_CONTROLS_PASS',len(changes))

def verify(readback_only=False):
    plan=json.loads((STATE/'plan.json').read_text())
    process=json.loads((STATE/'attempt1/process/process-receipt.json').read_text())
    assert process['plan_sha256']==sha(STATE/'plan.json')
    assert process['source_pins']==plan['pins'] and process['source_unchanged']
    assert process['environment_overrides']==plan['env'] and process['supervisor_error'] is None
    assert [r['id'] for r in process['results']]==['oracle-before','student-warmstart','oracle-after']
    for row,command in zip(process['results'],plan['commands']):
        assert row['argv']==command['argv'] and row['supervisor_error'] is None
        assert sha(STATE/'attempt1/process'/row['log'])==row['log_sha256']
    for name,pin in plan['pins'].items():
        path=ROOT/name
        if name=='retained.toml':path=BASE/'student-refinement/attempt2/refinement/result.toml'
        if name=='test/parity/Manifest.toml':path=BASE/'binomial-refresh-01/Manifest.toml'
        assert sha(path)==pin,name
    r=tomllib.loads((STATE/'attempt1/diagnostic/result.toml').read_text())
    readback=subprocess.check_output(['Rscript','--vanilla',str(ROOT/'tools/core070_student_warmstart_readback.R'),
          str(STATE/'attempt1/diagnostic/whole-fits.rds')],text=True,timeout=30)
    lines=readback.splitlines();assert lines[-1]=='R_WHOLE_FIT_READBACK_PASS'
    expected=[]
    for kind in ['original','warm','final']:
        for field in ['loglik','objective','code','gradient','parameters','df','sigma']:
            value=r[kind][field];values=value if isinstance(value,list) else [value]
            expected.extend((kind,field,i+1,float(v)) for i,v in enumerate(values))
    actual=[]
    for line in lines[:-1]:
        kind,field,i,value=line.split('\t');actual.append((kind,field,int(i),float(value)))
    assert actual==expected,'serialized whole fits differ from report'
    assert r['scope']=='ORIGINAL_STUDENT_PUBLIC_FIXED_TO_FREE_WARMSTART'
    assert r['source']['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert r['fixture_sha256']==sha(ROOT/'test/parity/test_studentt_parity.jl')
    assert r['data_sha256']=='2c8ac438e655b3ec39209799676f689c8a875ba300ec0df032c76ee506a94365'
    verdict=checks(r)
    negative_controls(r)
    retained_attempt(STATE)
    first=BASE/'student-warmstart-01'
    retained_attempt(first)
    assert 'Mixed-family fit needs a `family` column' in (first/'attempt1/process/01.log').read_text()
    assert len(verdict)==13
    if readback_only:
        assert sorted(k for k,v in verdict.items() if not v)==['r_gradient','samepoint_density_accuracy']
        print('STUDENT_WARMSTART_FAILED_RESULT_READBACK_PASS')
        return
    print('ORIGINAL_STUDENT_FAILED_CHECKS',json.dumps([k for k,v in verdict.items() if not v]))
    assert process['status']=='PASS' and all(x['exit_code']==0 for x in process['results'])
    assert len(verdict)==13 and all(verdict.values())
    print('ORIGINAL_STUDENT_PUBLIC_WARMSTART_QUALIFIED')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--readback-only',action='store_true',help='Verify the retained failed result; does not qualify parity.')
    verify(parser.parse_args().readback_only)
