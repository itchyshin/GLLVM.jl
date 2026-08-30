"""Negative controls for the local scalar evidence gate; no artifact mutation."""
import copy
import json
from unittest.mock import patch
import core070_verify_truncnb2_kernel as gate

evidence=json.loads((gate.ROOT/'docs/dev-log/core070/truncnb2-kernel-evidence.json').read_text())
gate.verify(evidence)
checks=0
def reject(action):
 global checks
 try: action()
 except (AssertionError,KeyError,FileNotFoundError): checks+=1
 else: raise AssertionError('Negative control unexpectedly passed')
for field in ['whole_package_loaded','independent_review','remote_fit_replay']:
 altered=copy.deepcopy(evidence);altered[field]=True
 reject(lambda:gate.verify(altered))
altered=copy.deepcopy(evidence);altered['phases'].remove('extended-red')
reject(lambda:gate.verify(altered))
altered=copy.deepcopy(evidence);altered['final_assertions']=353
reject(lambda:gate.verify(altered))
altered=copy.deepcopy(evidence)
receipt=next(k for k in altered['artifacts'] if k.endswith('final/process/process-receipt.json'))
altered['artifacts'][receipt]='0'*64
reject(lambda:gate.verify(altered))
with patch.object(gate,'sha',side_effect=FileNotFoundError('missing receipt')):
 reject(lambda:gate.verify(evidence))
original=gate.sha
with patch.object(gate,'sha',side_effect=lambda p:'0'*64 if p==gate.ROOT/'src/families/truncated_nbinom2.jl' else original(p)):
 reject(lambda:gate.verify(evidence))
reject(lambda:gate.verify(evidence,require_fits=True))
assert checks==9
print('TRUNCNB2_GATE_NEGATIVE_CONTROLS_PASS 9')
