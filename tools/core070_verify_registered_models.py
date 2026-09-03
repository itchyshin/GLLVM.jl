"""Current seven-case replay, with original models and control policies retained.

This verifies a declared executable subset while the programme contract is draft.
It does not call the full-programme verifier with a fabricated frozen status.
"""
import argparse
from copy import deepcopy
import json
from pathlib import Path
import struct
import subprocess

import core070_evidence as evidence
from core070_manifest_coverage import need
from core070_verify_gaussian_required import check_semantics as gaussian_checks, IDS as GAUSSIAN_IDS, MANIFEST
from core070_verify_poisson_beta_health import checks as pb_checks
from core070_verify_nb2_health import checks as nb2_checks
from core070_verify_nb2_formula import formula_checks
from core070_verify_truncnb2_required import check_policy, negatives as trunc_negatives

ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/registered-models-01'
IDS=['NATIVE-03-POISSON','NATIVE-06-NB2','NATIVE-08-BETA','NATIVE-12-TRUNCATED-NB2',
     'CORE070-FAMILY-05-LOG-FORMULA-INTERFACE',*GAUSSIAN_IDS]
COUNTS=dict(zip(IDS,[16,18,16,21,19,31,31]))
sha=evidence.digest
read=evidence.load_toml

def assertion_total():
    return sum(COUNTS[cid] for cid in IDS) - COUNTS[GAUSSIAN_IDS[0]]



def check_run(run,cells,cases,execution):
    need(run['status']=='success' and run['exit_code']==0 and run['success_marker']=='CORE070_PARITY_SUCCESS','failed run')
    need(run['requested_case_ids']==IDS and run['completed_case_ids']==sorted(IDS),'missing/changed cases')
    need(run['scope']=='subset' and run['selected_family_count']==4,'false scope')
    need(run['execution']==execution,'execution source/fixture/runtime changed')
    pin=sha(evidence.DEFAULT_MANIFEST)
    need(run['contract_sha256']==pin,'contract changed')
    need(set(cells)==set(IDS) and run['cells']==cells,'omitted/mismatched cell')
    need(run['assertion_counting']=='execution_groups_v1','missing assertion accounting schema')
    for cid,cell in cells.items():
        need(cell['id']==cid and cell['run_id']==run['run_id'] and cell['status']=='success','transplanted cell')
        need(cell['fixture']==cases[cid]['fixture'] and
             cell['fixture_sha256']==cases[cid]['fixture_sha256']==sha(ROOT/cell['fixture']),'stale case fixture')
        group=GAUSSIAN_IDS if cid in GAUSSIAN_IDS else [cid]
        need(sorted(cell['execution_case_ids'])==sorted(group),'wrong execution group')
        need(cell['assertions']==dict(passed=COUNTS[cid],failed=0,errored=0,broken=0),'case assertions failed/changed')
        need(cell['contract_sha256']==pin and cell['execution_manifest_sha256']==execution['manifest_sha256'],'cell provenance changed')
    need(evidence.execution_assertion_counts(cells)==dict(passed=assertion_total(),failed=0,errored=0,broken=0)
         and run['actual_assertions']==assertion_total(),'assertion totals inflated/incomplete')


def raw_values(path,code,expected):
    result=subprocess.run(['Rscript','--vanilla','-e',code,str(path)],text=True,capture_output=True,timeout=20)
    need(result.returncode==0,'raw fit readback failed: '+result.stderr)
    need(list(map(float,result.stdout.split()))==expected,'raw fit/report values differ')


