import copy,json
from unittest.mock import patch
import core070_verify_bridge_input as v
e=json.loads((v.ROOT/'docs/dev-log/core070/bridge-truncated-input-evidence.json').read_text());v.verify(e)
n=0
def reject(action):
 global n
 try:action()
 except (AssertionError,KeyError,FileNotFoundError):n+=1
 else:raise AssertionError('Invalid evidence accepted')
for key,value in [('fits_run',True),('embedding_qualified',True),('full_suite',True),('bridge_assertions',149),('final_assertions',1465)]:
 x=copy.deepcopy(e);x[key]=value;reject(lambda:v.verify(x))
x=copy.deepcopy(e);key=next(k for k in x['artifacts'] if k.endswith('final-process/process-receipt.json'));x['artifacts'][key]='0'*64;reject(lambda:v.verify(x))
original=v.sha
with patch.object(v,'sha',side_effect=lambda p:'0'*64 if p==v.ROOT/'src/bridge.jl' else original(p)):
 reject(lambda:v.verify(e))
reject(lambda:v.verify(e,require_bridge=True))
assert n==8
print('BRIDGE_INPUT_EVIDENCE_NEGATIVES_PASS 8')
