import copy,json
from unittest.mock import patch
import core070_verify_data_controls as v
e=json.loads((v.ROOT/'docs/dev-log/core070/data-controls-subset.json').read_text());v.verify(e)
n=0
def reject(action):
 global n
 try:action()
 except (AssertionError,KeyError,FileNotFoundError):n+=1
 else:raise AssertionError('Invalid evidence accepted')
for field,value in [('native_parity',True),('installed_package',True),('expected_cases',55),('reference_commit','stale')]:
 x=copy.deepcopy(e);x[field]=value;reject(lambda:v.verify(x))
x=copy.deepcopy(e);x['case_ids'].pop();reject(lambda:v.verify(x))
x=copy.deepcopy(e);key=next(k for k in x['artifacts'] if k.endswith('process1/process-receipt.json'));x['artifacts'][key]='0'*64;reject(lambda:v.verify(x))
original=v.sha
with patch.object(v,'sha',side_effect=lambda p:'0'*64 if p==v.ROOT/e['fixture'] else original(p)):
 reject(lambda:v.verify(e))
reject(lambda:v.verify(e,require_parity=True))
assert n==8
print('FROZEN_DATA_CONTROLS_NEGATIVES_PASS 8')
