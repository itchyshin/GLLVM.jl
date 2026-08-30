#!/usr/bin/env python3
"""Replay the frozen R control subset without compiling or fitting either engine."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import time


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(manifest_path, source, destination):
    manifest_pin = sha(manifest_path)
    manifest = json.loads(manifest_path.read_text())
    cases = manifest['cases']
    ids = [row['id'] for row in cases]
    if len(set(ids)) != len(ids) or len(ids) != manifest['expected_case_count']:
        raise ValueError('missing or duplicate control case')
    if any(sha(source / name) != pin for name, pin in manifest['source_pins'].items()):
        raise ValueError('frozen R source mismatch')
    destination.mkdir(parents=True, exist_ok=False)
    # Only definitions are evaluated. No fitter, package install or scientific run.
    rcode = '''
stopifnot(requireNamespace("cli", quietly=TRUE))
env <- new.env(parent=globalenv())
load_definitions <- function(path, names) {
  found <- character()
  for (x in parse(path)) {
    if (is.call(x) && identical(x[[1]], as.name("<-")) &&
        is.symbol(x[[2]]) && as.character(x[[2]]) %in% names) {
      eval(x, env); found <- c(found, as.character(x[[2]]))
    }
  }
  stopifnot(setequal(found,names))
}
'''
    definitions = {
        'R/gllvmTMB.R': ['gllvmTMBcontrol', '.gllvmTMB_normalize_aghq'],
        'R/fit-multi.R': ['.gllvmTMB_aghq_k'],
        'R/aghq-control.R': ['.AGHQ_K_LADDER', '.AGHQ_K_FLOOR',
                            '.AGHQ_AUTO_N_TRAITS_CUTOFF', '.aghq_family_label',
                            '.aghq_start_index', '.aghq_optimizer_table',
                            '.aghq_resolve', '.aghq_auto_gate', '.aghq_auto_decide'],
    }
    for name, names in definitions.items():
        rcode += 'load_definitions(' + json.dumps(str(source / name)) + ', c(' + ','.join(map(json.dumps, names)) + '))\n'
    rcode += '''
env$gate <- data.frame(block="z_B",size=1L,n_components=10L,
                       treewidth=0L,route="quadrature",reason="test fixture")
failed <- FALSE
'''
    for row in cases:
        rcode += 'ok <- tryCatch(isTRUE(eval(parse(text=' + json.dumps(row['assertion']) + '),env)),error=function(e) FALSE)\n'
        rcode += 'cat(' + json.dumps(row['id']) + ',if(ok) "PASS" else "FAIL",sep="\\t"); cat("\\n"); failed <- failed || !ok\n'
    rcode += 'quit(status=if(failed) 1L else 0L)\n'
    script = destination / 'replay.R'
    script.write_text(rcode)
    started = time.monotonic()
    with (destination / 'raw.log').open('wb') as output:
        process = subprocess.run(['Rscript', '--vanilla', str(script)], stdout=output,
                                 stderr=subprocess.STDOUT, timeout=30)
    actual = (destination / 'raw.log').read_text().splitlines()
    fresh = sha(manifest_path) == manifest_pin and all(sha(source / name) == pin for name, pin in manifest['source_pins'].items())
    passed = process.returncode == 0 and fresh and actual == [f'{id}\tPASS' for id in ids]
    receipt = {'status': 'PASS' if passed else 'FAIL', 'scope': manifest['scope'],
               'reference_commit': manifest['reference_commit'],
               'manifest_sha256': manifest_pin, 'source_pins': manifest['source_pins'],
               'script_sha256': sha(script), 'log_sha256': sha(destination / 'raw.log'),
               'actual_exit': process.returncode, 'expected_case_ids': ids,
               'r_runtime': subprocess.check_output(['Rscript', '--version'], text=True, stderr=subprocess.STDOUT).strip(),
               'elapsed_seconds': time.monotonic() - started, 'source_unchanged': fresh}
    (destination / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print('CORE070_R_AGHQ_CONTROL_SUBSET_' + receipt['status'])
    return 0 if passed else 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', required=True, type=Path)
    parser.add_argument('--source', required=True, type=Path)
    parser.add_argument('--destination', required=True, type=Path)
    args = parser.parse_args()
    raise SystemExit(run(args.manifest.resolve(), args.source.resolve(), args.destination.resolve()))
