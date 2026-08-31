"""Family scope cannot be paid with entry probes or one interface alone."""
import copy, json, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
import core070_manifest_coverage as c

class FamilyCoverage(unittest.TestCase):
    def freeze_fixture(self, cases):
        temp = tempfile.TemporaryDirectory(); self.addCleanup(temp.cleanup)
        root = Path(temp.name); (root / c.PREFIX).mkdir(parents=True)
        fact = dict(id='family/FAMILY-05-LOG', classification='required_core')
        index = dict(facts=[fact])
        mapping = dict(reference_commit=c.REFERENCE, rows=[dict(source_id=fact['id'],
            classification='required_core', executable_case_ids=[r['id'] for r in cases],
            rationale='Synthetic family scope fixture, not scientific evidence.')])
        (root/c.INDEX).write_text(json.dumps(index)); (root/c.MAPPING).write_text(json.dumps(mapping))
        (root/'review.txt').write_text('Synthetic review fixture only.')
        review = dict(status='ACCEPTED', reference_commit=c.REFERENCE,
            index_sha256=c.sha(root/c.INDEX), mapping_sha256=c.sha(root/c.MAPPING),
            reviewed_domains=sorted(c.DOMAINS), unresolved=[], reviewer='synthetic',
            evidence='review.txt', evidence_sha256=c.sha(root/'review.txt'))
        (root/'review.json').write_text(json.dumps(review))
        manifest = dict(executable_case=cases, source_coverage=dict(index=c.INDEX,
            mapping=c.MAPPING, index_sha256=c.sha(root/c.INDEX),
            mapping_sha256=c.sha(root/c.MAPPING), scope_review='review.json',
            scope_review_sha256=c.sha(root/'review.json')))
        return root, index, manifest

    def test_entry_probe_cannot_freeze_family_coverage(self):
        root,index,manifest = self.freeze_fixture([dict(id='probe',coverage_role='entry_probe')])
        with patch.object(c,'build_index',return_value=index):
            with self.assertRaisesRegex(c.CoverageError,'family interface coverage'):
                c.require_frozen_manifest(manifest,root)

    def model_cases(self):
        return [dict(id=role, coverage_role=role, source_fact_ids=['family/FAMILY-05-LOG'],
            model_contract_id='synthetic-NB2',fixture='fixture.jl',r_call='synthetic R call',
            model_contract='synthetic original NB2 model definition',
            julia_call='synthetic '+role,acceptance_rule='synthetic numerical rule',
            acceptance_level='paired_fit' if role=='native_model' else 'paired_fit_interface')
            for role in ['native_model','formula_interface','public_r_bridge']]

    def test_three_bound_interfaces_can_pass_structural_gate(self):
        root,index,manifest=self.freeze_fixture(self.model_cases())
        (root/'fixture.jl').write_text('# synthetic fixture, no actual fit')
        with patch.object(c,'build_index',return_value=index):
            c.require_frozen_manifest(manifest,root)

    def test_multiple_models_each_need_all_interfaces(self):
        cases=self.model_cases()
        extra=copy.deepcopy(cases)
        for row in extra:
            row['id']+='-variant';row['model_contract_id']='synthetic-NB2-variant'
        root,index,manifest=self.freeze_fixture(cases+extra)
        (root/'fixture.jl').write_text('# synthetic')
        with patch.object(c,'build_index',return_value=index):
            c.require_frozen_manifest(manifest,root)

    def test_weaker_or_unbound_cases_fail(self):
        for mutation in ['omit_formula','entry_only','different_model','missing_fixture','missing_call','missing_source']:
            cases=self.model_cases()
            if mutation=='omit_formula':cases.pop(1)
            elif mutation=='entry_only':cases[0]['acceptance_level']='entry_probe'
            elif mutation=='different_model':cases[1]['model_contract_id']='different'
            elif mutation=='missing_fixture':cases[0]['fixture']='missing.jl'
            elif mutation=='missing_call':cases[1]['julia_call']=''
            else:cases[2]['source_fact_ids']=[]
            root,index,manifest=self.freeze_fixture(cases)
            (root/'fixture.jl').write_text('# synthetic')
            with self.subTest(mutation=mutation),patch.object(c,'build_index',return_value=index):
                with self.assertRaises(c.CoverageError):c.require_frozen_manifest(manifest,root)

    def test_rejected_reference_does_not_force_rejecting_julia_extensions(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);(root/'negative.jl').write_text('# synthetic')
            facts=[dict(id='family/rejected',classification='rejected')]
            mapping=dict(rows=[dict(source_id=facts[0]['id'],executable_case_ids=['negative'])])
            cases=[dict(id='negative',coverage_role='reference_boundary',source_fact_ids=['family/rejected'],
                model_contract_id='boundary',fixture='negative.jl',r_call='R rejects',julia_call='Julia extension',
                acceptance_rule='explicit supported extension',julia_disposition='documented_extension')]
            c.validate_family_roles(facts,mapping,cases,root)
            cases[0]['julia_disposition']='UNRESOLVED'
            with self.assertRaises(c.CoverageError):c.validate_family_roles(facts,mapping,cases,root)

if __name__ == '__main__': unittest.main()
