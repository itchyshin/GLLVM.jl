"""Verify three source-bound formula cases and their same-run native/R health."""
import argparse
from copy import deepcopy
import json
import math
from pathlib import Path
import re
import tarfile

import core070_evidence as evidence
import core070_verify_registered_models as base
from core070_manifest_coverage import need

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / '.unlazy/core070-aghq/family-formulas-04'
CONTRACT = ROOT / 'docs/dev-log/core070/family-formulas-contract.json'
FAMILIES = ['poisson', 'beta', 'truncnb2']
IDS = ['CORE070-FAMILY-02-LOG-FORMULA-INTERFACE',
       'CORE070-FAMILY-07-LOGIT-FORMULA-INTERFACE',
       'CORE070-FAMILY-11-LOG-FORMULA-INTERFACE']


def registry_test_without_programme_count(text):
    """Keep the historical red test stable except for the global case total."""
    normalized, count = re.subn(
        r'(?m)^(\s*@test length\(requested_ids\(\)\) == )\d+(\s*)$',
        r'\1<PROGRAMME_CASE_COUNT>\2', text)
    need(count == 1, 'registry test has an ambiguous programme count assertion')
    return normalized


def close_vector(left, right):
    return len(left) == len(right) and all(math.isfinite(a) and math.isfinite(b) and
        abs(a-b) <= 1e-10 for a, b in zip(left, right))


def check_formula(report, health, case):
    need(report['id'] == case['id'] and case['prerequisite_case_ids'] == [report['native_id']],
         'formula/native case changed')
    need(report['data_sha256'] == health['data_sha256'] == case['data_sha256'], 'original data changed')
    need(report['reference_control_policy'] == health['policy'] == case['reference_control_policy'],
         'R control policy changed')
    need(report['r_loglik'] == health['r_loglik'], 'R objective changed')
    need(report['health_proof'] == 'same-run native health at identical fitted coordinates',
         'health attribution changed')
    need(report['curvature_provenance'] == ('explicit_keyword_not_stored_in_fit' if '11-LOG-' in case['id'] else 'fitted_object'), 'curvature provenance changed')
    expected_count = 14 if '02-LOG-' in case['id'] else 15
    need(report['nfree'] == expected_count, 'wrong free-parameter count')
    native = report['native']
    need(close_vector(native['parameters'], health['native_parameters']) and
         abs(native['loglik']-health['native_loglik']) <= 1e-10, 'different native optimum')
    need(report['curvature'] == health.get('hessian', 'observed'), 'curvature changed')
    expected_type = ('PoissonFit' if '02-LOG-' in case['id'] else
                     'BetaGroupedFit' if '07-LOGIT-' in case['id'] else 'TruncatedNegBin2PerTraitFit')
    need(native['type'].split('{')[0].split('.')[-1] == expected_type, 'wrong native model type')
    for label in ['native', 'wide', 'long']:
        fit = report[label]
        need(fit['converged'] is True and fit['type'] == native['type'], 'unhealthy/wrong model')
        need(fit['hessian'] == report['curvature'], 'formula curvature changed')
        need(len(fit['parameters']) == expected_count and
             close_vector(fit['parameters'], native['parameters']), 'formula parameters differ')
        need(math.isfinite(fit['loglik']) and abs(fit['loglik']-native['loglik']) <= 1e-10,
             'formula likelihood differs')
        need(math.isclose(fit['loglik'], health['r_loglik'], rel_tol=1e-6, abs_tol=0),
             'formula/R likelihood gate failed')
    need(report['input_errors'] == dict(wrong_rows='DimensionMismatch', missing_long='ArgumentError',
                                       duplicate_long='ArgumentError'), 'invalid inputs accepted')


