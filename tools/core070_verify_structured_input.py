"""Frozen reference preparation: no native or fitted-model completion claim."""
import hashlib,json,math,subprocess,tarfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];STATE=ROOT/'.unlazy/core070-aghq'
EVIDENCE='docs/dev-log/core070/structured-input-evidence.json'
ANNEX='docs/dev-log/core070/structured-required-case-plan.json'
RUNS=['structured-qualify-01','structured-input-01','structured-input-02','structured-input-03']
IDS=['STRUCT-'+s for s in ['PHY-TREE-RR','PHY-DENSE-RR','PHY-TREE-PROPTO','ANI-PED-SPARSE','KER-SINGLE-PSI','KER-MULTI','SPA-INDEP','SPA-LATENT','SPA-LATENT-PSI','SPA-DEP','SPA-COMMON-MAP','KER-MULTI-PSI-PRUNED','BAD-TREE-ULTRA','BAD-TREE-NEGATIVE','BAD-PED-PARENT','BAD-PED-CYCLE','BAD-KER-ASYM','BAD-KER-PSD','BAD-KER-RANK','BAD-KER-GROUP','BAD-KER-DEP','BAD-KER-PSI','BAD-SPA-RAW','BAD-SPA-ROWS']]
REJECT=set(IDS[12:]);DEFECT=IDS[11];BAD_DIAGNOSTICS=set(IDS[14:16])
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return json.loads(p.read_text())
def need(v,m):
 if not v:raise ValueError(m)
def close(a,b):return len(a)==len(b) and all(math.isfinite(x) and abs(x-y)<1e-12 for x,y in zip(a,b))
def shaped(actual,dims,vals,label):need(actual['dim']==dims and close(actual['values'],vals),label+' differs')
def covariance_inverse(a,b,v):
 # Sherman-Morrison for a I + b vv', independent of captured R computation.
 return [(1/a if i==j else 0)-b*v[i]*v[j]/(a*(a+b*sum(t*t for t in v))) for j in range(len(v)) for i in range(len(v))]
def verify_process(name,expected_exit,current):
 state=STATE/name;plan=load(state/'plan.json');p=load(state/'attempt1/process/process-receipt.json')
 kind='qualify' if 'qualify' in name else 'capture'
 need(p['status']==('PASS' if expected_exit==0 else 'FAIL') and p['source_unchanged'] and not p['supervisor_error'],'process failed/drifted')
 need(p['plan_sha256']==sha(state/'plan.json')==sha(state/'attempt1/process/execution-plan.json'),'plan changed')
 need(p['source_pins']==plan['pins'] and p['environment_overrides']==plan['env']=={'OPENBLAS_NUM_THREADS':'1','OMP_NUM_THREADS':'1'},'unbound environment/source')
 need(p['expected_ids']==[c['id'] for c in plan['commands']]==['oracle-before',kind,'oracle-after'] and len(p['results'])==3,'omitted command')
 required={'tools/core070_build_oracle.py','tools/core070_targeted_run.py','docs/dev-log/core070/structured-input-leaf.md'}
 required|={'tools/core070_structured_qualify.R','test/parity/fixtures/core070_structured_data.R'} if kind=='qualify' else {'tools/core070_fit_input.R','test/parity/fixtures/core070_structured_input.R','inputs/fixtures.rds'}
 need(set(plan['pins'])==required,'dependency inventory differs')
 for r,c,code in zip(p['results'],plan['commands'],[0,expected_exit,0]):
  need(r['id']==c['id'] and r['argv']==c['argv'] and r['exit_code']==code and not r['supervisor_error'],'nonzero/mismatched command')
  need(r['elapsed_seconds']<=c['timeout_seconds'] and sha(state/'attempt1/process'/r['log'])==r['log_sha256'],'timeout or altered log')
 with tarfile.open(state/'source.tar') as t:
  ms=t.getmembers();need(len(ms)==len({m.name for m in ms}) and {m.name for m in ms}==required|{'plan.json'},'archive inventory')
  for path,h in {**plan['pins'],'plan.json':sha(state/'plan.json')}.items():
   m=t.getmember(path);need(m.isfile() and hashlib.sha256(t.extractfile(m).read()).hexdigest()==h,'archive drift')
 for path,h in plan['pins'].items():
  if path=='inputs/fixtures.rds':target=STATE/'structured-qualify-01/attempt1/out/fixtures.rds'
  elif current:target=ROOT/path
  else:continue
  need(sha(target)==h,'current source/fixture changed '+path)
 return p

