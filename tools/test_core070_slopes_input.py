"""Reference preparation cannot promote lost terms or wrong covariance maps."""
import copy,json,unittest,subprocess,contextlib,io
from unittest.mock import patch
import core070_verify_slopes_input as gate

class SlopesInput(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.export=json.loads(subprocess.check_output(['Rscript','--vanilla',str(gate.ROOT/'tools/core070_slopes_export.R'),str(gate.STATE/gate.RUNS[-1]/'attempt1/out')],text=True))
  cls.annex=gate.load(gate.ROOT/gate.ANNEX)
 def test_positive(self):
  with contextlib.redirect_stdout(io.StringIO()):gate.verify()
 def test_corruptions(self):
  for defect in ['omit-case','misroute-promoted','map-corrupt','pin-freed','source-corrupt','basis-corrupt','response-order','warning-hidden','extra-parameter','exact-map-partial','native-promoted','unit-order','score-shape']:
   with self.subTest(defect=defect):
    e=copy.deepcopy(self.export);a=copy.deepcopy(self.annex);cs={c['id'][0]:c for c in e['cases']}
    if defect=='omit-case':e['cases'].pop()
    elif defect=='misroute-promoted':a['cases'][14]['status']='PREPARED_REFERENCE_NUMERICS_UNPAID'
    elif defect=='map-corrupt':cs['SLOPE-ANIMAL-INDEP-BAR']['parameters']['theta_dep_chol']['map'][7]=8
    elif defect=='pin-freed':cs['SLOPE-ANIMAL-INDEP-DBAR']['parameters']['theta_dep_chol']['values'][6]=.1
    elif defect=='source-corrupt':cs['SLOPE-ANIMAL-DEP-BAR']['data']['Ainv_phy_rr']['values'][0]=1
    elif defect=='basis-corrupt':cs['SLOPE-PHYLO-DEP-MULTIGAUSS']['data']['Z_phy_aug']['values'][0]=0
    elif defect=='response-order':cs['SLOPE-ORD-LAT-DEFAULT']['data']['y']['values'].reverse()
    elif defect=='warning-hidden':cs['SLOPE-ORD-LAT-POISDEFAULT']['warnings']=[]
    elif defect=='extra-parameter':cs['SLOPE-ORD-LAT-NOUNIQUE']['parameters']['theta_diag_B_slope']['free']=[6]
    elif defect=='exact-map-partial':cs['SLOPE-ANIMAL-DEP-MULTIGAUSS']['parameters']['theta_rr_phy']['map']=[None]*3
    elif defect=='unit-order':cs['SLOPE-ORD-LAT-DEFAULT']['data']['site_id']['values'][0]=17
    elif defect=='score-shape':cs['SLOPE-ANIMAL-DEP-BAR']['parameters']['b_phy_aug']['dim']=[1,6,6]
    else:a['cases'][0]['native_status']='PASS'
    with self.assertRaises(ValueError):gate.verify_export(e,a)
 def test_historical_failure_remains_failure(self):
  with self.assertRaises(ValueError):gate.verify_process(gate.RUNS[0],0,False)
 def test_missing_dependency_receipt_or_nonzero(self):
  original=gate.load
  for defect in ['missing-dependency','missing-receipt','nonzero-exit']:
   with self.subTest(defect=defect):
    target=gate.STATE/gate.RUNS[-1]/'attempt1/process/process-receipt.json' if defect=='nonzero-exit' else gate.ROOT/gate.EVIDENCE
    changed=copy.deepcopy(original(target))
    if defect=='missing-dependency':changed['current_pins'].pop('tools/core070_slopes_export.R')
    elif defect=='missing-receipt':changed['retained_artifacts'].pop(next(iter(changed['retained_artifacts'])))
    else:changed['results'][1]['exit_code']=12
    with patch.object(gate,'load',side_effect=lambda p:changed if p==target else original(p)),self.assertRaises(ValueError):gate.verify()
 def test_full_freeze_requires_slope_roles(self):
  with self.assertRaisesRegex(ValueError,'slope contract unbound'):gate.require_frozen_slopes({},gate.ROOT)
  cases=[]
  for id in gate.IDS:
   roles=['reference_defect_disposition'] if id in gate.MISROUTE else ['reference_boundary'] if id in gate.REJECT else ['native_model','formula_interface','public_r_bridge']
   for role in roles:
    cases.append(dict(slope_case_id=id,coverage_role=role,r_call='synthetic reference call',julia_call='synthetic native call',model_contract_id=id,acceptance_rule='synthetic check',fixture='synthetic fixture',julia_disposition='reject_with_explanation' if id in gate.MISROUTE else 'reject',resolution_status='ACCEPTED',acceptance_level='paired_fit' if role=='native_model' else 'paired_fit_interface'))
  gate.validate_slope_bindings(self.annex,cases)
  for defect in ['missing-bridge','missing-defect','silent-drop','preparation-only']:
   with self.subTest(defect=defect):
    changed=copy.deepcopy(cases)
    if defect=='missing-bridge':changed=[c for c in changed if c['coverage_role']!='public_r_bridge']
    elif defect=='missing-defect':changed=[c for c in changed if c['coverage_role']!='reference_defect_disposition']
    elif defect=='silent-drop':next(c for c in changed if c['slope_case_id'] in gate.MISROUTE)['julia_disposition']='copy_silent_drop'
    else:changed[0]['acceptance_level']='prepared_input'
    with self.assertRaises(ValueError):gate.validate_slope_bindings(self.annex,changed)

if __name__=='__main__':unittest.main()
