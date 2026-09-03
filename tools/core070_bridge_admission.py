"""Bind proven frozen-R bridge boundaries to specific required native models.

A reference boundary pays only the public bridge behavior obligation. Native
and formula same-model parity, and the independent full-scope review, remain
required. Descriptor-to-key mapping never authorizes a boundary here.
"""
import argparse
import json
from pathlib import Path
import core070_manifest_coverage as c

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = c.PREFIX + 'bridge-model-admission-contract.json'
INPUTS = [c.PREFIX + name for name in ['gaussian-required-contract.json',
          'registered-models-contract.json', 'bridge-descriptor-contract.json']]


def build_contract(root=ROOT):
    gaussian, registered, descriptors = [c.read_json(c.safe_path(root, p)) for p in INPUTS]
    c.need(all(x['reference_commit'] == c.REFERENCE for x in [gaussian, registered, descriptors]),
           'bridge boundary reference drift')
    native = [next(x for x in gaussian['cases'] if x['coverage_role'] == 'native_model'),
              next(x for x in registered['cases'] if x['id'] == 'NATIVE-12-TRUNCATED-NB2')]
    specifications = [
        ('family/FAMILY-00-IDENTITY', 'reference_model_change',
         'tools/core070_gaussian_bridge_boundary.R',
         'gllvmTMB(value~0+latent(0+trait|site,d=1), data=original_gaussian_data, '
         'unit="site", trait="trait", family=gaussian(), engine="julia")',
         'Original zero-mean p4/n120/K1 fixture: default unique request warns and equals '
         'explicit unique=false; common residual scale and df5 rather than required df8. '
         'This is reference model-change behavior, not same-model parity.'),
        ('family/FAMILY-11-LOG', 'reference_rejected',
         'tools/core070_bridge_descriptor_admission.R',
         'gllvm_julia_fit(matrix(1,4,6),family=truncated_nbinom2(),num.lv=1); '
         'gllvmTMB(value~0+trait+latent(0+trait|site,d=1,unique=FALSE), '
         'data=valid_4_trait_6_unit_data,unit="site",trait="trait",'
         'family=truncated_nbinom2(),engine="julia")',
         'Both exported public routes reproduce the exact GJL-GATE-FAMILY error on '
         'valid generic data. Frozen R/julia-bridge.R maps the family before fitting. '
         'The original seed58 p5/n120/K1 native model still needs native/formula parity.')]
    rows = []
    for model, (sid, disposition, fixture, r_call, rule) in zip(native, specifications):
        c.need(model['source_fact_ids'] == [sid] and
               model['model_contract_id'] == 'MODEL-' + sid.split('/')[1], 'native model mismatch')
        c.need(model['fixture_sha256'] == c.sha(c.safe_path(root, model['fixture'])),
               'native fixture changed')
        rows.append(dict(id='CORE070-' + sid.split('/')[1] + '-PUBLIC-R-BRIDGE',
            coverage_role='public_r_bridge', acceptance_level='reference_bridge_boundary',
            source_fact_ids=[sid], model_contract_id=model['model_contract_id'],
            native_case_id=model['id'], native_contract=INPUTS[len(rows)],
            native_contract_row_sha256=c.row_sha(model),
            native_model_contract=model['model_contract'],
            model_contract=model['model_contract'],
            fixture=fixture, fixture_sha256=c.sha(c.safe_path(root, fixture)),
            r_call=r_call, julia_call=model['julia_call'],
            bridge_admission=disposition, acceptance_rule=rule,
            scope_boundary='Reference bridge behavior only; native/formula same-model requirements unchanged.'))
    rows[0]['data_fixture'] = native[0]['data_fixture']
    rows[0]['data_fixture_sha256'] = native[0]['data_fixture_sha256']
    rows[1]['native_data_sha256'] = native[1]['data_sha256']
    rows[1]['descriptor_case_id'] = 'BRIDGE-DESCRIPTOR-FAMILY-11-LOG'
    return dict(schema=1, status='TWO_BOUND_REFERENCE_BRIDGE_BEHAVIORS_NOT_MODEL_PARITY',
        reference_commit=c.REFERENCE, inputs={p: c.sha(c.safe_path(root, p)) for p in INPUTS},
        cases=rows)


def require_boundary(row, fact, root=ROOT):
    c.need(root.resolve() == ROOT.resolve(), 'bridge raw verifier root differs')
    c.need(row.get('bridge_boundary_contract') == CONTRACT, 'unknown bridge boundary contract')
    path = c.safe_path(root, CONTRACT)
    c.need(row.get('bridge_boundary_contract_sha256') == c.sha(path), 'stale bridge boundary contract')
    contract = c.read_json(path)
    c.need(contract == build_contract(root), 'bridge boundary contract differs from source bindings')
    matches = [b for b in contract['cases'] if b['id'] == row.get('id')]
    c.need(len(matches) == 1, 'unknown bridge boundary case')
    binding = matches[0]
    c.need(all(row.get(k) == v for k, v in binding.items()), 'bridge boundary case binding differs')
    c.need(fact['id'] in binding['source_fact_ids'] and fact['classification'] == 'required_core',
           'bridge boundary source fact differs')
    # These live verifiers inspect raw results, source pins, supervisor exits,
    # log hashes and the actual observed behavior. Summary JSON is not evidence.
    if binding['bridge_admission'] == 'reference_model_change':
        from core070_verify_gaussian_bridge_boundary import verify
        from core070_verify_bridge_runtime import verify as runtime
        runtime(False)
        receipt = verify(False)
        c.need(receipt['status'] == 'VERIFIED_REFERENCE_MODEL_CHANGE_NOT_PARITY' and
               receipt['actual_df'] == 5 and receipt['required_unique_model_df'] == 8,
               'unverified Gaussian model change')
    else:
        from core070_verify_bridge_descriptors import verify
        receipt = verify(False)
        c.need(receipt['status'] == 'VERIFIED_DESCRIPTOR_OBSERVATIONS_NOT_MODEL_PARITY' and
               fact['id'] in receipt['required_native_descriptors_rejected_by_bridge'],
               'unverified frozen bridge rejection')
    return dict(id=row['id'], disposition=binding['bridge_admission'],
                model_contract_id=binding['model_contract_id'],
                process_sha256=receipt['process_sha256'])


def bound_rows(root=ROOT):
    path = c.safe_path(root, CONTRACT)
    contract = c.read_json(path)
    c.need(contract == build_contract(root), 'bridge boundary contract differs')
    return [dict(row, bridge_boundary_contract=CONTRACT,
                 bridge_boundary_contract_sha256=c.sha(path)) for row in contract['cases']]


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--verify', action='store_true')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.write:
        with (ROOT / CONTRACT).open('x') as handle:
            json.dump(build_contract(), handle, indent=2)
            handle.write('\n')
    if args.verify:
        results = [require_boundary(row, dict(id=row['source_fact_ids'][0],
                   classification='required_core')) for row in bound_rows()]
        print('TWO_MODEL_BOUND_BRIDGE_BOUNDARIES_VERIFIED_NOT_MODEL_PARITY')
        if args.output:
            with args.output.open('x') as handle:
                json.dump(dict(status='VERIFIED_REFERENCE_BOUNDARIES_NOT_MODEL_PARITY',
                    contract_sha256=c.sha(ROOT / CONTRACT), cases=results), handle, indent=2)
                handle.write('\n')