def verify_export(e,annex):
 cs=e['cases'];need([c['id'][0] for c in cs]==IDS and [a['id'] for a in annex['cases']]==IDS,'case inventory differs')
 f=e['fixture'];shaped(f['C'],[3,3],[1 if i==j else .3 for j in range(3) for i in range(3)],'C')
 shaped(f['K2'],[3,3],[.6*(i==j)+.4*[1,-1,1][i]*[1,-1,1][j] for j in range(3) for i in range(3)],'K2')
 need(f['A_proj']['dim']==[12,35] and len(f['A_proj']['values'])==420,'qualified mesh projection shape')
 need(all(abs(sum(f['A_proj']['values'][i::12])-1)<1e-12 for i in range(12)),'projection row sums')
 for k in ['spde_M0','spde_M1','spde_M2']:
  z=f[k];need(z['dim']==[35,35] and len(z['values'])==1225 and all(math.isfinite(v) for v in z['values']),'FEM shape/finite')
  need(all(abs(z['values'][i+35*j]-z['values'][j+35*i])<1e-12 for i in range(35) for j in range(35)),'FEM symmetry')
 for c,a in zip(cs,annex['cases']):
  id=c['id'][0];reject=id in REJECT;spatial=id.startswith('STRUCT-SPA')
  need(c['observed']==['REJECTED_BEFORE_TAPE' if reject else 'PREPARED'] and c['check']==[True],'capture failed '+id)
  status='REFERENCE_REJECTED' if reject else 'BLOCKED_REFERENCE_PARAMETER_LOSS' if id==DEFECT else 'PREPARED_REFERENCE_NUMERICS_UNPAID'
  need(a['status']==status and a['native_status']=='UNPAID' and a['executable_case_ids']==[],'unearned promotion '+id)
  need(a['reference_call']==c['call'][0],'call differs')
  if reject:
   need(a['observed_diagnostic']==c['detail'][0],'rejection diagnostic differs')
   if id in BAD_DIAGNOSTICS:need(a.get('diagnostic_status')=='BLOCKED_REFERENCE_DIAGNOSTIC' and 'diagnostic_quality' in a['required_roles'],'generic pedigree error promoted')
   continue
  d=c['data'];p=c['parameters'];val=lambda k:d[k]['values'];n=4 if spatial else 12
  need(val('n_sites')==[n] and val('n_traits')==[3] and val('family_id_vec')==[0]*(3*n) and val('use_aghq')==[0],'scope differs')
  need(val('site_id')==list(range(n))*3 and val('trait_id')==[i//n for i in range(3*n)],'observation order differs')
  need(close(val('y'),[math.cos((i+1)/3)+(i//n+1)/5 if spatial else math.sin((i+1)/3)+(i//n+1)/5 for i in range(3*n)]),'response differs')
  wanted={'b_fix':3,'log_sigma_eps':1};random={};flags={'use_propto':0,'use_spde':int(spatial),'use_phylo_rr':0,'use_phylo_diag':0,'n_kernel_tiers':0}
  if spatial:
   rank=3 if id==IDS[9] else 1 if id in IDS[7:9] else 0
   unique=id==IDS[8];need(val('spde_lv_k')==[rank] and val('spde_lv_unique')==[int(unique)] and val('n_mesh')==[35],'spatial flags')
   wanted['log_kappa_spde']=1
   if not rank or unique:random['omega_spde']=[35,3];wanted['log_tau_spde']=1 if id==IDS[10] else 3
   if rank:random['omega_spde_lv']=[35,rank];wanted['theta_rr_spde_lv']=3*rank-rank*(rank-1)//2
   need(p['log_tau_spde']['map']==([1,1,1] if id==IDS[10] else [None]*3 if rank and not unique else None),'tau tie/pin differs')
   for k in ['A_proj','spde_M0','spde_M1','spde_M2']:need(d[k]==f[k],'spatial projection/FEM mismatch '+k)
  elif id in [IDS[5],DEFECT]:
   flags['n_kernel_tiers']=2;random['g_kernel']=None;wanted['theta_rr_kernel']=6
   for k,v in {'kernel_rank':[1,1],'kernel_has_diag':[0,0],'kernel_has_latent':[1,1],'kernel_g_offset':[0,3],'kernel_group_id':[(i%12)//4 for i in range(36)],'n_kernel_levels':[3]}.items():need(val(k)==v,'kernel layout differs '+k)
   q1=covariance_inverse(.7+1e-8,.3,[1,1,1]);q2=covariance_inverse(.6+1e-8,.4,[1,-1,1])
   shaped(d['Ainv_kernel'],[2,3,3],[v for pair in zip(q1,q2) for v in pair],'kernel inverse')
   need(close(val('log_det_A_kernel'),[2*math.log(.7+1e-8)+math.log(1.6+1e-8),2*math.log(.6+1e-8)+math.log(1.8+1e-8)]),'kernel logdet')
   need(len(p['g_kernel']['values'])==6 and c['warnings']==[],'kernel field or pruning warning differs')
  elif id==IDS[2]:
   flags['use_propto']=1;random['p_phy']=[3,3];wanted['loglambda_phy']=1
   aa=1+1e-8;det=aa*aa-.25
   shaped(d['Cphy_inv'],[3,3],[aa/det,-.5/det,0,-.5/det,aa/det,0,0,0,1/aa],'propto inverse')
   need(close(val('log_det_Cphy'),[math.log(det*aa)]),'propto logdet')
  else:
   flags['use_phylo_rr']=1;wanted['theta_rr_phy']=3
   ped=id==IDS[3];tree=id==IDS[0];aug=4 if ped or tree else 3
   random['g_phy']=[aug,1];need(val('n_aug_phy')==[aug] and val('d_phy')==[1],'source dimension')
   mapping=[2+(i%12)//6 if ped else 1+(i%12)//4 if tree else (i%12)//4 for i in range(36)]
   need(val('species_aug_id')==mapping,'source observation map')
   q=[2,1,-1,-1,1,2,-1,-1,-1,-1,2,0,-1,-1,0,2] if ped else [6,-2,-2,0,-2,2,0,0,-2,0,2,0,0,0,0,1] if tree else covariance_inverse(.7+1e-8,.3,[1,1,1])
   shaped(d['Ainv_phy_rr'],[aug,aug],q,'source precision')
   logdet=-math.log(4) if ped else -math.log(8) if tree else 2*math.log(.7+1e-8)+math.log(1.6+1e-8)
   need(close(val('log_det_A_phy_rr'),[logdet]),'source logdet')
   if id==IDS[4]:flags['use_phylo_diag']=1;random['g_phy_diag']=[3,3];wanted['log_sd_phy_diag']=3
  for k,v in flags.items():need(val(k)==[v],'engine flag differs '+k)
  need(c['random']==list(random),'random inventory differs')
  for k,dim in random.items():need(p[k]['dim']==dim and p[k]['random']==[True],'random shape differs')
  for k,v in p.items():
   m=v['map'];need(m is None or len(m)==len(v['values']),'partial map lookup')
   need(v['free']==[len(v['values']) if m is None else len(set(m)-{None})],'free count inconsistent')
  actual={k:v['free'][0] for k,v in p.items() if v['random']==[False] and v['free']!=[0]}
  need(actual==wanted and a['free_parameters']==wanted and a['random']==c['random'],'fixed parameter inventory differs')
  warnings=' '.join(c['warnings']);need(('Unused optional grouping' in warnings)==spatial,'spatial unused grouping warning differs')
  need(('soft-deprecated' in warnings)==(id==IDS[2]),'alias deprecation differs')
 # The requested Psi companions have disappeared: this is a defect, not parity.
 for key in ['data','parameters','random']:
  need(cs[5][key]==cs[11][key],'multi-kernel pruning diagnostic changed')

def verify():
 e=load(ROOT/EVIDENCE);a=load(ROOT/ANNEX)
 need(e['reference_commit']==a['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86','source pin differs')
 need(e['status']=='REFERENCE_PREPARATION_WITH_PARAMETER_LOSS_NATIVE_UNPAID','unearned scope')
 required={'.unlazy/core070-aghq/oracle-source/source.json','.unlazy/core070-aghq/oracle-source/gllvmTMB-core070.tar','tools/core070_structured_export.R','docs/dev-log/core070/structured-input-contract.md',ANNEX}|{'.unlazy/core070-aghq/oracle-source/readback/'+p for p in ['R/fit-multi.R','R/phylo-tree-precision.R','R/pedigree-precision.R','R/mesh.R','src/gllvmTMB.cpp']}
 need(set(e['current_pins'])==required,'current dependency missing')
 for p,h in e['current_pins'].items():need(sha(ROOT/p)==h,'current dependency changed '+p)
 oracle=load(STATE/'oracle-source/source.json');archive=STATE/'oracle-source/gllvmTMB-core070.tar'
 need(oracle['archive_sha256']==sha(archive)=='0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc','frozen archive differs')
 need(oracle['reference_commit']==e['reference_commit'],'oracle reference differs')
 with tarfile.open(archive) as t:
  need(t.pax_headers.get('comment')==e['reference_commit'],'archive commit differs')
  for rel,h in oracle['source_files'].items():
   if str(STATE/'oracle-source/readback'/rel).startswith(str(ROOT)) and '.unlazy/core070-aghq/oracle-source/readback/'+rel in e['current_pins']:
    m=t.getmember(rel);need(m.isfile() and hashlib.sha256(t.extractfile(m).read()).hexdigest()==h==sha(STATE/'oracle-source/readback'/rel),'source not from frozen archive '+rel)
 artifacts={str(p.relative_to(STATE)) for run in RUNS for p in (STATE/run/'attempt1').rglob('*') if p.is_file()}|{run+'/'+f for run in RUNS for f in ['plan.json','source.tar','readback.tar']}
 need(set(e['retained_artifacts'])==artifacts,'retained artifact omitted')
 for p,h in e['retained_artifacts'].items():need(sha(STATE/p)==h,'retained artifact changed '+p)
 for run,code,current in zip(RUNS,[0,1,1,0],[True,False,False,True]):verify_process(run,code,current)
 export=json.loads(subprocess.check_output(['Rscript','--vanilla',str(ROOT/'tools/core070_structured_export.R'),str(STATE/RUNS[-1]/'attempt1/out')],text=True,timeout=20))
 verify_export(export,a);need(e['case_ids']==IDS,'summary omitted case')
 need(ANNEX in load(ROOT/'docs/dev-log/core070/required-source-case-map.json')['required_case_annexes'],'annex unlinked')
 print('CORE070_STRUCTURED_INPUT_CONTRACT_VERIFIED 11 models prepared;12 rejections;1 parameter-loss defect; native unpaid')
 return e
def validate_structured_bindings(plan,cases):
 need([r['id'] for r in plan['cases']]==IDS,'structured annex incomplete')
 for row in plan['cases']:
  id=row['id'];required={'reference_boundary'} if id in REJECT else {'reference_defect_disposition'} if id==DEFECT else {'native_model','formula_interface','public_r_bridge'}
  if id in BAD_DIAGNOSTICS:required.add('diagnostic_quality')
  selected=[c for c in cases if c.get('structured_case_id')==id]
  need(required<={c.get('coverage_role') for c in selected},'structured required role missing '+id)
  for c in selected:
   need(all(isinstance(c.get(k),str) and c[k].strip() and c[k]!='UNRESOLVED' for k in ['r_call','julia_call','model_contract_id','acceptance_rule','fixture']),'structured call unresolved '+id)
   if id==DEFECT:need(c.get('resolution_status')=='ACCEPTED' and c.get('julia_disposition') in {'reject_with_explanation','documented_model_extension'},'silent parameter loss cannot pass')
   elif c.get('coverage_role')=='diagnostic_quality':need(c.get('diagnostic_assertion')=='specific_invalid_pedigree' and c.get('acceptance_level')=='executed_negative','pedigree diagnostic quality unpaid')
   elif id in REJECT:need(c.get('julia_disposition') in {'reject','documented_extension'},'rejection disposition absent')
   else:need(c.get('acceptance_level')==('paired_fit' if c.get('coverage_role')=='native_model' else 'paired_fit_interface'),'prepared-only structured row promoted')
def require_frozen_structured(manifest,root):
 root=Path(root);coverage=manifest.get('source_coverage',{});plan=load(root/ANNEX)
 need(coverage.get('structured_plan')==ANNEX and coverage.get('structured_plan_sha256')==sha(root/ANNEX),'structured plan unbound')
 need(plan['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86','structured source changed')
 validate_structured_bindings(plan,manifest.get('executable_case',[]))
if __name__=='__main__':verify()
