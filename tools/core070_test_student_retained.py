"""Metadata corruption controls complement the retained live normalizer mutation."""
import copy,json
from unittest.mock import patch
import core070_verify_student_retained as v
e=json.loads((v.ROOT/'docs/dev-log/core070/student-retained-scalar-evidence.json').read_text());v.verify(e)
n=0
def reject(action):
 global n
 try:action()
 except (AssertionError,KeyError,FileNotFoundError):n+=1
 else:raise AssertionError('Invalid evidence accepted')
for key,value in [('engine_changed',True),('fit_health_passed',True),('assertions',901)]:
 x=copy.deepcopy(e);x[key]=value;reject(lambda:v.verify(x))
x=copy.deepcopy(e);key=next(k for k in x['artifacts'] if k.endswith('process1/process-receipt.json'));x['artifacts'][key]='0'*64;reject(lambda:v.verify(x))
original=v.sha
with patch.object(v,'sha',side_effect=lambda p:'0'*64 if p==v.ROOT/'test/fixtures/core070_student_scales.toml' else original(p)):
 reject(lambda:v.verify(e))
reject(lambda:v.verify(e,require_health=True))
assert n==6
print('STUDENT_RETAINED_EVIDENCE_NEGATIVES_PASS 6')
