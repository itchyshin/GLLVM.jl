"""Bind wide/long source formulas to the unchanged native/R Gaussian contracts."""
import copy,json
from pathlib import Path
import core070_covariance_programme as native
ROOT=native.ROOT
CONTRACT='docs/dev-log/core070/covariance-formula-programme-contract.json'
HELPER='test/parity/covariance_formula_cases.jl'
FIXTURES=['test/parity/test_covariance_fixed_formula_required.jl','test/parity/test_covariance_modes_formula_required.jl']
FIXED=[i+'-FORMULA-INTERFACE' for i in native.FIXED]
MODES=[i+'-FORMULA-INTERFACE' for i in native.MODES]
IDS=FIXED+MODES
sha=native.sha
need=native.need

def build(root=ROOT):
    rows=[]
    for original in native.build(root)['cases']:
        row=copy.deepcopy(original);fixed=row['id'] in native.FIXED
        row.update(id=row['id']+'-FORMULA-INTERFACE',native_case_id=original['id'],coverage_role='formula_interface',acceptance_level='paired_fit_interface',fixture=FIXTURES[0 if fixed else 1],execution_case_ids=FIXED if fixed else MODES,native_dependencies=native.FIXED if fixed else native.MODES,helper=HELPER,helper_sha256=sha(root/HELPER),formula_routes=['wide','reversed_long'],julia_call='gllvm(@formula(y~1),Y,site_data;sources, g_tol=1e-7,iterations=2000'+(',sigma_eps_fixed=c' if fixed else '')+'); gllvm(@formula(y~1),reversed_long;sources,species=:trait,site=:unit,g_tol=1e-7,iterations=2000'+(',sigma_eps_fixed=c' if fixed else '')+')',acceptance_rule=original['acceptance_rule']+'; BOTH wide/reversed-long formula fits require same model, healthy native and R prerequisites in this run; exact mean design/site/trait ordering and identifiable covariance; wide/long agreement additional only',scope_boundary='Gaussian explicit-source wide/long formula only; native dependency must run in same process. Public R bridge, other families, random-source grammar, inference/recovery/performance remain unpaid.')
        row['fixture_sha256']=sha(root/row['fixture'])
        rows.append(row)
    return dict(schema=1,status='NINE_FORMULA_INTERFACES_NOT_FULL_COVARIANCE',reference_commit=native.REFERENCE,native_registry_sha256=sha(root/native.CONTRACT),cases=rows)

def validate_registry(manifest,root=ROOT):
    need(manifest.get('covariance_formula_case_ids')==IDS,'formula covariance IDs differ')
    path=root/CONTRACT
    need(manifest.get('covariance_formula_registry')==dict(path=CONTRACT,sha256=sha(path)),'formula covariance registry pin differs')
    contract=json.loads(path.read_text());need(contract==build(root),'formula contract/fixture changed')
    rows=manifest.get('covariance_interfaces',[])
    need([r['id'] for r in rows]==IDS and all(r['fixture']==FIXTURES[0 if r['id'] in FIXED else 1] and r['role']=='formula_interface' for r in rows),'formula runner inventory differs')
    cases={r['id']:r for r in manifest.get('executable_case',[])}
    for row in contract['cases']:
        need(row['id'] in cases and all(cases[row['id']].get(k)==v for k,v in row.items()),'formula executable contract differs '+row['id'])
        base=cases.get(row['native_case_id'],{})
        need(base.get('model_contract_id')==row['model_contract_id'] and base.get('model_contract')==row['model_contract'],'formula changes native model')
    need(set(IDS)<={r['id'] for r in manifest.get('obligation',[])},'formula obligations missing')
    return contract
