#!/usr/bin/env python3
"""Retained no-fit Student-t admission regression in a full-package snapshot."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / '.unlazy/core070-aghq/student-input-01'
ENVIRONMENT = ROOT / '.unlazy/core070-aghq/package-qualification/attempt2'
JULIA = Path('/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia')
TEST = 'test/test_studentt_input_validation.jl'
NEIGHBOUR = 'test/test_studentt_normalizer_precision.jl'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sources():
    return {str(p.relative_to(ROOT)): sha(p) for p in sorted((ROOT/'src').rglob('*.jl'))}


def run(phase):
    destination = STATE/phase
    destination.mkdir(exist_ok=False)
    before = sources()
    shutil.copytree(ROOT/'src', destination/'src')
    shutil.copy2(ROOT/'Project.toml', destination/'Project.toml')
    shutil.copy2(ENVIRONMENT/'Manifest.toml', destination/'Manifest.toml')
    (destination/'test').mkdir()
    for name in (TEST, NEIGHBOUR):
        shutil.copy2(ROOT/name, destination/name)
    runner = destination/'run.jl'
    runner.write_text('using GLLVM, Test\n'
        '@assert realpath(pathof(GLLVM)) == realpath(joinpath(@__DIR__, "src/GLLVM.jl"))\n'
        'println("PACKAGE_PATH ", pathof(GLLVM)); println("JULIA_VERSION ", VERSION)\n'
        f'include("{TEST}")\n' +
        (f'include("{NEIGHBOUR}")\nprintln("STUDENT_INPUT_AND_SCALAR_PASS")\n' if phase == 'green' else ''))
    env = dict(os.environ, JULIA_DEPOT_PATH=str(ENVIRONMENT/'depot')+':/Users/z3437171/.julia',
        JULIA_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1', JULIA_PKG_OFFLINE='true', JULIA_PKG_PRECOMPILE_AUTO='0')
    argv = [str(JULIA), '--startup-file=no', '--project=.', 'run.jl']
    start = time.monotonic()
    timed_out = False
    with (destination/'output.log').open('wb') as log:
        try:
            result = subprocess.run(argv, cwd=destination, env=env, stdout=log,
                                    stderr=subprocess.STDOUT, timeout=60)
            code = result.returncode
        except subprocess.TimeoutExpired:
            timed_out, code = True, None
    elapsed = time.monotonic()-start
    record = dict(phase=phase, argv=argv, cwd=str(destination), exit_code=code,
        timeout=timed_out, elapsed_seconds=elapsed, sources=before,
        source_unchanged=before==sources(), tests={n:sha(ROOT/n) for n in (TEST, NEIGHBOUR)},
        runtime_sha256=sha(JULIA), manifest_sha256=sha(destination/'Manifest.toml'),
        project_sha256=sha(destination/'Project.toml'), runner_sha256=sha(runner),
        log_sha256=sha(destination/'output.log'), scope='INPUT_AND_SCALAR_ONLY_NO_FITS')
    (destination/'receipt.json').write_text(json.dumps(record, indent=2)+'\n')
    print((destination/'output.log').read_text())
    print(f'RETAINED_PHASE={phase} CHILD_EXIT={code} SECONDS={elapsed:.3f}')
    return 0 if verify_phase(phase) else 1


def verify_phase(phase):
    directory = STATE/phase
    record = json.loads((directory/'receipt.json').read_text())
    assert record['source_unchanged'] and not record['timeout']
    for name,pin in record['sources'].items():
        assert sha(directory/name)==pin, name
    for name,pin in record['tests'].items():
        assert sha(directory/name)==pin==sha(ROOT/name), name
    assert sha(directory/'output.log')==record['log_sha256']
    assert sha(directory/'run.jl')==record['runner_sha256']
    assert sha(directory/'Manifest.toml')==record['manifest_sha256']
    assert sha(directory/'Project.toml')==record['project_sha256']==sha(ROOT/'Project.toml')
    assert sha(JULIA)==record['runtime_sha256']
    output=(directory/'output.log').read_text()
    if phase=='red':
        assert record['exit_code']!=0
        assert re.search(r'Student-t fixed nu input boundary\s*\|\s*24\s+3\s+27\s+',output), output
        assert output.count('Thrown: StudentInputRead')==3,output
    else:
        assert record['exit_code']==0
        assert re.search(r'Student-t fixed nu input boundary\s*\|\s*27\s+27\s+',output),output
        assert re.search(r'Student-t density precision and outer derivatives\s*\|\s*51\s+51\s+',output),output
        assert 'STUDENT_INPUT_AND_SCALAR_PASS' in output
        assert sources()==record['sources'], 'candidate source drift'
    return True


def negative_controls():
    """Corrupt disposable evidence copies; never mutate retained run artifacts."""
    global STATE
    original = STATE
    with tempfile.TemporaryDirectory(prefix='student-input-gate-') as folder:
        disposable=Path(folder)/'evidence'
        shutil.copytree(original/'green', disposable/'green')
        STATE=disposable
        try:
            receipt=disposable/'green/receipt.json'
            baseline=receipt.read_bytes()
            cases=0
            for field,value in [('exit_code',1),('source_unchanged',False),('timeout',True)]:
                record=json.loads(baseline); record[field]=value
                receipt.write_text(json.dumps(record))
                try:verify_phase('green')
                except AssertionError:cases+=1
                else:raise AssertionError('accepted invalid '+field)
                receipt.write_bytes(baseline)
            for name in ('output.log', TEST, 'src/families/studentt.jl'):
                path=disposable/'green'/name; content=path.read_bytes()
                path.write_bytes(content+b'\n# stale evidence\n')
                try:verify_phase('green')
                except AssertionError:cases+=1
                else:raise AssertionError('accepted stale '+name)
                path.write_bytes(content)
            receipt.unlink()
            try:verify_phase('green')
            except FileNotFoundError:cases+=1
            else:raise AssertionError('accepted missing receipt')
            assert cases==7
        finally:
            STATE=original
    print('STUDENT_INPUT_GATE_NEGATIVE_CONTROLS 7 PASS')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run',choices=('red','green'))
    parser.add_argument('--verify',action='store_true')
    args=parser.parse_args()
    if args.run:
        raise SystemExit(run(args.run))
    if not args.verify:
        parser.error('use --run or --verify')
    verify_phase('red'); verify_phase('green')
    red=json.loads((STATE/'red/receipt.json').read_text())
    green=json.loads((STATE/'green/receipt.json').read_text())
    assert red['sources'].keys()==green['sources'].keys()
    assert [n for n in red['sources'] if red['sources'][n]!=green['sources'][n]]==['src/families/studentt.jl']
    negative_controls()
    print('STUDENT_FIXED_NU_INPUT_VERIFIED_NO_FITS')
