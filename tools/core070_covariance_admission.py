#!/usr/bin/env python3
"""Replay pinned R covariance grammar and modifier functions, without fitting models."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

FUNCTIONS = {'R/brms-sugar.R': ['.gllvmTMB_warn_keyword_deprecated', '.gllvmTMB_warn_unique_family_deprecated', '.gllvmTMB_warn_scalar_family_deprecated', '.gllvmTMB_warn_start_method_res_deprecated', '.gllvmTMB_warn_latent_default_psi', '.gllvmTMB_warn_latent_residual_alias', 'phylo', 'phylo_rr', 'gr', 'meta', 'latent', 'phylo_latent', 'phylo_slope', 'phylo_scalar', 'phylo_unique', 'spatial_unique', 'spatial_scalar', 'spatial_latent', 'spatial', 'meta_known_V', 'meta_V', 'indep', 'scalar', 'phylo_indep', 'spatial_indep', 'dep', 'phylo_dep', 'spatial_dep', '.strip_lhs_parens', '.is_one_lhs', '.is_zero_plus_trait', '.flatten_lhs_plus', '.assert_distinct_slope_cols', '.match_wide_intercept_slopes', '.match_long_intercept_slopes', '.gllvmTMB_lhs_form', '.gllvmTMB_lhs_form_multi', '.gllvmTMB_column_slope_cols', '.gllvmTMB_column_slope_helper_cols', '.assert_no_augmented_lhs', 'normalise_spatial_orientation', 'rewrite_canonical_aliases', 'scan_for_deprecated', 'desugar_brms_sugar'], 'R/parse-multi-formula.R': ['.gllvmTMB_formula_function_heads', '.gllvmTMB_reject_unsupported_formula_helpers', 'parse_multi_formula', 'parse_covstruct_call', 'parse_re_int_call'], 'R/missing-predictor.R': ['gll_find_mi_calls'], 'R/fit-multi.R': ['.augmented_slope_family_contract', '.augmented_slope_family_allowed']}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(manifest_path, source, root, destination):
    manifest_hash = sha(manifest_path)
    m = json.loads(manifest_path.read_text())
    cases = m['cases']
    if m['reference_commit'] != 'b4d5fee64def88bc768dda1f1f77c29b295edd86':
        raise ValueError('wrong frozen reference commit')
    if not cases or len(cases) != m['expected_case_count'] or len({c['id'] for c in cases}) != len(cases):
        raise ValueError('omitted or duplicate case')
    if set(m['source_pins']) != set(FUNCTIONS) or any(sha(source/p) != pin for p,pin in m['source_pins'].items()):
        raise ValueError('stale frozen source')
    fixture = root / m['fixture']
    if sha(fixture) != m['fixture_sha256']:
        raise ValueError('stale fixture')
    for case in cases:
        if case['expected'] not in ('TRUE','ERROR') or (case['expected']=='ERROR' and not case.get('error_contains')):
            raise ValueError('error cases require a specific expected diagnostic')
    destination.mkdir(parents=True,exist_ok=False)
    (destination/'manifest.json').write_bytes(manifest_path.read_bytes())
    retained = destination/'reference-fixture.R'; retained.write_bytes(fixture.read_bytes())
    code = 'stopifnot(requireNamespace("cli",quietly=TRUE))\nenv <- new.env(parent=globalenv())\n'
    for rel, names in FUNCTIONS.items():
        code += 'wanted <- c(' + ','.join(json.dumps(n) for n in names) + ')\nloaded <- character()\n'
        code += 'for(x in parse(' + json.dumps(str(source/rel)) + ''')) {
  if (!is.call(x) || !identical(x[[1]],as.name("<-"))) next
  name <- as.character(x[[2]])
  if (length(name)!=1L || !name %in% wanted) next
  stopifnot(is.call(x[[3]]),identical(x[[3]][[1]],as.name("function")),!name %in% loaded)
  eval(x,env); loaded <- c(loaded,name)
}
stopifnot(setequal(wanted,loaded))
'''
    code += 'constants <- Filter(function(x) is.call(x) && identical(x[[1]],as.name("<-")) && identical(x[[2]],as.name(".gllvmTMB_deprecation_seen")), parse(' + json.dumps(str(source/'R/brms-sugar.R')) + '))\n'
    code += 'stopifnot(length(constants)==1L,identical(constants[[1]][[3]],quote(new.env(parent=emptyenv()))));eval(constants[[1]],env)\n'
    code += 'sys.source(' + json.dumps(str(retained)) + ',envir=env)\nfailed <- FALSE\n'
    for case in cases:
        # Isolate case-local assignments so no previous case can repair a later one.
        code += 'result <- tryCatch(eval(parse(text=' + json.dumps(case['expression']) + '),new.env(parent=env)),error=identity)\n'
        if case['expected']=='ERROR':
            code += 'ok <- inherits(result,"error") && grepl(' + json.dumps(case['error_contains']) + ',gsub("[[:space:]]+"," ",conditionMessage(result)),fixed=TRUE)\n'
        else:
            code += 'ok <- isTRUE(result)\n'
        code += 'if(inherits(result,"error")) cat(' + json.dumps(case['id']+': ') + ',conditionMessage(result),"\\n",file=stderr())\n'
        code += 'cat(' + json.dumps(case['id']) + ',if(ok) "PASS" else "FAIL",sep="\\t");cat("\\n");failed <- failed || !ok\n'
    code += 'quit(status=if(failed) 1L else 0L)\n'
    script=destination/'replay.R'; script.write_text(code)
    with (destination/'raw.tsv').open('wb') as out, (destination/'diagnostics.log').open('wb') as err:
        try:
            child=subprocess.run(['Rscript','--vanilla',str(script)],stdout=out,stderr=err,timeout=30)
            exit_code=child.returncode
        except subprocess.TimeoutExpired:
            exit_code=124; err.write(b'R source replay timed out\n')
        except OSError as exc:
            exit_code=127; err.write(str(exc).encode())
    rows=(destination/'raw.tsv').read_text().splitlines()
    fresh=sha(manifest_path)==manifest_hash and sha(fixture)==m['fixture_sha256'] and all(sha(source/p)==pin for p,pin in m['source_pins'].items())
    passed=exit_code==0 and rows==[c['id']+'\tPASS' for c in cases] and fresh
    receipt=dict(status='PASS' if passed else 'FAIL',scope=m['status'],reference_commit=m['reference_commit'],
        actual_exit=exit_code,expected_case_ids=[c['id'] for c in cases],manifest_sha256=manifest_hash,
        fixture_sha256=m['fixture_sha256'],source_pins=m['source_pins'],source_unchanged=fresh,
        script_sha256=sha(script),raw_sha256=sha(destination/'raw.tsv'),diagnostics_sha256=sha(destination/'diagnostics.log'))
    try:
        receipt['r_runtime']=subprocess.check_output(['Rscript','--version'],text=True,stderr=subprocess.STDOUT,timeout=10).strip()
    except (OSError,subprocess.SubprocessError):
        receipt['r_runtime']='UNAVAILABLE';receipt['status']='FAIL';passed=False
    (destination/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print('CORE070_COVARIANCE_ADMISSION_'+receipt['status'])
    return 0 if passed else 1


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('manifest','source','root','destination'):p.add_argument('--'+name,type=Path,required=True)
    a=p.parse_args()
    raise SystemExit(run(a.manifest.resolve(),a.source.resolve(),a.root.resolve(),a.destination.resolve()))
