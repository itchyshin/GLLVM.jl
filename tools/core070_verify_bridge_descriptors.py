"""Check frozen bridge descriptor observations; never promote model parity."""
import argparse
from collections import Counter
from copy import deepcopy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / '.unlazy/core070-aghq/bridge-descriptor-admission-03'
CONTRACT = 'docs/dev-log/core070/bridge-descriptor-contract.json'
REFERENCE = 'b4d5fee64def88bc768dda1f1f77c29b295edd86'
COUNTS = {'DESCRIPTOR_ERROR': 12, 'EXCLUDED_NOT_EVALUATED': 14,
          'MAPPED_KEY_NOT_MODEL_PROOF': 18, 'MAPPER_REJECTED': 25}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def need(condition, message):
    if not condition:
        raise ValueError(message)


def check(result, contract):
    need(result['reference_commit'] == contract['reference_commit'] == REFERENCE,
         'wrong reference')
    need(result['scope'] == contract['scope'], 'model promotion or changed scope')
    rows = result['rows']
    need(len(rows) == contract['expected_case_count'] == 69, 'missing descriptor')
    need(len({c['id'] for c in contract['cases']}) == 69, 'duplicate contract IDs')
    need(Counter(r['status'] for r in rows) == COUNTS, 'observation counts changed')
    for row, case in zip(rows, contract['cases']):
        need(all(row.get(k) == v for k, v in case.items()), 'case contract changed')
        status = row['status']
        if case['native_classification'] == 'intentionally_excluded_constructor_only':
            need(status == 'EXCLUDED_NOT_EVALUATED' and set(row) == set(case) | {'status'},
                 'excluded constructor evaluated')
        else:
            need(status != 'EXCLUDED_NOT_EVALUATED', 'required case omitted')
        if status == 'MAPPER_REJECTED':
            error = row['error']
            need(error.startswith('[GJL-GATE-FAMILY] ') or error ==
                 "engine = 'julia': family must resolve to one supported family name.",
                 'unexpected rejection error')
            need(row['public_rejections_match'] is True and
                 row['public_matrix_error'] == row['public_formula_error'] == error,
                 'public rejection differs from mapper')
            fixture = ('24_UNITS_THREE_CATEGORIES' if row.get('requested_family') == 'multinomial'
                       else '4_TRAITS_6_UNITS')
            need(row['public_formula_fixture'] == fixture, 'invalid rejection fixture')
        elif status == 'MAPPED_KEY_NOT_MODEL_PROOF':
            need(isinstance(row['mapped_family'], str) and bool(row['mapped_family']),
                 'missing mapped key')
            need('public_rejections_match' not in row, 'mapped key promoted to public proof')
        elif status == 'DESCRIPTOR_ERROR':
            need(case['native_classification'] == 'rejected' and
                 isinstance(row['error'], str) and bool(row['error']), 'unexpected constructor failure')


