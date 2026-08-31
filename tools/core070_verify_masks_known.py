"""Verify loading-mask and known-covariance contracts, not native fitting or full parity."""
import csv,hashlib,json,math,re,tarfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq'
EVIDENCE='docs/dev-log/core070/masks-known-evidence.json'
IDS=['MASK-B-PINS','MASK-B-UPPER','MASK-PHY-PINS','MASK-PHY-INDEP-CONFLICT','MASK-B-DIM','MASK-B-NONMATRIX','MASK-B-SLOPE','MASK-B-ALLFIXED','KNOWN-EXACT','KNOWN-ALIAS','KNOWN-BLOCK','KNOWN-ZERO','KNOWN-MISSING','KNOWN-DIM','KNOWN-PROP','KNOWN-LIST','KNOWN-POISSON']
POSITIVE=['MASK-B-PINS','MASK-B-UPPER','MASK-PHY-PINS','MASK-B-ALLFIXED','KNOWN-EXACT','KNOWN-ALIAS','KNOWN-BLOCK','KNOWN-ZERO','KNOWN-POISSON']
GAUSSIAN=POSITIVE[:-1]
RUNS=['masks-known-01','masks-known-02','masks-known-points-01']
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
 kind='capture' if name in RUNS[:2] else 'points'
 need(proc['expected_ids']==[x['id'] for x in plan['commands']]==['oracle-before',kind,'oracle-after'],'process omitted')
 need(len(proc['results'])==3,'result omitted')
 for r,c,exit_code in zip(proc['results'],plan['commands'],[0,expected_exit,0]):
  need(r['id']==c['id'] and r['argv']==c['argv'] and r['exit_code']==exit_code and not r['supervisor_error'],'nonzero/mismatched command')
  need(sha(state/'attempt1/process'/r['log'])==r['log_sha256'],'changed process log')
 required={'tools/core070_build_oracle.py','tools/core070_targeted_run.py','test/parity/fixtures/core070_masks_known.R','docs/dev-log/core070/masks-known-leaf.md'}
 required.add('tools/core070_fit_input.R' if kind=='capture' else 'tools/core070_masks_known_points.R')
 if kind=='points':required.update({'inputs/'+x+'-input.rds' for x in POSITIVE}|{'inputs/fixtures.rds'})
 need(set(plan['pins'])==required,'dependency inventory differs')
 with tarfile.open(state/'source.tar') as archive:
  members=archive.getmembers();need(len(members)==len({m.name for m in members}) and {m.name for m in members}==required|{'plan.json'},'archive inventory differs')
  for name,pin in {**plan['pins'],'plan.json':sha(state/'plan.json')}.items():
   member=archive.getmember(name);need(member.isfile(),'nonregular archived input')
   need(hashlib.sha256(archive.extractfile(member).read()).hexdigest()==pin,'archive input changed')
 for name,pin in plan['pins'].items():
  if name.startswith('inputs/'):
   path=STATE/RUNS[1]/'attempt1/out'/Path(name).name
  elif current and name!='docs/dev-log/core070/masks-known-leaf.md':path=ROOT/name
  # The human pre-run leaf is archive-bound; its post-run correction has no
  # execution effect. Current corrected prose is separately pinned below.
  else:continue
  need(sha(path)==pin,'source or captured input changed '+name)
 return proc

def close(a,b,message,tolerance=1e-12):
 need(math.isfinite(float(a)) and abs(float(a)-b)<=tolerance,message)

