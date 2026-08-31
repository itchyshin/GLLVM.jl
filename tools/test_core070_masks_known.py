"""A required reference contract must reject missing or corrupted evidence."""
import contextlib,copy,io,json,tempfile,unittest,shutil
from pathlib import Path
from unittest.mock import patch
import core070_verify_masks_known as gate

class MasksKnownEvidence(unittest.TestCase):
 def test_positive(self):
  with contextlib.redirect_stdout(io.StringIO()):gate.verify()
 def test_point_corruption(self):
  out=gate.STATE/gate.RUNS[-1]/'attempt1/out'
  for defect in ['omitted','bad-nll','bad-gradient','bad-map','freed-pin','known-dropped','bad-pin']:
   with self.subTest(defect=defect):
    points=gate.rows(out/'points.tsv');maps=gate.rows(out/'maps.tsv')
    if defect=='omitted':points.pop()
    elif defect=='bad-nll':points[0]['delta']='1'
    elif defect=='bad-gradient':points[0]['gradient_error']='1'
    elif defect=='bad-map':maps[0]['map']='1,2,3,4,5'
    elif defect=='freed-pin':maps[3]['free_loadings']='5'
    elif defect=='bad-pin':maps[0]['pins']='0.7,0'
    else:points[8]['drop_known_delta']='0'
    with self.assertRaises(ValueError):gate.verify_points(points,maps,out)
 def test_observation_and_matrix_corruption(self):
  original=gate.STATE/gate.RUNS[-1]/'attempt1/out'
  for defect in ['missing-jitter','wrong-block','wrong-y','wrong-trait','wrong-parameter','wrong-covariance']:
   with self.subTest(defect=defect),tempfile.TemporaryDirectory() as folder:
    out=Path(folder)/'out';shutil.copytree(original,out)
    selected='KNOWN-BLOCK-P1'
    if defect in ['wrong-y','wrong-trait']:
     p=out/selected/'observations.tsv';data=gate.rows(p);data[0]['y' if defect=='wrong-y' else 'trait']='99'
    elif defect=='wrong-parameter':
     p=out/selected/'parameters.tsv';data=gate.rows(p);data[0]['value']='99'
    else:
     p=out/selected/('covariance.tsv' if defect=='wrong-covariance' else 'source.tsv');data=gate.rows(p)
     data[0][list(data[0])[0 if defect=='missing-jitter' else 1]]='0.1' if defect=='missing-jitter' else '99'
    import csv
    with p.open('w') as stream:
     w=csv.DictWriter(stream,fieldnames=list(data[0]),delimiter='\t');w.writeheader();w.writerows(data)
    with self.assertRaises(ValueError):gate.verify_points(gate.rows(out/'points.tsv'),gate.rows(out/'maps.tsv'),out)
 def test_bad_process(self):
  for defect in ['nonzero','stale','missing-dependency']:
   with self.subTest(defect=defect),tempfile.TemporaryDirectory() as folder:
    state=Path(folder);shutil.copytree(gate.STATE/gate.RUNS[1],state/gate.RUNS[1])
    p=state/gate.RUNS[1]/'attempt1/process/process-receipt.json';r=gate.load(p)
    if defect=='nonzero':r['results'][1]['exit_code']=9
    elif defect=='stale':r['source_unchanged']=False
    else:r['source_pins'].pop('tools/core070_fit_input.R')
    p.write_text(json.dumps(r))
    with patch.object(gate,'STATE',state),self.assertRaises(ValueError):gate.verify_process(gate.RUNS[1],0,True)
 def test_scope_or_missing_receipt(self):
  original=gate.load;path=gate.ROOT/gate.EVIDENCE
  for defect in ['scope','case','receipt','source']:
   with self.subTest(defect=defect):
    e=copy.deepcopy(original(path))
    if defect=='scope':e['status']='FULL_PARITY_PASS'
    elif defect=='case':e['case_ids'].pop()
    elif defect=='source':e['reference_source_pins'].clear()
    else:e['retained_artifacts'].pop(next(iter(e['retained_artifacts'])))
    with patch.object(gate,'load',side_effect=lambda p:e if p==path else original(p)),self.assertRaises(ValueError):gate.verify()
 def test_historical_failure_is_not_success(self):
  with self.assertRaises(ValueError):gate.verify_process(gate.RUNS[0],0,False)

if __name__=='__main__':unittest.main()
