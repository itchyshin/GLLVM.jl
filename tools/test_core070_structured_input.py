"""Prepared input must not become a parity claim or hide a lost variance term."""
import copy,contextlib,io,json,subprocess,unittest
from unittest.mock import patch
import core070_verify_structured_input as gate
class StructuredInput(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.export=json.loads(subprocess.check_output(['Rscript','--vanilla',str(gate.ROOT/'tools/core070_structured_export.R'),str(gate.STATE/'structured-input-03/attempt1/out')],text=True))
  cls.annex=gate.load(gate.ROOT/gate.ANNEX)
 def test_positive(self):
  with contextlib.redirect_stdout(io.StringIO()):gate.verify()
 def test_contract_corruption(self):
  for defect in ['omit','tree-Q','ped-map','dense-jitter','kernel-order','kernel-offset','spatial-projection','spatial-fem','common-map','extra-parameter','random-shape','native-promoted','defect-promoted','warning-hidden','response']:
   with self.subTest(defect=defect):
    e=copy.deepcopy(self.export);a=copy.deepcopy(self.annex);cs={c['id'][0]:c for c in e['cases']}
    if defect=='omit':e['cases'].pop()
    elif defect=='tree-Q':cs['STRUCT-PHY-TREE-RR']['data']['Ainv_phy_rr']['values'][0]+=1
    elif defect=='ped-map':cs['STRUCT-ANI-PED-SPARSE']['data']['species_aug_id']['values'][0]=0
    elif defect=='dense-jitter':cs['STRUCT-PHY-DENSE-RR']['data']['Ainv_phy_rr']['values'][0]=1.1607142857142858
    elif defect=='kernel-order':cs['STRUCT-KER-MULTI']['data']['Ainv_kernel']['values'].reverse()
    elif defect=='kernel-offset':cs['STRUCT-KER-MULTI']['data']['kernel_g_offset']['values']=[0,2]
    elif defect=='spatial-projection':cs['STRUCT-SPA-LATENT']['data']['A_proj']['values'][0]+=.1
    elif defect=='spatial-fem':cs['STRUCT-SPA-DEP']['data']['spde_M1']['values'][0]+=.1
    elif defect=='common-map':cs['STRUCT-SPA-COMMON-MAP']['parameters']['log_tau_spde']['map']=[1,2,3]
    elif defect=='extra-parameter':cs['STRUCT-SPA-LATENT']['parameters']['log_tau_spde']['free']=[3]
    elif defect=='random-shape':cs['STRUCT-PHY-TREE-RR']['parameters']['g_phy']['dim']=[1,4]
    elif defect=='native-promoted':a['cases'][0]['native_status']='PASS'
    elif defect=='defect-promoted':a['cases'][11]['status']='PREPARED_REFERENCE_NUMERICS_UNPAID'
    elif defect=='warning-hidden':cs['STRUCT-SPA-INDEP']['warnings']=[]
    elif defect=='response':cs['STRUCT-SPA-INDEP']['data']['y']['values'].reverse()
    with self.assertRaises(ValueError):gate.verify_export(e,a)
 def test_process_corruption(self):
  original=gate.load
  for defect in ['missing-receipt','missing-dependency','nonzero','stale-pin']:
   def changed(path):
    if path==gate.ROOT/gate.EVIDENCE and defect=='missing-receipt':raise FileNotFoundError(path)
    v=original(path)
    if path==gate.STATE/'structured-input-03/attempt1/process/process-receipt.json':
     if defect=='nonzero':v['results'][1]['exit_code']=1
     elif defect=='stale-pin':v['source_pins']['tools/core070_fit_input.R']='0'*64
    if path==gate.ROOT/gate.EVIDENCE and defect=='missing-dependency':v['current_pins'].pop('tools/core070_structured_export.R')
    return v
   with self.subTest(defect=defect),patch.object(gate,'load',side_effect=changed),self.assertRaises((ValueError,FileNotFoundError)):gate.verify()
 def test_failure_retained(self):
  with self.assertRaises(ValueError):gate.verify_process('structured-input-01',0,False)
 def test_freeze_rejects_missing_or_prepared_only(self):
  cases=[]
  for row in self.annex['cases']:
   for role in row['required_roles']:
    cases.append(dict(structured_case_id=row['id'],coverage_role=role,r_call=row['reference_call'],julia_call='explicit fixture call',model_contract_id='contract',acceptance_rule='rule',fixture='fixture',acceptance_level='paired_fit' if role=='native_model' else 'paired_fit_interface',julia_disposition='reject_with_explanation' if row['id']==gate.DEFECT else 'reject',resolution_status='ACCEPTED'))
  for c in cases:
   if c['coverage_role']=='diagnostic_quality':c['diagnostic_assertion']='specific_invalid_pedigree';c['acceptance_level']='executed_negative'
  gate.validate_structured_bindings(self.annex,cases)
  for defect in ['missing-bridge','missing-defect','prepared-only','silent-loss','unresolved-call','diagnostic-unpaid']:
   modified=copy.deepcopy(cases)
   if defect=='missing-bridge':modified=[c for c in modified if c['coverage_role']!='public_r_bridge']
   elif defect=='missing-defect':modified=[c for c in modified if c['structured_case_id']!=gate.DEFECT]
   elif defect=='prepared-only':modified[0]['acceptance_level']='prepared_input'
   elif defect=='silent-loss':next(c for c in modified if c['structured_case_id']==gate.DEFECT)['julia_disposition']='copy_silent_loss'
   elif defect=='diagnostic-unpaid':next(c for c in modified if c['coverage_role']=='diagnostic_quality')['diagnostic_assertion']='generic_covariance_error'
   else:modified[0]['julia_call']='UNRESOLVED'
   with self.subTest(defect=defect),self.assertRaises(ValueError):gate.validate_structured_bindings(self.annex,modified)
if __name__=='__main__':unittest.main()
