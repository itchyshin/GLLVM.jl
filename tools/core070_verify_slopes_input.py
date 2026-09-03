"""Verify random-slope preparation contracts, not native fitting or full parity."""
import csv,hashlib,json,math,re,tarfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq'
EVIDENCE='docs/dev-log/core070/slopes-input-evidence.json'
ANNEX='docs/dev-log/core070/slopes-required-case-plan.json'
RUNS=['slopes-input-01','slopes-input-02','slopes-input-03']
IDS=['SLOPE-'+x for x in ['ORD-LAT-DEFAULT','ORD-LAT-NOUNIQUE','ORD-LAT-RANK4','ORD-LAT-RANK7','ORD-INDEP-BAR','ORD-INDEP-DBAR','ORD-DEP-BAR','ORD-DEP-DBAR','ANIMAL-INDEP-BAR','ANIMAL-INDEP-DBAR','ANIMAL-DEP-BAR','ANIMAL-DEP-DBAR','ANIMAL-LAT-NOUNIQUE','ANIMAL-LAT-DEFAULT','ANIMAL-DEP-MULTIGAUSS','ANIMAL-DEP-MULTIPOIS','ORD-LAT-POISDEFAULT','ORD-LAT-POISNOUNIQUE','ORD-LAT-COMBINE','ANIMAL-LAT-RANK4','PHYLO-DEP-MULTIGAUSS','PHYLO-DEP-MULTIPOIS']]
REJECT={IDS[i] for i in [3,4,5,6,7,18,19,21]}
MISROUTE={IDS[14],IDS[15]}
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
 kind='capture'
 need(proc['expected_ids']==[x['id'] for x in plan['commands']]==['oracle-before',kind,'oracle-after'],'process omitted')
 need(len(proc['results'])==3,'result omitted')
 for r,c,exit_code in zip(proc['results'],plan['commands'],[0,expected_exit,0]):
  need(r['id']==c['id'] and r['argv']==c['argv'] and r['exit_code']==exit_code and not r['supervisor_error'],'nonzero/mismatched command')
  need(sha(state/'attempt1/process'/r['log'])==r['log_sha256'],'changed process log')
 required={'tools/core070_build_oracle.py','tools/core070_targeted_run.py','test/parity/fixtures/core070_slopes_input.R','docs/dev-log/core070/slopes-input-leaf.md'}
 required.add('tools/core070_fit_input.R')
 need(set(plan['pins'])==required,'dependency inventory differs')
 with tarfile.open(state/'source.tar') as archive:
  members=archive.getmembers();need(len(members)==len({m.name for m in members}) and {m.name for m in members}==required|{'plan.json'},'archive inventory differs')
  for name,pin in {**plan['pins'],'plan.json':sha(state/'plan.json')}.items():
   member=archive.getmember(name);need(member.isfile(),'nonregular archived input')
   need(hashlib.sha256(archive.extractfile(member).read()).hexdigest()==pin,'archive input changed')
 for name,pin in plan['pins'].items():
  if name.startswith('inputs/'):
   path=STATE/RUNS[1]/'attempt1/out'/Path(name).name
  elif current and name!='docs/dev-log/core070/slopes-input-leaf.md':path=ROOT/name
  # The human pre-run leaf is archive-bound; its post-run correction has no
  # execution effect. Current corrected prose is separately pinned below.
  else:continue
  need(sha(path)==pin,'source or captured input changed '+name)
 return proc

