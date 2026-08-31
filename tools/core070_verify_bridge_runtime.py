"""Verify only public bridge runtime qualification, never model parity."""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / '.unlazy/core070-aghq/public-bridge-runtime-04'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def need(value, message):
    if not value:
        raise ValueError(message)

def check(process, plan, receipt, before, after, log):
    need(process['status'] == 'PASS' and process['source_unchanged'] is True,
         'failed or changed process')
    need(process['supervisor_error'] is None, 'supervisor error')
    need(process['source_pins'] == plan['pins'] and process['environment_overrides'] == plan['env'],
         'process provenance mismatch')
    need(process['expected_ids'] == ['oracle-before', 'runtime', 'oracle-after'], 'wrong batch')
    need([r['id'] for r in process['results']] == process['expected_ids'], 'missing command')
    for actual, declared in zip(process['results'], plan['commands']):
        need(actual['exit_code'] == 0 and actual['supervisor_error'] is None and
             actual['argv'] == declared['argv'], 'failed or substituted command')
    need(plan['commands'][1]['argv'] == ['Rscript', '--vanilla', 'tools/core070_bridge_runtime.R'],
         'wrong runtime test')
    need(receipt['Julia'] == '1.12.6' and receipt['JuliaCall'] == '0.17.6', 'different runtime')
    need(receipt['R'] == 'R version 4.5.3 (2026-03-11)', 'different R runtime')
    need(receipt['JuliaCall_path'] == '/home/snakagaw/R/v07-lib/JuliaCall', 'wrong JuliaCall')
    need(receipt['gllvmTMB_path'] == '/home/snakagaw/core070-aghq-20260830/oracle-build-01/library/gllvmTMB',
         'wrong oracle')
    need(receipt['active_project'] == plan['cwd'] + '/test/parity/Project.toml' and
         receipt['GLLVM_source'] == plan['cwd'] + '/src/GLLVM.jl', 'wrong loaded candidate')
    need(receipt['roundtrip'] == 6 and receipt['julia_threads'] == receipt['blas_threads'] == 1,
         'roundtrip or thread failure')
    need(receipt['child_preload_environment'] == '' and
         receipt['parent_preload'] == plan['env']['LD_PRELOAD'], 'preload contract changed')
    need('CORE070_EXPECTED_RUNTIME_ERROR' in receipt['expected_error'], 'missing exception test')
    need(before == after and len(before) > 10, 'dependencies missing or changed')
    for suffix in ['/DESCRIPTION', '/R/JuliaCall.rdb', '/R/JuliaCall.rdx']:
        need(receipt['JuliaCall_path'] + suffix in before, 'missing installed package bytes')
    need(receipt['parent_preload'] in before and plan['env']['JULIA_HOME'] + '/julia' in before,
         'missing Julia or libunwind binary')
    # Bind every scalar in the JSON to the checksum-bound R console receipt.
    for key, value in receipt.items():
        if key == 'libPaths':
            continue
        printed = json.dumps(value) if isinstance(value, str) else str(value)
        need('$' + key + '\n[1] ' + printed + '\n' in log, 'unbound receipt field: ' + key)
    need(log.count('CORE070_PUBLIC_BRIDGE_RUNTIME_PASS') == 1, 'missing runtime success')

def verify(self_test=False):
    folder = STATE / 'attempt1'
    process = json.loads((folder / 'process/process-receipt.json').read_text())
    plan = json.loads((STATE / 'plan.json').read_text())
    receipt = json.loads((folder / 'bridge-runtime.json').read_text())
    before_path = folder / 'bridge-runtime-dependencies-before.json'
    after_path = folder / 'bridge-runtime-dependencies-after.json'
    before, after = [json.loads(p.read_text()) for p in [before_path, after_path]]
    need(process['plan_sha256'] == sha(STATE / 'plan.json'), 'plan changed')
    for row in process['results']:
        need(sha(folder / 'process' / row['log']) == row['log_sha256'], 'log changed')
    log = (folder / 'process/01.log').read_text()
    for p in [before_path, after_path]:
        need(sha(p) == receipt['dependencies_sha256'] and
             'BRIDGE_DEPENDENCY_SHA256 ' + p.name + ' ' + sha(p) in log, 'unbound dependencies')
    need(all(plan['pins'].get(str(p.relative_to(ROOT))) == sha(p)
             for p in (ROOT / 'src').rglob('*.jl')), 'candidate source changed or omitted')
    for name in ['tools/core070_bridge_runtime.R', 'tools/core070_bridge_dependencies.py', 'Project.toml']:
        need(plan['pins'].get(name) == sha(ROOT / name), 'runtime source changed')
    check(process, plan, receipt, before, after, log)
    negatives = [lambda p,r,b,a: p.update(status='FAIL'),
                 lambda p,r,b,a: p['results'].pop(),
                 lambda p,r,b,a: p['results'][1].update(exit_code=1),
                 lambda p,r,b,a: p.update(source_unchanged=False),
                 lambda p,r,b,a: r.update(roundtrip=7),
                 lambda p,r,b,a: r.update(GLLVM_source='/wrong/src/GLLVM.jl'),
                 lambda p,r,b,a: r.update(julia_threads=2),
                 lambda p,r,b,a: r.update(expected_error='NO_ERROR'),
                 lambda p,r,b,a: a.pop(next(iter(a))),
                 lambda p,r,b,a: b.clear()]
    if self_test:
        for mutate in negatives:
            p,r,b,a = deepcopy((process, receipt, before, after)); mutate(p,r,b,a)
            try:
                check(p, plan, r, b, a, log)
            except ValueError:
                continue
            raise AssertionError('accepted invalid runtime receipt')
        print('BRIDGE_RUNTIME_NEGATIVES_PASS', len(negatives))
    result = dict(status='RUNTIME_ONLY_VERIFIED_NOT_MODEL_PARITY',
                  runtime_seconds=process['results'][1]['elapsed_seconds'],
                  dependency_files=len(before), dependency_manifest_sha256=sha(before_path),
                  process_sha256=sha(folder / 'process/process-receipt.json'),
                  receipt_sha256=sha(folder / 'bridge-runtime.json'),
                  runtime=receipt, negative_controls=len(negatives) if self_test else 0)
    print('BRIDGE_RUNTIME_VERIFIED')
    return result

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = verify(args.self_test)
    if args.output:
        with args.output.open('x') as handle:
            json.dump(result, handle, indent=2); handle.write('\n')
