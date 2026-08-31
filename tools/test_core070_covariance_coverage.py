"""Native covariance fits cannot pay three-interface or rejected-route obligations."""
import copy, tempfile, unittest
from pathlib import Path
import core070_manifest_coverage as c

class CovarianceCoverage(unittest.TestCase):
    def fixture(self):
        temp=tempfile.TemporaryDirectory();self.addCleanup(temp.cleanup)
        root=Path(temp.name);(root/'fixture.jl').write_text('# synthetic structural check, not fitted evidence')
        facts=[dict(id='covariance/COV-KERNEL-INDEP',classification='required_core')]
        cases=[dict(id=role,coverage_role=role,source_fact_ids=[facts[0]['id']],model_contract_id='synthetic',model_contract='synthetic Gaussian kernel',fixture='fixture.jl',r_call='synthetic R',julia_call='synthetic Julia',acceptance_rule='synthetic comparison',acceptance_level='paired_fit' if role=='native_model' else 'paired_fit_interface') for role in ('native_model','formula_interface','public_r_bridge')]
        mapping=dict(rows=[dict(source_id=facts[0]['id'],executable_case_ids=[r['id'] for r in cases])])
        return root,facts,mapping,cases
    def test_native_only_fails(self):
        root,facts,mapping,cases=self.fixture();mapping['rows'][0]['executable_case_ids']=['native_model']
        with self.assertRaisesRegex(c.CoverageError,'covariance interface coverage'):c.validate_covariance_roles(facts,mapping,cases,root)
    def test_three_same_model_interfaces_pass_structure_only(self):
        root,facts,mapping,cases=self.fixture();c.validate_covariance_roles(facts,mapping,cases,root)
    def test_helper_or_changed_model_fails(self):
        for key,value in [('acceptance_level','helper_parser_check'),('model_contract_id','different'),('model_contract','different')]:
            root,facts,mapping,cases=self.fixture();cases[1][key]=value
            with self.subTest(key=key),self.assertRaises(c.CoverageError):c.validate_covariance_roles(facts,mapping,cases,root)
    def test_missing_binding_fails(self):
        root,facts,mapping,cases=self.fixture();cases[0]['source_fact_ids']=[]
        with self.assertRaises(c.CoverageError):c.validate_covariance_roles(facts,mapping,cases,root)
    def test_rejection_requires_explicit_disposition(self):
        root,facts,mapping,cases=self.fixture();facts[0]['classification']='rejected';cases=cases[:1];cases[0]['coverage_role']='reference_boundary';mapping['rows'][0]['executable_case_ids']=['native_model']
        with self.assertRaises(c.CoverageError):c.validate_covariance_roles(facts,mapping,cases,root)
        cases[0]['julia_disposition']='documented_extension';c.validate_covariance_roles(facts,mapping,cases,root)

if __name__=='__main__':unittest.main()