def verify_points(points,maps,output):
 need([m['id'] for m in maps]==GAUSSIAN,'missing or duplicate model map')
 need([p['id'] for p in points]==[x+'-P'+str(i) for x in GAUSSIAN for i in [1,2]],'missing or duplicate point')
 for m in maps:
  known=m['id'].startswith('KNOWN');allfixed=m['id']=='MASK-B-ALLFIXED';phy=m['id']=='MASK-PHY-PINS'
  need(m['field']==('none' if known else 'theta_rr_phy' if phy else 'theta_rr_B'),'wrong loading field')
  need(m['random']==('e_eq' if known else 'g_phy' if phy else 'z_B'),'wrong random block')
  need(int(m['free_loadings'])==(0 if known or allfixed else 3) and m['free_residual']=='1','wrong free coordinates')
  need(m['map']==('none' if known else 'NA,NA,NA,NA,NA' if allfixed else 'NA,1,2,3,NA'),'wrong map')
  need(m['pins']==('none' if known else '0.8,0.7,0.1,0.2,-0.15' if allfixed else '0.8,0'),'wrong fixed pins')
 for p in points:
  id,point=p['id'].rsplit('-P',1);point=int(point);known=id.startswith('KNOWN');phy=id=='MASK-PHY-PINS';allfixed=id=='MASK-B-ALLFIXED'
  m=next(x for x in maps if x['id']==id);d=output/p['id']
  numbers={k:float(p[k]) for k in ['r_nll','dense_nll','delta','gradient_error','shifted_mean_delta']}
  need(all(math.isfinite(x) for x in numbers.values()),'nonfinite point')
  close(numbers['delta'],abs(numbers['r_nll']-numbers['dense_nll']),'inconsistent likelihood delta',1e-10)
  need(0<=numbers['delta']<=1e-6 and 0<=numbers['gradient_error']<=1e-5 and numbers['shifted_mean_delta']>1e-4 and p['pass']=='TRUE','failed point')
  if known and id!='KNOWN-ZERO':need(float(p['drop_known_delta'])>1e-4,'dropped known covariance accepted')
  pars=rows(d/'parameters.tsv');beta=[.2,-.1,.3] if point==1 else [-.1,.25,.05];sigma=.8 if point==1 else .55
  theta=[.8,.7,.1,.2,-.15] if allfixed else ([.8,.7,.1,.2,0] if point==1 else [.8,.9,-.1,.25,0])
  expected={'b_fix':beta,'log_sigma_eps':[math.log(sigma)]}
  if not known and not allfixed:expected[m['field']]=theta[1:4]
  need(sorted(r['name'] for r in pars)==sorted(k for k,v in expected.items() for _ in v),'missing free parameter')
  for k,v in expected.items():
   actual=[r for r in pars if r['name']==k]
   for r,w in zip(actual,v):close(r['value'],w,'wrong fixed-point coordinate')
  need(all(math.isfinite(float(r[k])) for r in pars for k in ['r_gradient','dense_fd']),'nonfinite gradient')
  grad=max(abs(float(r['r_gradient'])-float(r['dense_fd']))/max(1,abs(float(r['r_gradient']))) for r in pars)
  close(grad,numbers['gradient_error'],'detached derivative evidence',1e-10)
  obs=rows(d/'observations.tsv');need(len(obs)==54,'wrong observation count')
  for i,r in enumerate(obs):
   # R factor() orders u1,u10,...,u18,u2,... lexicographically. Rows retain
   # expansion order; numerical group codes therefore are not row numbers.
   site_code=sorted('u'+str(j) for j in range(1,19)).index('u'+str(i%18+1))+1
   need(int(r['trait'])==i//18+1 and int(r['group'])==(i+1 if known else (i%18)//3+1 if phy else site_code),'wrong observation order')
   close(r['y'],math.sin((i+1)/3)+(i//18+1)/5,'wrong retained response')
  size=54 if known else 6 if phy else 18
  def source(i,j):
   if not known:return ((1+1e-8 if i==j else .3) if phy else float(i==j))
   vi=.1+.3*i/53;vj=.1+.3*j/53
   raw=0 if id=='KNOWN-ZERO' else vi if i==j else .25*math.sqrt(vi*vj) if id=='KNOWN-BLOCK' and (i%18)//3==(j%18)//3 else 0
   return raw+(1e-8 if i==j else 0)
  matrix=rows(d/'source.tsv');headers=[('g' if phy else 'X')+str(i+1) for i in range(size)]
  need(len(matrix)==size and all(list(r)==headers for r in matrix),'wrong source shape/order')
  for i,r in enumerate(matrix):
   for j,k in enumerate(headers):close(r[k],source(i,j),'wrong effective source matrix')
  L=[[theta[0],0],[theta[2],theta[1]],[theta[3],theta[4]]]
  cov=rows(d/'covariance.tsv');need(len(cov)==54 and all(len(r)==54 for r in cov),'wrong marginal shape')
  for i,r in enumerate(cov):
   for j,v in enumerate(r.values()):
    latent=source(i,j) if known else source(int(obs[i]['group'])-1,int(obs[j]['group'])-1)*sum(a*b for a,b in zip(L[i//18],L[j//18]))
    close(v,latent+(sigma*sigma if i==j else 0),'wrong marginal covariance')

def verify():
 e=load(ROOT/EVIDENCE)
 need(e['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86' and e['status']=='REFERENCE_FIXED_POINTS_NATIVE_FITS_UNPAID','reference/scope drift')
 need(e['case_ids']==IDS,'case inventory drift')
 need(set(e['reference_source_pins'])=={'R/lambda-constraint.R','R/fit-multi.R','R/brms-sugar.R','R/two-stage.R','src/gllvmTMB.cpp'},'source dependency omitted')
 for p,h in e['reference_source_pins'].items():need(sha(STATE/'oracle-source/readback'/p)==h,'source bytes changed')
 need(set(e['document_pins'])=={'docs/dev-log/core070/masks-known-leaf.md','docs/dev-log/core070/masks-known-contract.md','docs/dev-log/core070/masks-known-subset.json'},'document dependency omitted')
 for p,h in e['document_pins'].items():need(sha(ROOT/p)==h,'current document changed')
 expected={str(p.relative_to(STATE)) for run in RUNS for p in (STATE/run/'attempt1').rglob('*') if p.is_file()}
 expected|={run+'/'+file for run in RUNS for file in ['plan.json','source.tar','readback.tar']}
 need(set(e['retained_artifacts'])==expected,'retained artifact omitted')
 for p,h in e['retained_artifacts'].items():need(sha(STATE/p)==h,'artifact changed '+p)
 for name,exit_code,current in [(RUNS[0],1,False),(RUNS[1],0,True),(RUNS[2],0,True)]:
  proc=verify_process(name,exit_code,current)
  need(e['elapsed_seconds'][name]==proc['results'][1]['elapsed_seconds'],'elapsed summary detached')
 text=(STATE/RUNS[1]/'attempt1/process/01.log').read_text()
 matches=re.findall(r'^((?:MASK|KNOWN)-\S+)\t(PREPARED|REJECTED_BEFORE_TAPE)\tPASS$',text,re.M)
 need(matches==[(id,'PREPARED' if id in POSITIVE else 'REJECTED_BEFORE_TAPE') for id in IDS],'capture missing or misclassified')
 failed=(STATE/RUNS[0]/'attempt1/process/01.log').read_text()
 need(re.findall(r'^((?:MASK|KNOWN)-\S+)\tREJECTED_BEFORE_TAPE\tFAIL$',failed,re.M)==['MASK-B-SLOPE','KNOWN-MISSING','KNOWN-PROP'],'original diagnostic failures missing')
 out=STATE/RUNS[2]/'attempt1/out';points=rows(out/'points.tsv');maps=rows(out/'maps.tsv')
 need(e['points']==points and e['maps']==maps,'summary differs')
 wanted={'maps.tsv','points.tsv'}|{id+'-P'+str(i)+'/'+f for id in GAUSSIAN for i in [1,2] for f in ['observations.tsv','source.tsv','parameters.tsv','covariance.tsv','point.rds']}
 need({str(p.relative_to(out)) for p in out.rglob('*') if p.is_file()}==wanted,'missing point artifact')
 verify_points(points,maps,out)
 subset=load(ROOT/'docs/dev-log/core070/masks-known-subset.json');mapping=load(ROOT/'docs/dev-log/core070/required-source-case-map.json')
 need([r['id'] for r in subset['cases']]==IDS,'subset case drift')
 for c in subset['cases']:
  selected=[r for r in mapping['rows'] if r['source_id']=='masks-known/'+c['id']]
  need(len(selected)==1 and selected[0].get('reference_model_case_ids')==[c['id']] and selected[0].get('reference_model_evidence')==EVIDENCE and selected[0]['executable_case_ids']==[],'reference-only mapping drift')
 print('CORE070_MASKS_KNOWN_CONTRACT_VERIFIED 17 cases;16 Gaussian points; native fits unpaid')
 return e

if __name__=='__main__':verify()
