"""Evidence corruption controls and one deliberately false live dispatch expectation."""
import copy,csv,json,subprocess,tempfile
from pathlib import Path
import core070_verify_inference_routes as v
e=json.loads((v.ROOT/'docs/dev-log/core070/inference-routing-subset.json').read_text())
v.verify(e)
checks=0
def reject(x):
 global checks
 try:v.verify(x)
 except (AssertionError,KeyError,FileNotFoundError):checks+=1
 else:raise AssertionError('Invalid evidence accepted')
for field,value in [('numerical_intervals',True),('installed_package',True),('expected_cases',97),('reference_commit','stale')]:
 x=copy.deepcopy(e);x[field]=value;reject(x)
x=copy.deepcopy(e);x['case_ids'].pop();reject(x)
x=copy.deepcopy(e);x['artifacts'][e['receipt']]='0'*64;reject(x)
x=copy.deepcopy(e);x['current_pins'][e['fixture']]='0'*64;reject(x)
# Exercise the probe, not only a hash checker; a false expected route must cause exit 1.
with tempfile.TemporaryDirectory(prefix='core070-inference-negative-') as t:
 t=Path(t);rows=list(csv.DictReader((v.ROOT/e['fixture']).open(),delimiter='\t'));rows[0]['expected']='IMPOSSIBLE_ROUTE'
 with (t/'fixture.tsv').open('w') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]),delimiter='\t');w.writeheader();w.writerows(rows)
 r=subprocess.run(['/Library/Frameworks/R.framework/Resources/bin/Rscript','--vanilla',str(v.ROOT/'tools/core070_inference_routes.R'),str(v.ROOT/'.unlazy/core070-aghq/oracle-source/readback'),str(t/'fixture.tsv'),str(t/'results.tsv')],capture_output=True,text=True,timeout=60)
 assert r.returncode==1 and 'RESULT 97 PASS 1 FAIL' in r.stdout
 checks+=1
assert checks==8
print('INFERENCE_ROUTE_NEGATIVE_CONTROLS_PASS 8')
