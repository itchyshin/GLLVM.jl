"""Verify fixed-reference mode contracts, not native fitting or full parity."""
import csv,hashlib,json,math,re,tarfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq'
EVIDENCE='docs/dev-log/core070/covariance-modes-evidence.json'
IDS=['MODE-'+s+'-'+m for s in ['ORD','ANIMAL','KERNEL'] for m in ['INDEP','COMMON','DEP']]
RUNS=['covariance-modes-01','covariance-modes-points-01','covariance-modes-points-02']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return json.loads(p.read_text())
def need(v,m):
 if not v:raise ValueError(m)
def rows(p):
 with p.open() as stream:return list(csv.DictReader(stream,delimiter='\t'))
def verify_process(name,expected_exit,current):
 state=STATE/name;plan=load(state/'plan.json');proc=load(state/'attempt1/process/process-receipt.json')
 need(proc['source_unchanged'] and not proc['supervisor_error'],'stale/failed supervisor')
 need(proc['status']==('PASS' if expected_exit==0 else 'FAIL'),'unexpected process outcome')
 need(proc['plan_sha256']==sha(state/'plan.json')==sha(state/'attempt1/process/execution-plan.json'),'plan drift')
 need(proc['source_pins']==plan['pins'] and proc['environment_overrides']==plan['env'],'unbound process')
 need(plan['env']=={'OPENBLAS_NUM_THREADS':'1','OMP_NUM_THREADS':'1'},'thread contract differs')
 kind='capture' if name==RUNS[0] else 'points'
 need(proc['expected_ids']==[x['id'] for x in plan['commands']]==['oracle-before',kind,'oracle-after'],'process omitted')
 need(len(proc['results'])==3,'result omitted')
 for r,c,exit_code in zip(proc['results'],plan['commands'],[0,expected_exit,0]):
  need(r['id']==c['id'] and r['argv']==c['argv'] and r['exit_code']==exit_code and not r['supervisor_error'],'nonzero/mismatched command')
  need(sha(state/'attempt1/process'/r['log'])==r['log_sha256'],'changed process log')
 required={'tools/core070_build_oracle.py','tools/core070_targeted_run.py','test/parity/fixtures/core070_covariance_modes.R','docs/dev-log/core070/covariance-modes-leaf.md'}
 required.add('tools/core070_fit_input.R' if kind=='capture' else 'tools/core070_covariance_modes_points.R')
 if kind=='points':required.update({'inputs/'+x+'-input.rds' for x in IDS}|{'inputs/fixtures.rds'})
 need(set(plan['pins'])==required,'dependency inventory differs')
 with tarfile.open(state/'source.tar') as archive:
  members=archive.getmembers();need(len(members)==len({m.name for m in members}) and {m.name for m in members}==required|{'plan.json'},'archive inventory differs')
  for name,pin in {**plan['pins'],'plan.json':sha(state/'plan.json')}.items():
   member=archive.getmember(name);need(member.isfile(),'nonregular archived input')
   need(hashlib.sha256(archive.extractfile(member).read()).hexdigest()==pin,'archive input changed')
 for name,pin in plan['pins'].items():
  if name.startswith('inputs/'):
   path=STATE/RUNS[0]/'attempt1/out'/Path(name).name
  elif current and name!='docs/dev-log/core070/covariance-modes-leaf.md':path=ROOT/name
  # The human pre-run leaf is archive-bound; its post-run correction has no
  # execution effect. Current corrected prose is separately pinned below.
  else:continue
  need(sha(path)==pin,'source or captured input changed '+name)
 return proc

def verify_points(points,maps,output):
 need([r['id'] for r in maps]==IDS,'mode omitted or duplicated')
 need([r['id'] for r in points]==[x+'-P'+str(i) for x in IDS for i in [1,2]],'point omitted or duplicated')
 for row in maps:
  _,source,mode=row['id'].split('-');ordinary=source=='ORD';propto=source=='ANIMAL' and mode=='COMMON'
  field='theta_diag_B' if ordinary and mode!='DEP' else 'theta_rr_B' if ordinary else 'loglambda_phy' if propto else 'theta_rr_phy'
  expected_map='unmapped'
  if field=='theta_diag_B' and mode=='COMMON':expected_map='1,1,1'
  if field=='theta_rr_phy' and mode!='DEP':expected_map='1,2,3,NA,NA,NA' if mode=='INDEP' else '1,1,1,NA,NA,NA'
  need(row['field']==field and row['map']==expected_map,'mode parameter map differs')
  need(int(row['free_covariance'])=={'INDEP':3,'COMMON':1,'DEP':6}[mode] and int(row['free_residual'])==int(not(ordinary and mode!='DEP')),'free-coordinate count differs')
  need(row['random']==('s_B' if field=='theta_diag_B' else 'z_B' if ordinary else 'p_phy' if propto else 'g_phy'),'random block differs')
  need(row['transform']==('log_SD' if field=='theta_diag_B' else 'log_variance' if propto else 'raw_loadings'),'parameter scale differs')
  need(float(row['source_jitter'])==(0 if ordinary else 1e-8),'source preprocessing differs')
 for row in points:
  values={k:float(row[k]) for k in ['r_nll','dense_nll','delta','gradient_error','shifted_mean_delta']}
  need(all(math.isfinite(x) for x in values.values()),'nonfinite point')
  need(abs(abs(values['r_nll']-values['dense_nll'])-values['delta'])<1e-10,'inconsistent likelihood delta')
  need(0<=values['delta']<=1e-6 and 0<=values['gradient_error']<=1e-5 and values['shifted_mean_delta']>1e-4,'point numerical/negative check failed')
  if '-COMMON-' in row['id']:need(float(row['wrong_common_delta'])>1e-4,'wrong shared-draw control accepted')
  need(row['pass']=='TRUE','failed point promoted')
  par=rows(output/row['id']/'parameters.tsv')
  mapping=next(m for m in maps if row['id'].startswith(m['id']+'-P'))
  expected_names=['b_fix']*3+[mapping['field']]*int(mapping['free_covariance'])+['log_sigma_eps']*int(mapping['free_residual'])
  need(sorted(r['name'] for r in par)==sorted(expected_names),'retained free coordinates omitted')
  need(all(math.isfinite(float(r[k])) for r in par for k in ['value','r_gradient','dense_fd']),'nonfinite retained coordinates')
  error=max(abs(float(r['r_gradient'])-float(r['dense_fd']))/max(1,abs(float(r['r_gradient']))) for r in par)
  need(abs(error-values['gradient_error'])<1e-10,'retained gradient differs')
  source=rows(output/row['id']/'source.tsv')
  ordinary=row['id'].startswith('MODE-ORD-');dimension=18 if ordinary else 6
  headers=['X'+str(i) if ordinary else 'g'+str(i) for i in range(1,dimension+1)]
  need(len(source)==dimension and all(list(r)==headers for r in source),'retained source shape/order differs')
  for i,r in enumerate(source):
   for j,k in enumerate(headers):
    expected=(1.0 if i==j else 0.0) if ordinary else (1.0+1e-8 if i==j else 0.3)
    need(abs(float(r[k])-expected)<1e-12,'retained effective source matrix differs')

