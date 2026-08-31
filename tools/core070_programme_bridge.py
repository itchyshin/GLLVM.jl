"""Typed public-R component of the full programme's mixed-language verifier."""
import argparse
import json
from pathlib import Path
import core070_manifest_coverage as c
from core070_bridge_admission import bound_rows, require_boundary, CONTRACT as BOUNDARIES

ROOT=Path(__file__).resolve().parents[1]
REGISTRY=c.PREFIX+'public-r-bridge-programme-registry.json'
PAIRED=c.PREFIX+'public-bridge-required-cases.json'
NATIVE=c.PREFIX+'registered-models-contract.json'


def build_registry(root=ROOT):
    paired=c.read_json(c.safe_path(root,PAIRED))
    native=c.read_json(c.safe_path(root,NATIVE))
    c.need(paired['reference_commit']==native['reference_commit']==c.REFERENCE,'bridge reference drift')
    rows=[]
    for case in paired['cases']:
        models=[m for m in native['cases'] if m['coverage_role']=='native_model' and
                m['model_contract_id']==case['model_contract_id']]
        c.need(len(models)==1,'unbound paired bridge model')
        rows.append(dict(case,executor='public_r_bridge',reference_call=case['r_call'],
            model_contract=models[0]['model_contract'],
            fixture_sha256=c.sha(c.safe_path(root,case['fixture'])),
            bridge_subcontract=PAIRED,bridge_subcontract_sha256=c.sha(root/PAIRED)))
    rows.extend(dict(row,executor='public_r_bridge',reference_call=row['r_call'])
                for row in bound_rows(root))
    c.need(len(rows)==len({r['id'] for r in rows})==5,'bridge registry count differs')
    return dict(schema=1,status='FIVE_BOUND_BRIDGE_CASES_NOT_FULL_PROGRAMME',
        reference_commit=c.REFERENCE,case_ids=[r['id'] for r in rows],cases=rows,
        inputs={p:c.sha(c.safe_path(root,p)) for p in [PAIRED,NATIVE,BOUNDARIES]})


def validate_registry(manifest,root=ROOT):
    declaration=manifest.get('public_r_bridge_registry',{})
    c.need(declaration.get('path')==REGISTRY,'missing public R bridge registry')
    path=c.safe_path(root,REGISTRY)
    c.need(declaration.get('sha256')==c.sha(path),'stale public R bridge registry')
    registry=c.read_json(path)
    c.need(registry==build_registry(root),'public R bridge registry differs from source contracts')
    c.need(manifest.get('public_r_bridge_case_ids')==registry['case_ids'],'bridge IDs differ')
    rows=[r for r in manifest.get('executable_case',[]) if r.get('executor')=='public_r_bridge']
    c.need(len(rows)==5 and {r['id'] for r in rows}==set(registry['case_ids']),'bridge cases omitted or duplicated')
    by_id={r['id']:r for r in rows}
    c.need(all(all(by_id[r['id']].get(k)==v for k,v in r.items()) for r in registry['cases']),
           'inline bridge contract differs')
    return registry


def verify_component(manifest,selection,root=ROOT):
    registry=validate_registry(manifest,root)
    c.need(isinstance(selection,dict) and set(selection)=={'case_ids','registry_sha256'},
           'missing or malformed public R bridge selection')
    c.need(selection['case_ids']==registry['case_ids'] and
           selection['registry_sha256']==c.sha(root/REGISTRY),'stale or incomplete bridge selection')
    from core070_verify_bridge_bundle import verify
    bundle=verify(False)
    c.need(bundle['status']=='BOUNDED_BRIDGE_EVIDENCE_VERIFIED_NOT_FULL_PARITY','failed bridge bundle')
    models=bundle['components']['models']
    from core070_verify_bridge_models import STATE
    manifest_path=root/(c.PREFIX+'frozen-r070-contract.toml')
    plan=c.read_json(STATE/'plan.json')
    c.need(plan['pins'].get(str(manifest_path.relative_to(root)))==c.sha(manifest_path) and
           plan['pins'].get(REGISTRY)==c.sha(root/REGISTRY),
           'public R execution predates the programme manifest or registry')
    paired_ids=[r['id'] for r in registry['cases'] if r['acceptance_level']=='paired_fit_interface']
    c.need(models['required_case_ids']==paired_ids,'paired bridge cases differ')
    boundaries=[]
    for row in registry['cases']:
        if row['acceptance_level']=='reference_bridge_boundary':
            boundaries.append(require_boundary(row,dict(id=row['source_fact_ids'][0],
                              classification='required_core'),root))
    return dict(status='PASS',scope='PUBLIC_R_BRIDGE_COMPONENT_ONLY',
                case_ids=registry['case_ids'],registry_sha256=c.sha(root/REGISTRY),
                manifest_sha256=c.sha(manifest_path),
                paired=models,boundaries=boundaries,
                runtime=bundle['components']['runtime'])


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write',action='store_true')
    parser.add_argument('--verify',action='store_true')
    parser.add_argument('--output',type=Path)
    args=parser.parse_args()
    if args.write:
        with (ROOT/REGISTRY).open('x') as h:json.dump(build_registry(),h,indent=2);h.write('\n')
    if args.verify:
        from core070_evidence import load_manifest,DEFAULT_MANIFEST
        manifest=load_manifest(DEFAULT_MANIFEST)
        result=verify_component(manifest,dict(case_ids=manifest['public_r_bridge_case_ids'],
            registry_sha256=c.sha(ROOT/REGISTRY)))
        print('PUBLIC_R_BRIDGE_PROGRAMME_COMPONENT_VERIFIED_NOT_FULL_PROGRAMME')
        if args.output:
            with args.output.open('x') as h:json.dump(result,h,indent=2);h.write('\n')
