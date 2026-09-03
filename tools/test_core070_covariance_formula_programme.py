"""Formula rows cannot change the native model or omit required routes."""
import copy,unittest
from unittest.mock import patch
import core070_evidence as e
import core070_covariance_formula_programme as c

class FormulaCovariance(unittest.TestCase):
    def manifest(self):return e.load_toml(e.DEFAULT_MANIFEST)
    def test_live_bindings(self):
        self.assertEqual(len(c.validate_registry(self.manifest())['cases']),9)
    def test_missing_formula_ids_fail(self):
        m=self.manifest();m.pop('covariance_formula_case_ids')
        with patch.object(e,'load_toml',return_value=m),self.assertRaises(e.EvidenceError):e._load_manifest_metadata(e.DEFAULT_MANIFEST)
    def test_missing_native_or_formula_case_fails(self):
        for cid in [c.IDS[0],c.native.IDS[0]]:
            m=self.manifest();m['executable_case']=[r for r in m['executable_case'] if r['id']!=cid]
            with self.subTest(cid=cid),self.assertRaises(ValueError):c.validate_registry(m)
    def test_modified_contract_or_missing_route_fails(self):
        for key,value in [('model_contract_id','wrong'),('helper_sha256','stale'),('formula_routes',['wide']),('native_dependencies',[]),('acceptance_level','helper_parser_check')]:
            m=self.manifest();r=next(r for r in m['executable_case'] if r['id']==c.IDS[0]);r[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):c.validate_registry(m)
    def test_native_and_formula_do_not_pay_bridge(self):
        import core070_manifest_coverage as v
        m=self.manifest();mapping=copy.deepcopy(v.read_json(e.ROOT/v.MAPPING))
        facts=[f for f in v.read_json(e.ROOT/v.INDEX)['facts'] if f['id']=='covariance/COV-KERNEL-INDEP']
        cases=[r for r in m['executable_case'] if r.get('coverage_role')!='public_r_bridge']
        for row in mapping['rows']:
            if row['source_id']==facts[0]['id']:
                row['executable_case_ids']=[cid for cid in row['executable_case_ids'] if not cid.endswith('-PUBLIC-R-BRIDGE')]
        with self.assertRaisesRegex(v.CoverageError,'covariance interface coverage missing'):v.validate_covariance_roles(facts,mapping,cases,e.ROOT)

if __name__=='__main__':unittest.main()