def verify(self_test=False):
    folder=STATE/'attempt1/receipts'
    run,cells=evidence._load_receipts(folder)
    manifest=evidence.load_manifest(evidence.DEFAULT_MANIFEST)
    need(manifest['status']=='DRAFT_INCOMPLETE_NOT_FROZEN','no programme promotion')
    cases={c['id']:c for c in manifest['executable_case']}
    need(set(IDS)<=set(cases),'required executable definitions missing')
    contracts=json.loads((ROOT/'docs/dev-log/core070/registered-models-contract.json').read_text())
    need(contracts['reference_commit']==manifest['reference_commit'],'stale model source')
    for row in contracts['cases']:need(cases[row['id']]==row,'master/source model contract differs')
    execution=evidence.execution_inventory(cases,IDS,evidence.DEFAULT_MANIFEST)
    entries=execution['entries']+[dict(path='test/parity/Manifest.toml',sha256=sha(MANIFEST))]
    entries.sort(key=lambda r:r['path'])
    execution=dict(entries=entries,manifest_sha256=evidence._hash_inventory(entries))
    check_run(run,cells,cases,execution)
    evidence._validate_source(run['source'],manifest,execution,folder)
    need(run['source']['julia_threads']==run['source']['blas_threads']==1,'thread budget changed')
    process_path=STATE/'attempt1/process/process-receipt.json'
    evidence.verify_process(folder,process_path,execution)
    process=json.loads(process_path.read_text());plan=json.loads((STATE/'plan.json').read_text())
    need(process['plan_sha256']==sha(STATE/'plan.json') and process['environment_overrides']==plan['env'],'local plan/environment changed')
    need(plan['env']['CORE070_PARITY_CASE_IDS']==','.join(IDS)
         and plan['env']['CORE070_PARITY_REQUIRED']==plan['env']['GLLVM_PARITY_TESTS']=='1','wrong/optional requested run')
    need([row['id'] for row in process['results']]==['oracle-before','registry','pair','oracle-after'],'missing runtime/oracle checks')
    child=next(r for r in process['results'] if r['id']=='pair')
    need(child['argv'][-1]=='test/parity/runparity.jl','not the required runner')
    log=(process_path.parent/child['log']).read_text()
    def bound(name,marker):
        path=folder/name
        need(log.splitlines().count(marker+' '+sha(path))==1,'unbound numerical output: '+name)
        return path
    gaussian=[]
    for name in ['gaussian-native.toml','gaussian-formula.toml','gaussian-long.toml']:
        gaussian.append(read(bound(name,'GAUSSIAN_ARTIFACT_SHA256 '+name)))
    gaussian_checks(*gaussian)
    reports={}
    for family,cid in [('poisson','NATIVE-03-POISSON'),('beta','NATIVE-08-BETA')]:
        r=read(bound(family+'-health.toml',family.upper()+'_HEALTH_SHA256'))
        raw=bound(family+'-whole-fit.rds',family.upper()+'_RAW_FITS_SHA256')
        # Poisson/Beta metrics inherit source provenance from their hashed supervised log.
        need(r['id']==cid,'wrong family report')
        need(r['policy']==cases[cid]['reference_control_policy']=='public_start_from_refinement_v1','changed refinement policy')
        need(r['data_sha256']==cases[cid]['data_sha256'],'changed original data')
        need(sha(raw)==r['raw_fits_sha256'],'raw R fit changed')
        need(r['checks']==pb_checks(r) and all(pb_checks(r).values()),'Poisson/Beta health failed')
        f=read(folder/(family+'-fixture.toml'))
        need(sha(folder/(family+'-fixture.toml'))==r['fixture_sha256'],'retained data report changed')
        need(evidence.hashlib.sha256(struct.pack('<300d',*f['Y_column_major'])).hexdigest()==r['data_sha256'],'realized data hash differs')
        code='x<-readRDS(commandArgs(TRUE)[1]);stopifnot(identical(x$data,x$original_data),identical(x$map,x$original_map),identical(names(x$opt$par),names(x$original_opt$par)));for(v in list(x$opt$par,x$gradient,x$opt$convergence,x$objective,x$original_opt$par,x$original_gradient,x$original_opt$convergence,x$original_opt$objective))cat(sprintf("%.17g",v),sep="\\n")'
        raw_values(raw,code,r['r_parameters']+r['r_gradient']+[r['r_code'],r['r_objective']]+r['original_r_parameters']+r['original_r_gradient']+[r['original_r_code'],r['original_r_objective']])
        reports[cid]=r
    for prefix,cid,tag in [('nb2','NATIVE-06-NB2','NB2'),('formula-nb2','CORE070-FAMILY-05-LOG-FORMULA-INTERFACE','FORMULA')]:
        r=read(bound(prefix+'-health.toml',tag+'_HEALTH_SHA256'))
        raw=bound(prefix+'-whole-fit.rds',tag+'_RAW_FITS_SHA256')
        need(r['case_id']==cid and r['source']==run['source'],'NB2 case/source differs')
        need(r['policy']==cases[cid]['reference_control_policy']=='nb2_original_default_v1','NB2 policy differs')
        need(r['data_sha256']==cases[cid]['data_sha256'] and sha(raw)==r['raw_fits_sha256'],'NB2 data/raw differs')
        need(all(nb2_checks(r).values()),'NB2 health failed')
        code='x<-readRDS(commandArgs(TRUE)[1]);for(v in list(x$opt$par,x$gradient,x$opt$convergence,x$objective))cat(sprintf("%.17g",v),sep="\\n")'
        raw_values(raw,code,r['r_parameters']+r['r_gradient']+[r['r_code'],r['r_objective']])
        reports[cid]=r
    formula=read(bound('nb2-formula.toml','NB2_FORMULA_SHA256'))
    need(formula['native_health_sha256']==sha(folder/'formula-nb2-health.toml'),'formula health output differs')
    formula_checks(formula,reports['CORE070-FAMILY-05-LOG-FORMULA-INTERFACE'],True)
    trunc=read(bound('truncnb2-policy.toml','TRUNCNB2_POLICY_SHA256'))
    raw=bound('truncnb2-whole-fits.rds','TRUNCNB2_RAW_FITS_SHA256')
    need(sha(raw)==trunc['raw_fits_sha256'],'truncated-NB2 raw fit differs')
    check_policy(trunc)
    need(trunc['policy']==cases['NATIVE-12-TRUNCATED-NB2']['reference_control_policy'],'truncated-NB2 controls differ')
    code='x<-readRDS(commandArgs(TRUE)[1]);stopifnot(identical(x$original_data,x$final_data),identical(x$original_map,x$final_map),identical(names(x$original_opt$par),names(x$final_opt$par)));for(v in list(x$original_opt$par,x$final_opt$par,x$original_gradient,x$final_gradient,x$original_opt$convergence,x$final_opt$convergence))cat(sprintf("%.17g",v),sep="\\n")'
    raw_values(raw,code,trunc['original_r_parameters']+trunc['r_parameters']+trunc['original_r_gradient']+trunc['r_gradient']+[trunc['original_r_code'],trunc['r_code']])
    reports['NATIVE-12-TRUNCATED-NB2']=trunc
    if self_test:
        trunc_negatives(trunc)
        count=10
        for change in [lambda r:r['completed_case_ids'].pop(),lambda r:r.update(exit_code=7),
                       lambda r:r.update(contract_sha256='0'*64),lambda r:r.update(actual_assertions=152),
                       lambda r:r['cells'][IDS[0]]['assertions'].update(failed=1)]:
            bad=deepcopy(run);change(bad)
            try:check_run(bad,bad['cells'],cases,execution)
            except (ValueError,evidence.EvidenceError):count+=1
            else:raise AssertionError('accepted corrupted run')
        for cid,checker in [('NATIVE-03-POISSON',pb_checks),('NATIVE-08-BETA',pb_checks),('NATIVE-06-NB2',nb2_checks)]:
            for key,value in [('native_converged',False),('r_gradient_max',1.0)]:
                bad=deepcopy(reports[cid]);bad[key]=value
                try:accepted=all(checker(bad).values())
                except AssertionError:accepted=False
                need(not accepted,'accepted corrupted health');count+=1
        bad=deepcopy(formula);bad['long_loglik']=0.0
        try:formula_checks(bad,reports['CORE070-FAMILY-05-LOG-FORMULA-INTERFACE'],True)
        except AssertionError:count+=1
        else:raise AssertionError('accepted changed formula fit')
        print('REGISTERED_MODELS_NEGATIVES_PASS',count)
    print(f'REGISTERED_MODELS_REQUIRED_VERIFIED {len(IDS)} cases; {len(IDS)-1} executions; {assertion_total()} assertions; no complete-family claim')
    summaries={cid:dict(loglik_delta=abs(r['native_loglik']-r['r_loglik']),native_gradient_max=r['native_gradient_max'],r_gradient_max=r['r_gradient_max']) for cid,r in reports.items()}
    summaries['Gaussian native/formula']=dict(loglik_delta=gaussian[0]['delta_loglik'],native_gradient_max=gaussian[0]['native_gradient_max'],r_gradient_max=gaussian[0]['r_gradient_max'])
    return dict(status='VERIFIED_REGISTERED_SUBSET_NOT_FULL_FAMILY_OR_PROGRAMME',case_ids=IDS,actual_assertions=assertion_total(),executions=len(IDS)-1,elapsed_seconds=child['elapsed_seconds'],models=summaries,execution_manifest_sha256=execution['manifest_sha256'],contract_sha256=sha(evidence.DEFAULT_MANIFEST),process_receipt_sha256=sha(process_path),run_sha256=sha(folder/'run.toml'),reference_commit=manifest['reference_commit'])


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test',action='store_true');parser.add_argument('--output',type=Path)
    args=parser.parse_args();result=verify(args.self_test)
    if args.output:
        with args.output.open('x') as handle:json.dump(result,handle,indent=2);handle.write('\n')
