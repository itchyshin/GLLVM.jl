#!/usr/bin/env python3
"""Replay the frozen engine's family/link admission function without any fits."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(manifest_path, source, destination):
    manifest_hash = sha(manifest_path)
    manifest = json.loads(manifest_path.read_text())
    cases = manifest['cases']
    if len(cases) != manifest['expected_case_count'] or len({c['id'] for c in cases}) != len(cases):
        raise ValueError('missing or duplicate admission case')
    if any(sha(source / p) != v for p, v in manifest['source_pins'].items()):
        raise ValueError('frozen source mismatch')
    # Extract the named local function, not an independent rewrite of its rules.
    lines = (source / 'R/fit-multi.R').read_text().splitlines()
    starts = [i for i, line in enumerate(lines) if line == '  family_to_id <- function(f) {']
    if len(starts) != 1:
        raise ValueError('family admission source seam changed')
    start = starts[0]
    end = next(i for i in range(start+1, len(lines)) if lines[i] == '  }')
    function_text = '\n'.join(lines[start:end+1])
    destination.mkdir(parents=True, exist_ok=False)
    script = destination / 'replay.R'
    code = '''stopifnot(requireNamespace("cli", quietly=TRUE))
env <- new.env(parent=globalenv())
'''
    code += 'for(x in parse(' + json.dumps(str(source / 'R/families.R')) + ''')) {
  if (identical(x, quote(utils::globalVariables(".phi")))) next
  if (!is.call(x) || !identical(x[[1]], as.name("<-")) ||
      !is.call(x[[3]]) || !identical(x[[3]][[1]], as.name("function")))
    stop("unexpected top-level expression in frozen family source")
  eval(x, env)
}
'''
    code += 'eval(parse(text=' + json.dumps(function_text) + '), env)\nfailed <- FALSE\n'
    for case in cases:
        expression = json.dumps(case['reference_descriptor_call'])
        code += f'descriptor <- tryCatch(eval(parse(text={expression}),env),error=identity)\n'
        code += '''if(inherits(descriptor,"error")) {
  observed <- "CONSTRUCTOR_ERROR"
} else {
  answer <- tryCatch(env$family_to_id(descriptor),error=identity)
  observed <- if(inherits(answer,"error")) "ERROR" else paste(answer,collapse=",")
}
'''
        expected = case['expected']
        expected = ','.join(map(str, expected)) if isinstance(expected, list) else expected
        code += f'ok <- identical(observed,{json.dumps(expected)})\n'
        code += 'cat(' + json.dumps(case['id']) + ',observed,if(ok) "PASS" else "FAIL",sep="\\t");cat("\\n");failed <- failed || !ok\n'
    code += 'quit(status=if(failed) 1L else 0L)\n'
    script.write_text(code)
    with (destination / 'raw.tsv').open('wb') as output, (destination / 'diagnostics.log').open('wb') as diagnostics:
        child = subprocess.run(['Rscript','--vanilla',str(script)],stdout=output,
                               stderr=diagnostics,timeout=30)
    rows = (destination / 'raw.tsv').read_text().splitlines()
    expected_rows = [c['id']+'\t'+(','.join(map(str,c['expected'])) if isinstance(c['expected'],list) else c['expected'])+'\tPASS' for c in cases]
    fresh = sha(manifest_path) == manifest_hash and all(sha(source/p)==v for p,v in manifest['source_pins'].items())
    passed = child.returncode == 0 and rows == expected_rows and fresh
    receipt = dict(status='PASS' if passed else 'FAIL', scope=manifest['status'],
                   reference_commit=manifest['reference_commit'],actual_exit=child.returncode,
                   manifest_sha256=manifest_hash,source_pins=manifest['source_pins'],
                   extracted_function_lines=[start+1,end+1],script_sha256=sha(script),
                   raw_sha256=sha(destination/'raw.tsv'),diagnostics_sha256=sha(destination/'diagnostics.log'),source_unchanged=fresh,
                   expected_case_ids=[c['id'] for c in cases],
                   r_runtime=subprocess.check_output(['Rscript','--version'],text=True,stderr=subprocess.STDOUT).strip())
    (destination/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print('CORE070_R_FAMILY_ADMISSION_'+receipt['status'])
    return 0 if passed else 1


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--manifest',type=Path,required=True)
    p.add_argument('--source',type=Path,required=True)
    p.add_argument('--destination',type=Path,required=True)
    a=p.parse_args()
    raise SystemExit(run(a.manifest.resolve(),a.source.resolve(),a.destination.resolve()))
