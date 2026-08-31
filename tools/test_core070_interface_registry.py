"""The separate interface registry cannot silently disappear or enter family totals."""
import copy, unittest
import core070_manifest_coverage as coverage
from unittest.mock import patch
import core070_evidence as gate

class InterfaceRegistry(unittest.TestCase):
    def test_real_contract(self):
        d=gate.load_manifest(gate.DEFAULT_MANIFEST)
        self.assertEqual(len(d['families']),17)
        self.assertEqual(len(d['interfaces']),5)
        self.assertEqual(len(d['models']),1)
    def test_formula_only_binds_original_dgp(self):
        d=gate.load_manifest(gate.DEFAULT_MANIFEST)
        cases={row['id']:row for row in d['interfaces']}
        inventory=gate.execution_inventory(cases,d['interface_case_ids'],gate.DEFAULT_MANIFEST)
        paths={row['path'] for row in inventory['entries']}
        self.assertIn('test/parity/test_negbin_parity.jl',paths)
        self.assertIn('test/parity/test_nb2_formula_parity.jl',paths)
        self.assertIn('test/parity/nb2_health.jl',paths)
        self.assertIn('test/parity/fixtures/core070_gaussian_original.toml',paths)
        self.assertIn('test/parity/fixtures/core070_gaussian_reference.R',paths)

    def test_registry_corruptions(self):
        original=gate.load_manifest(gate.DEFAULT_MANIFEST)
        changes=[
            lambda d:d.update(interface_case_ids=[],interfaces=[]),
            lambda d:d['interface_case_ids'].append(d['interface_case_ids'][0]),
            lambda d:d['families'].append(copy.deepcopy(d['families'][0])),
            lambda d:d['interface_case_ids'].__setitem__(0,d['family_smoke_case_ids'][0]),
            lambda d:d['interfaces'][0].update(fixture=''),
            lambda d:d['interfaces'][0].update(model_contract_id=''),
            lambda d:d.update(model_case_ids=[],models=[]),
            lambda d:d['models'][0].update(role='formula_interface'),
            lambda d:d['models'][0].update(fixture=''),
        ]
        for i,change in enumerate(changes):
            with self.subTest(corruption=i):
                d=copy.deepcopy(original);change(d)
                with patch.object(gate,'load_toml',return_value=d),self.assertRaises(gate.EvidenceError):
                    gate._load_manifest_metadata(gate.DEFAULT_MANIFEST)
    def test_gaussian_bridge_remains_required(self):
        d=gate.load_manifest(gate.DEFAULT_MANIFEST)
        index=coverage.read_json(gate.ROOT/coverage.INDEX)
        facts=[f for f in index['facts'] if f['id']=='family/FAMILY-00-IDENTITY']
        mapping=coverage.read_json(gate.ROOT/coverage.MAPPING)
        # Removing the declared bridge case must still leave this model unpaid.
        for row in mapping['rows']:
            row['executable_case_ids']=[cid for cid in row['executable_case_ids'] if cid!='CORE070-FAMILY-00-IDENTITY-PUBLIC-R-BRIDGE']
        with self.assertRaisesRegex(coverage.CoverageError,'family interface coverage missing'):
            coverage.validate_family_roles(facts,mapping,d['executable_case'],gate.ROOT)

if __name__=='__main__':unittest.main()