def verify():
 evidence=load(ROOT/EVIDENCE)
 need(evidence['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86' and evidence['status']=='REFERENCE_FIXED_POINTS_NATIVE_FITS_UNPAID','reference/scope changed')
 need(set(evidence['document_pins'])=={'docs/dev-log/core070/covariance-modes-leaf.md','docs/dev-log/core070/covariance-modes-contract.md'},'contract document omitted')
 need(set(evidence['reference_source_pins'])=={'R/fit-multi.R','R/brms-sugar.R','R/animal-keyword.R','R/kernel-keywords.R','src/gllvmTMB.cpp'},'reference dependency omitted')
 for path,pin in evidence['document_pins'].items():need(sha(ROOT/path)==pin,'current contract prose changed')
 for path,pin in evidence['reference_source_pins'].items():
  need(sha(ROOT/'.unlazy/core070-aghq/oracle-source/readback'/path)==pin,'reference source changed')
 need(evidence['case_ids']==IDS,'summary case inventory differs')
 mapping=load(ROOT/'docs/dev-log/core070/required-source-case-map.json')
 links={'COV-ORD-INDEP':IDS[0:1],'COV-ORD-INDEP-COMMON':IDS[1:2],'COV-ORD-DEP':IDS[2:3],
        'COV-ANIMAL-INDEP':IDS[3:5],'COV-ANIMAL-DEP':IDS[5:6],
        'COV-KERNEL-INDEP':IDS[6:8],'COV-KERNEL-DEP':IDS[8:9]}
 for source,case_ids in links.items():
  selected=[r for r in mapping['rows'] if r['source_id']=='covariance/'+source]
  need(len(selected)==1 and selected[0].get('reference_model_case_ids')==case_ids and selected[0].get('reference_model_evidence')==EVIDENCE,'reference model source link omitted')
 point_files={'observations.tsv','source.tsv','parameters.tsv','covariance.tsv','point.rds'}
 for run,case_ids in [(RUNS[1],IDS[:3]),(RUNS[2],IDS)]:
  wanted={case+'-P'+str(i)+'/'+f for case in case_ids for i in [1,2] for f in point_files}
  if run==RUNS[2]:wanted|={'maps.tsv','points.tsv'}
  out=STATE/run/'attempt1/out'
  need({str(p.relative_to(out)) for p in out.rglob('*') if p.is_file()}==wanted,'point artifact inventory differs')
 artifacts=evidence['retained_artifacts']
 expected={str(p.relative_to(STATE)) for run in RUNS for p in (STATE/run/'attempt1').rglob('*') if p.is_file()}
 expected|={run+'/'+file for run in RUNS for file in ['plan.json','source.tar','readback.tar']}
 need(set(artifacts)==expected,'missing/extra retained artifact')
 for path,pin in artifacts.items():need(sha(STATE/path)==pin,'retained artifact changed '+path)
 for name,expected_exit,current in [(RUNS[0],0,True),(RUNS[1],1,False),(RUNS[2],0,True)]:
  process=verify_process(name,expected_exit,current)
  need(evidence['elapsed_seconds'][name]==process['results'][1]['elapsed_seconds'],'summary time differs')
 capture=(STATE/RUNS[0]/'attempt1/process/01.log').read_text()
 need(re.findall(r'^(MODE-\S+)\tPREPARED\tPASS$',capture,re.M)==IDS,'capture case omitted')
 failed=(STATE/RUNS[1]/'attempt1/process/01.log').read_text()
 need('max(abs(C - fixtures$C)) < 1e-12 is not TRUE' in failed,'original failure not retained')
 output=STATE/RUNS[2]/'attempt1/out';points=rows(output/'points.tsv');maps=rows(output/'maps.tsv')
 verify_points(points,maps,output)
 log=(STATE/RUNS[2]/'attempt1/process/01.log').read_text()
 need(re.findall(r'^(MODE-\S+) delta .* PASS\s*$',log,re.M)==[r['id'] for r in points],'point log detached')
 need(evidence['maps']==maps and evidence['points']==points,'summary results differ')
 print('CORE070_COVARIANCE_MODES_CONTRACT_VERIFIED 9 models;18 fixed points; native fits/formula/bridge unpaid')
 return evidence
if __name__=='__main__':verify()
