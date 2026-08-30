"""A frozen label is not a complete, reviewed source-to-case contract."""
from copy import deepcopy
import json
from unittest.mock import patch
import tempfile
from pathlib import Path
import unittest
import core070_evidence as evidence
import core070_manifest_coverage as coverage

class ManifestCoverage(unittest.TestCase):
    def test_relabelled_draft_cannot_load_as_frozen(self):
        text=evidence.DEFAULT_MANIFEST.read_text().replace('status = "DRAFT_INCOMPLETE_NOT_FROZEN"','status = "FROZEN"',1)
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'false-frozen.toml';path.write_text(text)
            with self.assertRaisesRegex(evidence.EvidenceError,'SOURCE_COVERAGE'):
                evidence.load_manifest(path)


    def test_known_source_inventory_matches_live_pinned_inputs(self):
        saved=coverage.read_json(evidence.ROOT/coverage.INDEX)
        self.assertEqual(saved,coverage.build_index(evidence.ROOT))
        self.assertEqual(len(saved['facts']),752)
        self.assertEqual(sum(f['classification']!='intentionally_excluded' for f in saved['facts']),698)

    def test_mapping_positive_and_negative_controls(self):
        facts=[dict(id='family/ok',classification='required_core'),dict(id='family/no',classification='rejected'),
               dict(id='family/parked',classification='intentionally_excluded')]
        mapping=dict(reference_commit=coverage.REFERENCE,rows=[
          dict(source_id=f['id'],classification=f['classification'],executable_case_ids=ids,rationale=reason)
          for f,ids,reason in zip(facts,[['fit'],['negative'],[]],['same model','same rejection','user-approved exclusion'])])
        coverage.validate_mapping(mapping,facts,['fit','negative'])
        for mutation in ['omit_fact','duplicate_fact','erase_case','unknown_case','class_drift','blank_reason','orphan_case','reference','bad_rows']:
            bad=deepcopy(mapping);cases=['fit','negative']
            if mutation=='omit_fact':bad['rows'].pop()
            elif mutation=='duplicate_fact':bad['rows'].append(bad['rows'][0])
            elif mutation=='erase_case':bad['rows'][0]['executable_case_ids']=[]
            elif mutation=='unknown_case':bad['rows'][0]['executable_case_ids']=['invented']
            elif mutation=='class_drift':bad['rows'][0]['classification']='intentionally_excluded'
            elif mutation=='blank_reason':bad['rows'][0]['rationale']=' '
            elif mutation=='orphan_case':cases.append('unaccounted')
            elif mutation=='reference':bad['reference_commit']='0'*40
            else:bad['rows']=None
            with self.subTest(mutation=mutation),self.assertRaises(coverage.CoverageError):
                coverage.validate_mapping(bad,facts,cases)

    def test_actual_unmapped_source_fact_prevents_freeze(self):
        index=coverage.read_json(evidence.ROOT/coverage.INDEX)
        mapping=coverage.read_json(evidence.ROOT/coverage.MAPPING)
        with self.assertRaisesRegex(coverage.CoverageError,'unmapped required or negative case'):
            coverage.validate_mapping(mapping,index['facts'],['fake-complete-case'])

    def test_artifact_escape_and_missing_review_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder)
            for name in ['../outside','/absolute','missing']:
                with self.subTest(name=name),self.assertRaises(coverage.CoverageError):coverage.safe_path(root,name)
            with self.assertRaisesRegex(coverage.CoverageError,'no source-to-case coverage binding'):
                coverage.require_frozen_manifest({'status':'FROZEN'},root)


    def test_pinned_review_and_mapping_positive_then_stale_negative(self):
        # A tiny fixture exercises the closure mechanism, not actual programme scope.
        facts=[dict(id='test/required',classification='required_core')]
        index=dict(facts=facts)
        mapping=dict(reference_commit=coverage.REFERENCE,rows=[dict(source_id='test/required',classification='required_core',executable_case_ids=['case'],rationale='synthetic same-model case')])
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);(root/coverage.PREFIX).mkdir(parents=True)
            (root/coverage.INDEX).write_text(json.dumps(index));(root/coverage.MAPPING).write_text(json.dumps(mapping))
            report=root/'review.txt';report.write_text('Synthetic review fixture; not a programme review.')
            review=dict(status='ACCEPTED',reference_commit=coverage.REFERENCE,index_sha256=coverage.sha(root/coverage.INDEX),mapping_sha256=coverage.sha(root/coverage.MAPPING),reviewed_domains=sorted(coverage.DOMAINS),unresolved=[],reviewer='synthetic fixture',evidence='review.txt',evidence_sha256=coverage.sha(report))
            (root/'review.json').write_text(json.dumps(review))
            manifest=dict(executable_case=[dict(id='case')],source_coverage=dict(index=coverage.INDEX,mapping=coverage.MAPPING,index_sha256=coverage.sha(root/coverage.INDEX),mapping_sha256=coverage.sha(root/coverage.MAPPING),scope_review='review.json',scope_review_sha256=coverage.sha(root/'review.json')))
            with patch.object(coverage,'build_index',return_value=index):
                coverage.require_frozen_manifest(manifest,root)
                for mutation in ['map_pin','review_pin','omitted_domain','review_evidence']:
                    changed=deepcopy(manifest);changed_review=deepcopy(review)
                    if mutation=='map_pin':changed['source_coverage']['mapping_sha256']='0'*64
                    elif mutation=='review_pin':changed['source_coverage']['scope_review_sha256']='0'*64
                    elif mutation=='omitted_domain':
                        changed_review['reviewed_domains'].pop()
                        (root/'review.json').write_text(json.dumps(changed_review))
                        changed['source_coverage']['scope_review_sha256']=coverage.sha(root/'review.json')
                    else:report.write_text('Changed evidence without matching approval.')
                    with self.subTest(mutation=mutation),self.assertRaises(coverage.CoverageError):coverage.require_frozen_manifest(changed,root)
                    (root/'review.json').write_text(json.dumps(review));report.write_text('Synthetic review fixture; not a programme review.')

if __name__=='__main__':unittest.main()
