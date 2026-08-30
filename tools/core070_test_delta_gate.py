"""Negative controls for same-model delta acceptance."""
import copy,json
from core070_verify_delta_matched import ROOT,verify
base=json.loads((ROOT/'docs/dev-log/core070/delta-matched-evidence.json').read_text())
cases=[]
for name,key,value in [('false programme completion','scope','CORE_COMPLETE'),('stale reference','reference_commit','0'*40),('missing process','process','missing.json')]:
 e=copy.deepcopy(base);e[key]=value;cases.append((name,e))
for key,value in [('data_sha256','0'*64),('r_gradient_max',0.0),('dispersion','shared')]:
 e=copy.deepcopy(base);e['metrics']['delta_gamma'][key]=value;cases.append((key,e))
e=copy.deepcopy(base);e['artifacts'][e['process']]='0'*64;cases.append(('corrupted process',e))
for name,e in cases:
 try:verify(e,require_parity=True)
 except (AssertionError,FileNotFoundError):print('REJECTED: '+name)
 else:raise AssertionError('False acceptance: '+name)
print('DELTA_GATE_NEGATIVE_CONTROLS_PASS: 7')
