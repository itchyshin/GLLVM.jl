"""Exercise before-fit source locks without loading Julia or R fitting packages."""
import json,os,shutil,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SCRIPT='tools/core070_poisson_beta_health.jl'
CONTRACT='docs/dev-log/core070/poisson-beta-health-contract.json'
REFINED='docs/dev-log/core070/poisson-beta-refinement-contract.json'
FIXTURES=['test/parity/test_poisson_parity.jl','test/parity/test_beta_parity.jl']

def run():
    positive=negative=0
    for kind,expected in [('default',None),('refined',None),('contract','predeclared contract changed'),
                          ('fixture','original fixture changed'),('refined_contract','predeclared contract changed'),('unknown','invalid refinement policy')]:
        with tempfile.TemporaryDirectory(prefix='pb-preflight-') as folder:
            root=Path(folder)
            for rel in [SCRIPT,CONTRACT,REFINED]+FIXTURES:
                p=root/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,p)
            env=dict(os.environ);env['CORE070_PB_POLICY']='public_start_from_refinement_v1' if kind in ('refined','refined_contract') else 'original_defaults_no_refit'
            if kind=='contract':(root/CONTRACT).write_text('{}\n')
            if kind=='refined_contract':(root/REFINED).write_text('{}\n')
            if kind=='fixture':
                p=root/FIXTURES[0];p.write_text(p.read_text().replace('Random.seed!(44)','Random.seed!(45)'))
            if kind=='unknown':env['CORE070_PB_POLICY']='accept-everything'
            result=subprocess.run(['julia','--startup-file=no',str(root/SCRIPT),'--check'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
            if expected:
                assert result.returncode!=0 and expected in result.stdout,(kind,result.stdout);negative+=1
            else:
                assert result.returncode==0 and 'POISSON_BETA_PREFLIGHT_PASS' in result.stdout and 'fits=0' in result.stdout,result.stdout;positive+=1
    print('POISSON_BETA_PREFLIGHT_TESTS_PASS',positive,'positive;',negative,'negative; fits=0')
if __name__=='__main__':run()