def verify_export(export,annex):
 cases=export['cases'];need([c['id'][0] for c in cases]==IDS,'case omitted')
 need([c['id'] for c in annex['cases']]==IDS,'annex case omitted')
 for c,a in zip(cases,annex['cases']):
  id=c['id'][0];rejected=id in REJECT;misroute=id in MISROUTE
  need(c['observed']==['REJECTED_BEFORE_TAPE' if rejected else 'PREPARED'] and c['check']==[True],'capture failed')
  expected='REFERENCE_REJECTED' if rejected else 'BLOCKED_REFERENCE_MISROUTE' if misroute else 'PREPARED_REFERENCE_NUMERICS_UNPAID'
  need(a['status']==expected and a['native_status']=='UNPAID','unearned case promotion')
  need(a['reference_call']==c['call'][0] and a['executable_case_ids']==[],'call/interface drift')
  if rejected:continue
  d=c['data'];p=c['parameters'];poisson='POIS' in id;ordinary=id.startswith('SLOPE-ORD');latent='-LAT-' in id
  val=lambda k:d[k]['values']
  need(val('n_traits')==[3] and val('n_sites')==[18] and val('use_aghq')==[0],'data scope differs')
  need(val('family_id_vec')==[2 if poisson else 0]*54,'family differs')
  need(val('trait_id')==[i//18 for i in range(54)],'trait order differs')
  levels=sorted('u'+str(i) for i in range(1,19))
  need(val('site_id')==[levels.index('u'+str(i%18+1)) for i in range(54)],'unit order differs')
  x=[-1+2*(i%18)/17 for i in range(54)]
  need(all(abs(y-(i%5 if poisson else math.sin((i+1)/3)+(i//18+1)/5))<1e-12 for i,y in enumerate(val('y'))) and len(val('y'))==54,'response differs')
  wanted={'b_fix':3}
  if not poisson:wanted['log_sigma_eps']=1
  if misroute:
   need(c['random']==['g_phy'] and val('use_phylo_rr')==[1] and val('use_phylo_dep_slope')==[0] and val('n_lhs_cols')==[1],'reference misroute no longer reproduced')
   wanted['theta_rr_phy']=6
  elif ordinary:
   rank=4 if id.endswith('RANK4') else 2
   wanted['theta_rr_B_slope']=6*rank-rank*(rank-1)//2
   unique=id=='SLOPE-ORD-LAT-DEFAULT'
   if unique:wanted['theta_diag_B_slope']=6
   need(c['random']==(['z_B_slope','s_B_slope'] if unique else ['z_B_slope']),'ordinary random/Psi differs')
   need(p['z_B_slope']['dim']==[rank,18],'ordinary score shape differs')
   if unique:need(p['s_B_slope']['dim']==[6,18],'ordinary Psi shape differs')
   need(val('use_rr_B_slope')==[1] and val('use_diag_B_slope')==[int(unique)] and val('d_B_slope')==[rank],'ordinary flags differ')
   z=d['Z_B_lat'];need(z['dim']==[54,6],'ordinary basis shape differs')
   expected=[(1 if j==2*(i//18) else x[i] if j==2*(i//18)+1 else 0) for j in range(6) for i in range(54)]
   need(all(abs(a-b)<1e-12 for a,b in zip(z['values'],expected)) and len(z['values'])==324,'ordinary basis differs')
   if unique:need(d['Z_B_diag']==z,'Psi design differs')
  elif latent:
   wanted['theta_rr_phy_slope']=10
   need(c['random']==['g_phy_slope'] and val('use_phylo_latent_slope')==[1] and val('d_phy_slope')==[2],'structured latent differs')
   need(p['g_phy_slope']['dim']==[6,2,2],'structured score shape differs')
   z=d['Z_phy_lat'];need(z['dim']==[54,2] and len(z['values'])==108 and all(abs(a-b)<1e-12 for a,b in zip(z['values'],[1]*54+x)),'structured separate basis differs')
  else:
   n=9 if id.endswith('MULTIGAUSS') else 6;stride=n//3
   wanted['theta_dep_chol']=45 if n==9 else 6 if '-INDEP-DBAR' in id else 9 if '-INDEP-BAR' in id else 12 if '-DEP-DBAR' in id else 21
   need(c['random']==['b_phy_aug'] and val('use_phylo_dep_slope')==[1] and val('n_lhs_cols')==[n],'dependent flags differ')
   need(p['b_phy_aug']['dim']==[6,n,1],'dependent score shape differs')
   pairs=[(j,j) for j in range(n)]+[(i,j) for j in range(n) for i in range(j+1,n)]
   kept=[i==j or (i//2==j//2 if '-INDEP-BAR' in id else i%2==j%2 if '-DEP-DBAR' in id else False if '-INDEP-DBAR' in id else True) for i,j in pairs]
   expected=[];level=0
   for keep in kept:
    if keep:level+=1;expected.append(level)
    else:expected.append(None)
   m=p['theta_dep_chol']['map']
   need(m==(None if all(kept) else expected),'dependent pin map differs')
   need(all(v==0 for v,keep in zip(p['theta_dep_chol']['values'],kept) if not keep),'pinned covariance nonzero')
   z=d['Z_phy_aug'];need(z['dim']==[54,n,1],'dependent basis shape differs')
   expect=[(1 if j==stride*(i//18) else x[i] if j==stride*(i//18)+1 else x[i]*x[i]-.3 if stride==3 and j==stride*(i//18)+2 else 0) for j in range(n) for i in range(54)]
   need(len(z['values'])==54*n and all(abs(a-b)<1e-12 for a,b in zip(z['values'],expect)),'dependent basis differs')
  actual={k:v['free'][0] for k,v in p.items() if v['random']==[False] and v['free']!=[0]}
  need(actual==wanted,'extra/missing fixed coordinates')
  for k,v in p.items():
   m=v['map'];need(m is None or len(m)==len(v['values']),'parameter map length differs')
  if not ordinary:
   need(val('species_aug_id')==[(i%18)//3 for i in range(54)],'structured source row map differs')
   Q=d['Ainv_phy_rr'];aa=.7+1e-8;bb=.3
   need(Q['dim']==[6,6] and len(Q['values'])==36 and all(abs(v-((1/aa if i==j else 0)-bb/(aa*(aa+6*bb))))<1e-12 for (i,j),v in zip([(i,j) for j in range(6) for i in range(6)],Q['values'])),'structured precision differs')
  warnings=' '.join(c['warnings'])
  need(('omitted for this non-Gaussian fit' in ' '.join(warnings.split()))==(id=='SLOPE-ORD-LAT-POISDEFAULT'),'default Psi warning differs')
  need(a['free_parameters']==wanted and a['random']==c['random'],'annex parameter contract differs')

def verify():
 import subprocess
 e=load(ROOT/EVIDENCE);a=load(ROOT/ANNEX)
 need(e['reference_commit']==a['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86','source reference differs')
 need(e['status']=='REFERENCE_PREPARATION_WITH_TWO_MISROUTES_NATIVE_UNPAID','scope promotion')
 required_pins={'tools/core070_slopes_export.R','docs/dev-log/core070/slopes-input-contract.md',ANNEX,'docs/dev-log/core070/slopes-input-leaf.md'}|{'.unlazy/core070-aghq/oracle-source/readback/'+p for p in ['R/brms-sugar.R','R/fit-multi.R','R/lambda-constraint.R','src/gllvmTMB.cpp']}
 need(set(e['current_pins'])==required_pins,'missing current dependency')
 for p,h in e['current_pins'].items():need(sha(ROOT/p)==h,'current source changed '+p)
 expected={str(p.relative_to(STATE)) for run in RUNS for p in (STATE/run/'attempt1').rglob('*') if p.is_file()}
 expected|={run+'/'+f for run in RUNS for f in ['plan.json','source.tar','readback.tar']}
 need(set(e['retained_artifacts'])==expected,'missing retained artifact')
 for p,h in e['retained_artifacts'].items():need(sha(STATE/p)==h,'retained artifact drift')
 for run,exit_code,current in [(RUNS[0],1,False),(RUNS[1],0,False),(RUNS[2],0,True)]:verify_process(run,exit_code,current)
 parsed=json.loads(subprocess.check_output(['Rscript','--vanilla',str(ROOT/'tools/core070_slopes_export.R'),str(STATE/RUNS[-1]/'attempt1/out')],text=True,timeout=20))
 verify_export(parsed,a)
 need(e['case_ids']==IDS,'summary omitted case')
 mapping=load(ROOT/'docs/dev-log/core070/required-source-case-map.json')
 need(ANNEX in mapping['required_case_annexes'],'unlinked required annex')
 print('CORE070_SLOPES_INPUT_CONTRACT_VERIFIED 12 prepared models;8 rejections;2 reference misroutes; native unpaid')
 return e

def validate_slope_bindings(plan,executable_cases):
 """Preparation rows require later native/interface or explicit defect evidence."""
 need([c['id'] for c in plan['cases']]==IDS,'slope annex omitted obligation')
 for row in plan['cases']:
  id=row['id'];required={'reference_defect_disposition'} if id in MISROUTE else {'reference_boundary'} if id in REJECT else {'native_model','formula_interface','public_r_bridge'}
  selected=[c for c in executable_cases if c.get('slope_case_id')==id]
  need(required<={c.get('coverage_role') for c in selected},'slope case missing native/interface/defect role '+id)
  for c in selected:
   need(all(isinstance(c.get(k),str) and c[k].strip() for k in ['r_call','julia_call','model_contract_id','acceptance_rule','fixture']),'incomplete executable slope contract '+id)
   if id in MISROUTE:
    need(c.get('resolution_status')=='ACCEPTED' and c.get('julia_disposition') in {'reject_with_explanation','documented_model_extension'},'silent reference misroute cannot pass '+id)
   elif id in REJECT:
    need(c.get('julia_disposition') in {'reject','documented_extension'},'unsupported slope lacks explicit disposition '+id)
   else:
    need(c.get('acceptance_level')==('paired_fit' if c.get('coverage_role')=='native_model' else 'paired_fit_interface'),'prepared-only slope promoted '+id)

def require_frozen_slopes(manifest,root):
 root=Path(root);coverage=manifest.get('source_coverage',{});plan=load(root/ANNEX)
 need(coverage.get('slopes_plan')==ANNEX and coverage.get('slopes_plan_sha256')==sha(root/ANNEX),'slope contract unbound')
 need(plan.get('reference_commit')=='b4d5fee64def88bc768dda1f1f77c29b295edd86','slope source changed')
 validate_slope_bindings(plan,manifest.get('executable_case',[]))

if __name__=='__main__':verify()