def verify(self_test=False):
    contract = json.loads((ROOT / CONTRACT).read_text())
    original_path = ROOT / 'docs/dev-log/core070/family-admission-subset.json'
    original = json.loads(original_path.read_text())
    need(contract['source_descriptor_sha256'] == sha(original_path), 'stale descriptor source')
    need(contract['cases'] == [dict(id='BRIDGE-DESCRIPTOR-' + c['id'],
        source_fact_id='family/' + c['id'], reference_descriptor_call=c['reference_descriptor_call'],
        native_classification=c['classification']) for c in original['cases']], 'source mapping differs')
    source_path = ROOT / '.unlazy/core070-aghq/oracle-source/source.json'
    source = json.loads(source_path.read_text())
    need(source['reference_commit'] == original['reference_commit'] == REFERENCE, 'stale oracle')
    for name, pin in contract['source_pins'].items():
        need(source['source_files'][name] == pin == sha(source_path.parent / 'readback' / name),
             'oracle source changed')
    plan = json.loads((STATE / 'plan.json').read_text())
    folder = STATE / 'attempt1'
    process = json.loads((folder / 'process/process-receipt.json').read_text())
    need(process['status'] == 'PASS' and process['source_unchanged'] is True and
         process['supervisor_error'] is None, 'failed process')
    need(process['plan_sha256'] == sha(STATE / 'plan.json') and
         process['source_pins'] == plan['pins'] and process['environment_overrides'] == plan['env'],
         'changed process provenance')
    need([r['id'] for r in process['results']] ==
         ['oracle-before', 'descriptor-admission', 'oracle-after'], 'missing command')
    for row, command in zip(process['results'], plan['commands']):
        need(row['argv'] == command['argv'] and row['exit_code'] == 0 and
             row['supervisor_error'] is None and row['elapsed_seconds'] <= command['timeout_seconds'],
             'failed command or time cap')
        need(sha(folder / 'process' / row['log']) == row['log_sha256'], 'log modified')
    for name in [CONTRACT, 'tools/core070_bridge_descriptor_admission.R',
                 'tools/core070_targeted_run.py', 'tools/core070_build_oracle.py',
                 str(original_path.relative_to(ROOT)), str(source_path.relative_to(ROOT))]:
        need(plan['pins'].get(name) == sha(ROOT / name), 'stale source pin ' + name)
    path = folder / 'bridge-admission-results.json'
    result = json.loads(path.read_text())
    need(result['contract_sha256'] == sha(ROOT / CONTRACT), 'stale result contract')
    log = (folder / 'process/01.log').read_text()
    need('BRIDGE_ADMISSION_RESULTS_SHA256 ' + sha(path) + '  ' + path.name in log and
         log.count('CORE070_BRIDGE_DESCRIPTOR_OBSERVATION_PASS') == 1, 'unbound result')
    for filename in ['00.log', '02.log']:
        need('CORE070_ORACLE_VERIFY_PASS' in (folder / 'process' / filename).read_text(),
             'oracle verification absent')
    check(result, contract)
    if self_test:
        rejected = next(i for i, r in enumerate(result['rows']) if r['status'] == 'MAPPER_REJECTED')
        excluded = next(i for i, r in enumerate(result['rows']) if r['status'] == 'EXCLUDED_NOT_EVALUATED')
        mapped = next(i for i, r in enumerate(result['rows']) if r['status'] == 'MAPPED_KEY_NOT_MODEL_PROOF')
        mutations = [lambda r: r['rows'].pop(), lambda r: r['rows'].reverse(),
            lambda r: r.update(reference_commit='stale'), lambda r: r.update(scope='PARITY_PASS'),
            lambda r: r['rows'][rejected].update(public_matrix_error='unexpected'),
            lambda r: r['rows'][rejected].update(public_formula_error='bad data'),
            lambda r: r['rows'][rejected].update(public_rejections_match=False),
            lambda r: r['rows'][rejected].update(public_formula_fixture='bad fixture'),
            lambda r: r['rows'][excluded].update(mapped_family='invented'),
            lambda r: r['rows'][mapped].update(status='PARITY_PASS'),
            lambda r: r['rows'][mapped].update(public_rejections_match=True)]
        for mutate in mutations:
            bad = deepcopy(result)
            mutate(bad)
            try:
                check(bad, contract)
            except ValueError:
                continue
            raise AssertionError('invalid receipt accepted')
        print('BRIDGE_DESCRIPTOR_NEGATIVES_PASS', len(mutations))
    required_rejected = [r['source_fact_id'] for r in result['rows'] if
        r['native_classification'] == 'required_core' and r['status'] == 'MAPPER_REJECTED']
    rejected_mapped = [r['source_fact_id'] for r in result['rows'] if
        r['native_classification'] == 'rejected' and r['status'] == 'MAPPED_KEY_NOT_MODEL_PROOF']
    print('BRIDGE_DESCRIPTOR_OBSERVATIONS_VERIFIED_NOT_MODEL_PARITY')
    return dict(status='VERIFIED_DESCRIPTOR_OBSERVATIONS_NOT_MODEL_PARITY', reference_commit=REFERENCE,
        contract_sha256=sha(ROOT / CONTRACT), result_sha256=sha(path),
        process_sha256=sha(folder / 'process/process-receipt.json'), counts=COUNTS,
        seconds=process['results'][1]['elapsed_seconds'], public_rejection_pairs=25,
        required_native_descriptors_rejected_by_bridge=required_rejected,
        native_rejected_descriptors_mapping_to_bridge_keys=rejected_mapped)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    evidence = verify(args.self_test)
    if args.output:
        with args.output.open('x') as handle:
            json.dump(evidence, handle, indent=2)
            handle.write('\n')
