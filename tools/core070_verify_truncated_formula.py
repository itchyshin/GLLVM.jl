"""Verify the explicit truncated-NB2 route, its regression and pinned R replay.

This is a scoped interface checkpoint, not full-family or programme acceptance.
"""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import re

import core070_verify_registered_models as registered

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / '.unlazy/core070-aghq'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def need(condition, message):
    if not condition:
        raise ValueError(message)


def check_receipt(receipt, plan, expected_status, expected_exit):
    need(receipt['status'] == expected_status, 'unexpected batch status')
    need(receipt['source_unchanged'] and receipt['supervisor_error'] is None,
         'source changed or supervisor failed')
    need(receipt['source_pins'] == plan['pins'], 'receipt/plan pins differ')
    need(receipt['environment_overrides'] == plan['env'], 'environment differs')
    need(len(receipt['results']) == len(plan['commands']) == 1, 'missing/extra commands')
    result = receipt['results'][0]
    need(result['argv'] == plan['commands'][0]['argv'], 'command differs')
    need(result['exit_code'] == expected_exit and result['supervisor_error'] is None,
         'unexpected command exit')
    need(result['elapsed_seconds'] < plan['commands'][0]['timeout_seconds'], 'timeout')


def process(name, status='PASS', exit_code=0, current=True):
    directory = STATE / name
    plan = json.loads((directory / 'plan.json').read_text())
    receipt_path = directory / 'attempt1/process/process-receipt.json'
    receipt = json.loads(receipt_path.read_text())
    need(receipt['plan_sha256'] == sha(directory / 'plan.json'), 'plan changed')
    check_receipt(receipt, plan, status, exit_code)
    result = receipt['results'][0]
    log_path = receipt_path.parent / result['log']
    need(sha(log_path) == result['log_sha256'], 'log changed')
    if current:
        for path, pin in plan['pins'].items():
            if path.startswith(('src/', 'docs/src/')) or path in (
                'Project.toml', 'test/test_truncated_formula.jl', 'test/runtests.jl',
                'docs/make.jl', 'docs/Project.toml', 'README.md', 'CHANGELOG.md'):
                need(sha(ROOT / path) == pin, 'stale input: ' + path)
    return plan, receipt, log_path.read_text()


def verify(self_test=False):
    red, red_receipt, red_log = process('truncated-formula-red-02', 'FAIL', 1, False)
    green, green_receipt, green_log = process('truncated-formula-green-01')
    docs, docs_receipt, docs_log = process('truncated-formula-docs-02')
    _, neighbours, neighbour_log = process('truncated-formula-neighbours-01')
    for label, count in [('fit_gllvm — unified family dispatch', 11),
                         ('fit_gllvm unified API — keyword routing', 24)]:
        need(re.search(re.escape(label) + rf'\s*\|\s*{count}\s+{count}', neighbour_log),
             'neighbour regression omitted or failed')
    test = 'test/test_truncated_formula.jl'
    need(red['pins'][test] == green['pins'][test], 'regression changed after baseline')
    need('disp_group (grouped dispersion) is not supported for family TruncatedNegBin2' in red_log,
         'baseline did not expose missing dispatch')
    need('UndefVarError' not in red_log, 'setup failure is not a dispatch regression')
    need(re.search(r'Truncated NB2 explicit per-trait dispatch and formulas\s*\|\s*29\s+29', green_log),
         'missing 29 passing assertions')
    changed = [path for path, pin in red['pins'].items()
               if path.startswith('src/') and green['pins'].get(path) != pin]
    need(changed == ['src/families/fit_gllvm.jl'], 'likelihood changed alongside dispatch')
    need('test_truncated_formula.jl' in (ROOT / 'test/runtests.jl').read_text(),
         'regression omitted from core suite')
    fixture = (ROOT / 'test/parity/test_truncated_nbinom2_parity.jl').read_text()
    start = fixture.index('    Random.seed!(_TNB2_SEED)')
    stop = fixture.index('    @testset "support', start)
    block = '\n'.join(line[4:] if line.startswith('    ') else line
                      for line in fixture[start:stop].splitlines())
    need(block in (ROOT / test).read_text(), 'original DGP drifted')
    need('```@example truncated_nb2_dispatch' in (ROOT / 'docs/src/response-families.md').read_text(),
         'example no longer executed')
    registered.STATE = STATE / 'truncated-formula-pair-01'
    pair = registered.verify(self_test)
    if self_test:
        for change in (lambda r: r.update(source_unchanged=False),
                       lambda r: r['results'][0].update(exit_code=1),
                       lambda r: r['results'].clear(),
                       lambda r: r.update(source_pins={}),
                       lambda r: r.update(environment_overrides={})):
            bad = deepcopy(green_receipt)
            change(bad)
            try:
                check_receipt(bad, green, 'PASS', 0)
            except ValueError:
                pass
            else:
                raise AssertionError('accepted corrupted unit receipt')
        print('TRUNCATED_FORMULA_NEGATIVES_PASS 5 process controls plus 22 registered controls')
    result = dict(status='SCOPED_INTERFACE_VERIFIED_FULL_SUITES_AND_REVIEW_PENDING',
                  unit_assertions=29, paired_registered_cases=pair,
                  baseline_seconds=red_receipt['results'][0]['elapsed_seconds'],
                  candidate_seconds=green_receipt['results'][0]['elapsed_seconds'],
                  docs_seconds=docs_receipt['results'][0]['elapsed_seconds'],
                  neighbour_assertions=35,
                  neighbour_seconds=neighbours['results'][0]['elapsed_seconds'],
                  test_sha256=green['pins'][test],
                  dispatch_sha256=green['pins']['src/families/fit_gllvm.jl'],
                  docs_receipt_sha256=sha(STATE / 'truncated-formula-docs-02/attempt1/process/process-receipt.json'),
                  unit_receipt_sha256=sha(STATE / 'truncated-formula-green-01/attempt1/process/process-receipt.json'))
    print('TRUNCATED_FORMULA_VERIFIED 29 assertions; shared default preserved; no full-family claim')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = verify(args.self_test)
    if args.output:
        with args.output.open('x') as handle:
            json.dump(result, handle, indent=2)
            handle.write('\n')
