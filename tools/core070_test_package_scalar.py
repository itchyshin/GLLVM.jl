"""Negative controls for complete-module evidence; do not mutate retained receipts."""
import copy,json
from unittest.mock import patch
import core070_verify_package_scalar as v
e=json.loads((v.ROOT/'docs/dev-log/core070/package-scalar-evidence.json').read_text());v.verify(e)
n=0
def rejects(action):
 global n
 try:action()
 except (AssertionError,KeyError,FileNotFoundError):n+=1
 else:raise AssertionError('Corrupt evidence accepted')
for field,value in [('package_loaded',False),('full_suite',True),('fitted_replay',True),('scalar_assertions',353),('curvature_assertions',65),('manifest_sha256','0'*64)]:
 x=copy.deepcopy(e);x[field]=value;rejects(lambda:v.verify(x))
x=copy.deepcopy(e);key=next(k for k in x['artifacts'] if k.endswith('process3/process-receipt.json'));x['artifacts'][key]='0'*64;rejects(lambda:v.verify(x))
original=v.sha
with patch.object(v,'sha',side_effect=lambda p:'0'*64 if p==v.ROOT/'src/families/truncated_nbinom2.jl' else original(p)):
 rejects(lambda:v.verify(e))
rejects(lambda:v.verify(e,require_fits=True))
assert n==9
print('FULL_MODULE_EVIDENCE_NEGATIVE_CONTROLS_PASS 9')