def verify(self_test=False):
    base.STATE = STATE
    base.IDS = base.IDS[:7] + IDS
    base.COUNTS.update({cid:22 for cid in IDS})
    result = base.verify(self_test)
    folder = STATE / 'attempt1/receipts'
    contract = json.loads(CONTRACT.read_text())
    manifest = evidence.load_manifest(evidence.DEFAULT_MANIFEST)
    cases = {row['id']:row for row in manifest['executable_case']}
    need([row['id'] for row in contract['cases']] == IDS, 'formula contract inventory changed')
    need(contract['reference_commit'] == manifest['reference_commit'], 'stale reference')
    process = json.loads((STATE / 'attempt1/process/process-receipt.json').read_text())
    registry = next(row for row in process['results'] if row['id'] == 'registry')
    registry_log = (STATE / 'attempt1/process' / registry['log']).read_text()
    need(process['source_pins']['test/test_core070_interface_registry.jl'] ==
         evidence.digest(ROOT / 'test/test_core070_interface_registry.jl'), 'stale registry test')
    need(re.search(r'Formula cases require a fresh native comparison\s*\|\s*12\s+12', registry_log),
         'missing native-dependency regressions')
    red = ROOT / '.unlazy/core070-aghq/family-formulas-red-01'
    red_plan = json.loads((red / 'plan.json').read_text())
    red_receipt = json.loads((red / 'attempt1/process/process-receipt.json').read_text())
    need(red_receipt['plan_sha256'] == evidence.digest(red / 'plan.json'), 'baseline plan changed')
    need(red_receipt['status'] == 'FAIL' and red_receipt['results'][0]['exit_code'] == 1,
         'missing failing registry baseline')
    need(red_receipt['source_unchanged'] and red_receipt['source_pins'] == red_plan['pins'],
         'baseline source changed')
    red_log = red / 'attempt1/process' / red_receipt['results'][0]['log']
    need(evidence.digest(red_log) == red_receipt['results'][0]['log_sha256'] and
         'Evaluated: 2 == 5' in red_log.read_text() and 'Evaluated: 20 == 23' in red_log.read_text(),
         'baseline failed for a different reason')
    with tarfile.open(red / 'source.tar') as archive:
        red_names = set(archive.getnames())
        member = archive.extractfile('test/test_core070_interface_registry.jl')
        need(member is not None, 'historical registry test missing from red source')
        historical_registry = member.read().decode()
    need(evidence.hashlib.sha256(historical_registry.encode()).hexdigest() ==
         red_plan['pins']['test/test_core070_interface_registry.jl'], 'historical registry test changed')
    current_registry = (ROOT / 'test/test_core070_interface_registry.jl').read_text()
    need(registry_test_without_programme_count(historical_registry) ==
         registry_test_without_programme_count(current_registry),
         'registry test changed after baseline outside the programme case count')
    formula_files = ['test/parity/family_formula_cases.jl',
                     'test/parity/test_poisson_formula_parity.jl',
                     'test/parity/test_beta_formula_parity.jl',
                     'test/parity/test_truncnb2_formula_parity.jl']
    need(not (set(formula_files) & red_names), 'formula implementation present in red baseline')
    with tarfile.open(ROOT / '.unlazy/core070-aghq/family-formulas-03/source.tar') as first_green:
        for path in formula_files:
            member = first_green.extractfile(path)
            need(member is not None and evidence.hashlib.sha256(member.read()).hexdigest() ==
                 evidence.digest(ROOT / path), 'formula implementation changed after first green: ' + path)
    log = (STATE / 'attempt1/process/02.log').read_text()
    results = {}
    for family, case in zip(FAMILIES, contract['cases']):
        need(cases[case['id']] == case, 'master formula contract differs')
        path = folder / (family+'-formula.toml')
        need(log.splitlines().count('FAMILY_FORMULA_SHA256 '+path.name+' '+evidence.digest(path)) == 1,
             'unbound formula report')
        report = evidence.load_toml(path)
        health_name = family+'-health.toml' if family != 'truncnb2' else 'truncnb2-policy.toml'
        need(report['native_health_file'] == health_name and
             report['native_health_sha256'] == evidence.digest(folder / health_name), 'stale native health')
        health = evidence.load_toml(folder / health_name)
        check_formula(report, health, case)
        if self_test:
            for mutate in (lambda r:r.update(native_id='wrong'), lambda r:r.update(data_sha256='0'*64),
                           lambda r:r.update(reference_control_policy='default'),
                           lambda r:r['long'].update(converged=False),
                           lambda r:r['wide']['parameters'].__setitem__(0, 999.0),
                           lambda r:r['long'].update(loglik=0.0),
                           lambda r:r['input_errors'].update(missing_long='NO_ERROR')):
                bad = deepcopy(report); mutate(bad)
                try: check_formula(bad, health, case)
                except ValueError: pass
                else: raise AssertionError('accepted corrupted formula report')
        results[case['id']] = dict(native_id=report['native_id'], nfree=report['nfree'],
            data_sha256=report['data_sha256'], report_sha256=evidence.digest(path),
            native_health_sha256=report['native_health_sha256'],
            wide_native_loglik_delta=abs(report['wide']['loglik']-report['native']['loglik']),
            long_native_loglik_delta=abs(report['long']['loglik']-report['native']['loglik']))
    if self_test: print('FAMILY_FORMULA_NEGATIVES_PASS 21 formula controls plus 22 registered controls')
    print('FAMILY_FORMULAS_VERIFIED 10 cases; 9 executions; 187 assertions; public bridge still required')
    return dict(status='TEN_CASE_SUBSET_VERIFIED_NOT_FULL_FAMILY_OR_PROGRAMME',
                paired_run=result, formula_cases=results, registry_assertions=40,
                contract_sha256=evidence.digest(CONTRACT))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args(); result = verify(args.self_test)
    if args.output:
        with args.output.open('x') as handle:
            json.dump(result, handle, indent=2); handle.write('\n')
