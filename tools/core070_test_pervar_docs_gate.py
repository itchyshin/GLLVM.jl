"""Negative controls for the bounded documentation evidence gate."""
import copy,json,tempfile
from pathlib import Path
from core070_verify_pervar_docs import ROOT,sha,verify

def main():
    original=json.loads((ROOT/'docs/dev-log/core070/pervar-docs-evidence.json').read_text())
    cases=[]
    e=copy.deepcopy(original);e['scope']='DOCS_COMPLETE';cases.append(('false completion',e,False))
    e=copy.deepcopy(original);e['process']['example']='missing-process.json';cases.append(('missing process',e,False))
    e=copy.deepcopy(original);e['example_metrics']['nparams']=12;cases.append(('fabricated metrics',e,False))
    e=copy.deepcopy(original);e['deployed']=True;cases.append(('unsupported deployment',e,True))
    e=copy.deepcopy(original);e['artifacts'][e['site_hashes']]='0'*64;cases.append(('corrupted site inventory',e,True))
    with tempfile.TemporaryDirectory(dir=ROOT/'.unlazy/core070-aghq/pervar-docs') as tmp:
        p=Path(tmp)/'process-receipt.json'
        r=json.loads((ROOT/original['process']['example']).read_text());r['status']='FAIL'
        p.write_text(json.dumps(r));relative=str(p.relative_to(ROOT))
        e=copy.deepcopy(original);e['process']['example']=relative;e['artifacts'][relative]=sha(p)
        cases.append(('failed process with valid checksum',e,False))
        for name,e,build in cases:
            try:verify(e,build=build)
            except (AssertionError,FileNotFoundError):print('REJECTED: '+name)
            else:raise AssertionError('False acceptance: '+name)
    print('PERVAR_DOCS_NEGATIVE_CONTROLS_PASS: 6')
if __name__=='__main__':main()
