"""Verify retained same-point measurements without turning them into fit parity."""
import copy,csv,hashlib,io,json,math
from pathlib import Path
import tomllib

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'.unlazy/core070-aghq'
STATE=BASE/'student-samepoint-03'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def close(a,b,tol=1e-9):assert math.isfinite(a) and math.isfinite(b) and abs(a-b)<=tol,(a,b)

def validate_points(points):
    assert [p['id'] for p in points]==['original-r','retained-tighter-r','retained-native']
    for row in points:
        names=row['parameter_names'];q=row['full_parameters']
        assert len(names)==len(q)==150 and names.count('z_B')==130
        assert all(math.isfinite(v) for v in q)
        for name in ['b_fix','theta_rr_B','log_sigma_student','log_df_student']:assert names.count(name)==5
        assert [q[i] for i,name in enumerate(names) if name!='z_B']==row['outer_parameters']
        rg,ng=row['r_gradient'],row['native_gradient']
        assert len(rg)==len(ng)==150 and all(math.isfinite(v) for v in rg+ng)
        close(max(abs(a-b) for a,b in zip(rg,ng)),row['joint_gradient_delta_max'])
        close(max(abs(rg[i]) for i,name in enumerate(names) if name=='z_B'),row['r_mode_gradient_max'])
        rd,nd=row['r_hzz_diagonal'],row['native_hzz_diagonal']
        assert len(rd)==len(nd)==130 and all(math.isfinite(v) and v>0 for v in rd+nd)
        close(max(abs(a-b)/max(1,abs(a)) for a,b in zip(rd,nd)),row['hzz_relative_delta_max'])
        close(row['r_joint']+sum(math.log(v) for v in rd)/2-130*math.log(2*math.pi)/2,row['r_reconstructed'])
        close(row['native_joint']+sum(math.log(v) for v in nd)/2-130*math.log(2*math.pi)/2,row['native_reconstructed'])
        close(row['native_joint']-row['r_joint'],row['joint_delta'])
        close(row['native_actual_marginal']-row['r_marginal'],row['native_marginal_delta'])
        close(row['native_marginal_delta'],row['joint_delta'],1e-8)
        assert row['hzz_relative_delta_max']<1e-12 and row['r_hzz_offdiagonal_max']==0
        assert row['r_mode_gradient_max']<1e-4
        close(row['r_reconstructed'],row['r_marginal'])
    assert 0.003<points[0]['joint_delta']<0.0032
    assert 0.003<points[1]['joint_delta']<0.0032
    assert 119<points[2]['joint_delta']<120

def verify():
    for attempt,wanted in [('01','FAIL'),('02','FAIL'),('03','PASS')]:
        directory=BASE/('student-samepoint-'+attempt)
        plan=json.loads((directory/'plan.json').read_text())
        record=json.loads((directory/'attempt1/process/process-receipt.json').read_text())
        assert record['status']==wanted and record['plan_sha256']==sha(directory/'plan.json')
        assert record['source_pins']==plan['pins']
        assert record['source_unchanged'] and record['supervisor_error'] is None
        assert record['environment_overrides']==plan['env']
        assert [r['id'] for r in record['results']]==['oracle-before','student-samepoint','oracle-after']
        assert [r['exit_code'] for r in record['results']]==([0,0,0] if attempt=='03' else [0,1,0])
        for row,command in zip(record['results'],plan['commands']):
            assert row['argv']==command['argv'] and row['supervisor_error'] is None
            assert sha(directory/'attempt1/process'/row['log'])==row['log_sha256']
    plan=json.loads((STATE/'plan.json').read_text())
    for name,pin in plan['pins'].items():
        p=ROOT/name
        if name=='retained.toml':p=BASE/'student-refinement/attempt2/refinement/result.toml'
        if name=='test/parity/Manifest.toml':p=BASE/'binomial-refresh-01/Manifest.toml'
        assert sha(p)==pin,name
    d=STATE/'attempt1/diagnostic'
    receipt=tomllib.loads((d/'diagnostic.toml').read_text())
    assert receipt['scope']=='SAME_PARAMETER_DIAGNOSTIC_NOT_PARITY'
    assert receipt['source']['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert receipt['data_sha256']=='2c8ac438e655b3ec39209799676f689c8a875ba300ec0df032c76ee506a94365'
    assert receipt['points_sha256']==sha(d/'points.toml')
    assert receipt['fixture_sha256']==sha(ROOT/'test/parity/test_studentt_parity.jl')
    retained=BASE/'student-refinement/attempt2/refinement/result.toml'
    assert receipt['retained_sha256']==sha(retained)
    points=tomllib.loads((d/'points.toml').read_text())['points'];validate_points(points)
    previous=tomllib.loads(retained.read_text())
    assert points[1]['outer_parameters']==previous['refined_parameters']
    native=previous['native_parameters']
    assert points[2]['outer_parameters']==native[5:10]+native[:5]+native[10:]
    close(-points[2]['native_actual_marginal'],previous['native_loglik'])
    close(receipt['original_r_loglik'],previous['original_loglik'])
    assert receipt['original_r_code']==1
    text=(STATE/'scalar-source-check.log').read_text()
    assert 'TMB_VERSION 1.9.21' in text and 'R version 4.5.3' in text
    assert 'log(1+x*x/df)' in text and 'lgamma((df+1)/2)' in text
    rows=list(csv.DictReader(io.StringIO(text[text.index('df\tz\tliteral'):]),delimiter='\t'))
    assert len(rows)==15
    expected=[(df,z) for df in [4,1e3,1e6,2.3174518756022614e10,3.034232245769893e31] for z in [0,0.7,3]]
    for row,(expected_df,expected_z) in zip(rows,expected):
        df,z,literal,stable,delta=(float(row[k]) for k in ['df','z','literal','stable','delta'])
        assert math.isclose(df,expected_df,rel_tol=1e-13) and z==expected_z
        close(literal-stable,delta,1e-12)
        if df==4:assert abs(delta)<1e-12
        if df<=1e6:assert abs(delta)<1e-8
        if 1e10<df<1e11 and z==0:assert 1e-5<delta<1e-4
        if df>1e30:
            assert literal==0
            close(stable,-math.log(2*math.pi)/2-z*z/2,1e-12)
    return points

def negatives(points):
    count=0
    for kind in ['omit','duplicate','joint','hessian','mode','marginal']:
        x=copy.deepcopy(points)
        if kind=='omit':x.pop()
        elif kind=='duplicate':x[1]=x[0]
        elif kind=='joint':x[0]['native_joint']+=1
        elif kind=='hessian':x[0]['r_hzz_diagonal'][0]*=2
        elif kind=='mode':x[0]['r_gradient'][x[0]['parameter_names'].index('z_B')]=1
        else:x[0]['native_marginal_delta']=0
        try:validate_points(x)
        except AssertionError:count+=1
        else:raise AssertionError('damaged measurement accepted: '+kind)
    assert count==6
    print('STUDENT_SAMEPOINT_NEGATIVE_CONTROLS 6 PASS')

if __name__=='__main__':
    points=verify();negatives(points)
    print('STUDENT_SAMEPOINT_SOURCE_DISCREPANCY_VERIFIED_PARITY_UNPAID')
