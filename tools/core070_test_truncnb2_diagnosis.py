"""Reject invented completion or corrupted diagnosis receipts."""
import copy,json
from core070_verify_truncnb2_diagnosis import ROOT,verify
base=json.loads((ROOT/'docs/dev-log/core070/truncnb2-diagnosis-evidence.json').read_text())
cases=[]
e=copy.deepcopy(base);e['scope']='ENGINE_FIXED';cases.append(('false fix',e))
e=copy.deepcopy(base);e['health_metrics']['r_code']=0;cases.append(('invented convergence',e))
e=copy.deepcopy(base);e['precision_metrics']['max_candidate_error']=0;cases.append(('invented precision',e))
e=copy.deepcopy(base);e['health_metrics']['data_sha256']='0'*64;cases.append(('replaced data',e))
e=copy.deepcopy(base);e['process']['health']='missing';cases.append(('missing process',e))
e=copy.deepcopy(base);e['artifacts'][e['health']]='0'*64;cases.append(('corrupt result',e))
for name,e in cases:
 try:verify(e)
 except (AssertionError,FileNotFoundError):print('REJECTED: '+name)
 else:raise AssertionError('False acceptance: '+name)
try:verify(base,require_health=True)
except AssertionError as exc:assert 'TRUNCNB2_HEALTH_UNMET' in str(exc)
else:raise AssertionError('False health acceptance')
print('TRUNCNB2_DIAGNOSIS_NEGATIVE_CONTROLS_PASS: 7')
