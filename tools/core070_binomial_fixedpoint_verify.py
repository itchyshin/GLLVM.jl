"""Verify diagnostic provenance without treating a gradient root as a fitted model."""
import re,tomllib,math,json,shutil,tempfile,contextlib,io
from unittest.mock import patch
from pathlib import Path
from core070_verify_link_boundaries import ROOT,process,sha
from core070_aghq_binomial_verify import current
STATE=ROOT/'.unlazy/core070-aghq/binomial-fixedpoint-02'

def verify():
 p,r,log=process(STATE,False,0);current(p)
 assert p['commands'][1]['argv'][-1]=='tools/core070_binomial_fixedpoint_run.jl'
 assert r['results'][1]['elapsed_seconds']<300
 for title,count in [('BF retained endpoint identity',4),('BF finite diagnostic receipts',6)]:
  assert re.search(re.escape(title)+rf'\s*\|\s*{count}\s+{count}',log)
 f=STATE/'attempt1/pair.toml';x=tomllib.loads(f.read_text())
 assert log.splitlines().count('BF_RECEIPT_SHA256 '+sha(f))==1
 assert x['scope']=='DIAGNOSTIC_ONLY_NOT_FIT_OR_PARITY' and x['case_id']=='BF-SEED43-K5'
 assert x['reference']=='b4d5fee64def88bc768dda1f1f77c29b295edd86' and x['k']==5
 assert x['julia_version']=='1.12.6' and x['package_root']==p['cwd']
 prior=ROOT/'.unlazy/core070-aghq/aghq-binomial-pair-03/attempt1/pair.toml'
 assert x['source_pair_sha256']==sha(prior) and x['fixture_sha256']==sha(prior.with_suffix('.toml.fixture.toml'))
 original=tomllib.loads(prior.read_text());assert not original['native_converged'] and not original['r_converged']
 assert [a['start_label'] for a in x['runs']]==['native','R']
 for a,key in zip(x['runs'],('native_parameters','r_native_parameters')):
  assert a['start']==original[key] and not a['parity_pass']
  assert len(a['parameters'])==len(a['frozen_gradient'])==14 and all(map(math.isfinite,a['parameters']+a['frozen_gradient']))
  assert a['frozen_residual_met']==(max(map(abs,a['frozen_gradient']))<1e-6)
  assert abs(a['objective_change_from_start']-(a['objective']-a['trace'][0]['objective']))<1e-12
  assert a['mode_site_count']==60 and a['mode_gradient_max']<=1e-7 and 0<=a['curvature_repairs']<=60
  assert len(a['loading_covariance'])==25 and all(map(math.isfinite,a['loading_covariance']))
  for j,label in enumerate(('native','R')):
   assert abs(a['objective_change_from_'+label]-(a['objective']-x['runs'][j]['trace'][0]['objective']))<1e-12
  assert a['fd_stability']<1e-5
  assert abs(max(abs(v-w) for v,w in zip(a['total_gradient_fd'],a['total_gradient_double_step']))-a['fd_stability'])<1e-12
  assert 1<=len(a['trace'])<=9 and a['trace'][0]['parameters']==a['start']
  for row in a['trials']:
   assert 0<=row['iteration']<8 and 1/256<=row['rho']<=1
  print(a['start_label'],'root_residual_met',a['frozen_residual_met'],'objective_change',a['objective_change_from_start'],'total_gradient',max(map(abs,a['total_gradient_fd'])))
 print('CORE070_BINOMIAL_FIXEDPOINT_DIAGNOSTIC_VERIFIED original parity remains unmet')
def negatives():
 def nonzero(p):
  f=p/'attempt1/process/process-receipt.json';r=json.loads(f.read_text())
  r['results'][1]['exit_code']=1;f.write_text(json.dumps(r))
 mutations={
  'missing-receipt':lambda p:(p/'attempt1/process/process-receipt.json').unlink(),
  'omitted-result':lambda p:(p/'attempt1/pair.toml').unlink(),
  'stale-source':lambda p:(p/'plan.json').write_text('{}'),
  'nonzero-exit':nonzero}
 for label,mutate in mutations.items():
  with tempfile.TemporaryDirectory(prefix='bf-negative-') as folder:
   copy=Path(folder)/'state';shutil.copytree(STATE,copy);mutate(copy)
   try:
    with patch.dict(verify.__globals__,STATE=copy),contextlib.redirect_stdout(io.StringIO()):verify()
   except (AssertionError,FileNotFoundError,KeyError,ValueError):pass
   else:raise AssertionError('Accepted '+label)
 with tempfile.TemporaryDirectory(prefix='bf-dependency-') as folder:
  try:
   with patch.dict(current.__globals__,MANIFEST=Path(folder)/'absent'),contextlib.redirect_stdout(io.StringIO()):verify()
  except FileNotFoundError:pass
  else:raise AssertionError('Accepted missing dependency')
 print('BF_EVIDENCE_NEGATIVES_PASS 5')

if __name__=='__main__':
 verify();negatives()
