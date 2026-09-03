"""Fixed-reference contract verifier negative controls; no compute launches."""
import contextlib,copy,io,json,shutil,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import core070_verify_covariance_modes as gate

class CovarianceModeEvidence(unittest.TestCase):
 def test_positive(self):
  with contextlib.redirect_stdout(io.StringIO()):gate.verify()
 def test_point_and_map_mutations(self):
  out=gate.STATE/gate.RUNS[-1]/'attempt1/out'
  original_points=gate.rows(out/'points.tsv');original_maps=gate.rows(out/'maps.tsv')
  for defect in ['point-omitted','mode-omitted','bad-nll','bad-gradient','common-draw','wrong-transform','wrong-map','wrong-count','jitter-hidden']:
   with self.subTest(defect=defect):
    points=copy.deepcopy(original_points);maps=copy.deepcopy(original_maps)
    if defect=='point-omitted':points.pop()
    elif defect=='mode-omitted':maps.pop()
    elif defect=='bad-nll':points[0]['delta']='1'
    elif defect=='bad-gradient':points[0]['gradient_error']='1'
    elif defect=='common-draw':points[2]['wrong_common_delta']='0'
    elif defect=='wrong-transform':maps[4]['transform']='raw_loadings'
    elif defect=='wrong-map':maps[7]['map']='1,2,3,NA,NA,NA'
    elif defect=='wrong-count':maps[2]['free_residual']='0'
    else:maps[7]['source_jitter']='0'
    with self.assertRaises(ValueError):gate.verify_points(points,maps,out)
 def test_process_failures(self):
  original=gate.STATE
  for defect in ['nonzero','stale-plan','missing-dependency','archive-missing']:
   with self.subTest(defect=defect),tempfile.TemporaryDirectory() as folder:
    target=Path(folder);state=target/gate.RUNS[0]
    shutil.copytree(original/gate.RUNS[0],state)
    if defect=='archive-missing':(state/'source.tar').unlink()
    elif defect=='stale-plan':(state/'plan.json').write_text('{}')
    else:
     p=state/'attempt1/process/process-receipt.json';r=gate.load(p)
     if defect=='nonzero':r['results'][1]['exit_code']=7
     else:r['source_pins'].pop('tools/core070_fit_input.R')
     p.write_text(json.dumps(r))
    with patch.object(gate,'STATE',target),self.assertRaises((ValueError,OSError)):
     gate.verify_process(gate.RUNS[0],0,True)
 def test_unearned_summary_and_missing_dependency(self):
  original=gate.load;path=gate.ROOT/gate.EVIDENCE
  for defect in ['scope','case','source','document','result']:
   with self.subTest(defect=defect):
    e=copy.deepcopy(original(path))
    if defect=='scope':e['status']='FULL_PARITY_PASS'
    elif defect=='case':e['case_ids'].pop()
    elif defect=='source':e['reference_source_pins'].pop('src/gllvmTMB.cpp')
    elif defect=='document':e['document_pins'].clear()
    else:e['points'][0]['delta']='0'
    with patch.object(gate,'load',side_effect=lambda p:e if p==path else original(p)),self.assertRaises(ValueError):gate.verify()
 def test_historical_failure_cannot_be_marked_success(self):
  with self.assertRaises(ValueError):gate.verify_process(gate.RUNS[1],0,False)
 def test_retained_effective_source_matrix(self):
  import csv
  original=gate.STATE/gate.RUNS[-1]/'attempt1/out'
  for defect in ['missing-row','wrong-order','missing-jitter','wrong-correlation']:
   with self.subTest(defect=defect),tempfile.TemporaryDirectory() as folder:
    out=Path(folder)/'out';shutil.copytree(original,out)
    source=out/'MODE-ANIMAL-INDEP-P1/source.tsv';values=gate.rows(source);headers=list(values[0])
    if defect=='missing-row':values.pop()
    elif defect=='wrong-order':headers.reverse()
    elif defect=='missing-jitter':values[0]['g1']='1'
    else:values[0]['g2']='0.4'
    with source.open('w') as f:
     writer=csv.DictWriter(f,fieldnames=headers,delimiter='\t');writer.writeheader();writer.writerows(values)
    with self.assertRaisesRegex(ValueError,'retained (source|effective source)'):
     gate.verify_points(gate.rows(out/'points.tsv'),gate.rows(out/'maps.tsv'),out)

if __name__=='__main__':unittest.main()
