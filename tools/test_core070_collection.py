"""Synthetic programme receipts emitted by real supervised children; no model claims."""
from copy import deepcopy
import json
import re
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

import core070_evidence as evidence
import core070_targeted_run as supervisor


def toml(data, prefix=()):
    """Encode the scalar/list and nested-table subset used by test receipts."""
    def value_text(value):
        if isinstance(value, list):
            return '[' + ', '.join(value_text(item) for item in value) + ']'
        if isinstance(value, dict):
            return '{' + ', '.join(json.dumps(key)+' = '+value_text(item) for key,item in value.items()) + '}'
        return json.dumps(value)
    out = []
    if prefix:
        out.append('[' + '.'.join(json.dumps(key) for key in prefix) + ']')
    for key, value in data.items():
        if not isinstance(value, dict):
            out.append(json.dumps(key) + ' = ' + value_text(value))
    for key, value in data.items():
        if isinstance(value, dict):
            out.extend(toml(value, prefix + (key,)))
    return out


class Collection(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        original = evidence.ROOT
        # A separate root permits a synthetic frozen contract without editing the real draft.
        for rel in evidence.EXECUTION_STATIC + ('docs/dev-log/core070', 'test/parity/fixtures'):
            src, dst = original / rel, self.root / rel
            if not src.exists():
                continue
            dst.parent.mkdir(parents=True, exist_ok=True)
            if src.is_dir():
                shutil.copytree(src, dst, dirs_exist_ok=True)
            else:
                shutil.copyfile(src, dst)
        draft = evidence.load_manifest(evidence.DEFAULT_MANIFEST)
        self.ids = [row['id'] for row in draft['obligation']]
        self.manifest = self.root / evidence.CONTRACT_REL
        text = self.manifest.read_text().replace('status = "DRAFT_INCOMPLETE_NOT_FROZEN"', 'status = "FROZEN"', 1)
        text = re.sub(r'\n\[\[executable_case\]\][\s\S]*?(?=\n\[|\Z)', '', text)
        text = 'required_case_ids = ' + json.dumps(self.ids) + '\n' + text
        families = {row['id']: row['fixture'] for row in draft['families']}
        for case_id in self.ids:
            fixture = families.get(case_id, draft['families'][0]['fixture'])
            target = self.root / fixture
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(original / fixture, target)
            text += '\n[[executable_case]]\n' + '\n'.join(toml(dict(
                id=case_id, fixture=fixture, fixture_sha256=evidence.digest(target),
                reference_call='synthetic', julia_call='synthetic', model_contract='synthetic', acceptance_rule='synthetic')))
        self.manifest.write_text(text)
        self.addCleanup(patch.stopall)
        patch.object(evidence, 'ROOT', self.root).start()
        # These tests isolate process/receipt collection, not semantic scope.
        # The separate manifest-coverage suite exercises the production loader.
        patch.object(evidence, 'load_manifest', evidence._load_manifest_metadata).start()
        self.frozen = evidence.load_manifest(self.manifest)
        self.cases = {row['id']: row for row in self.frozen['executable_case']}
        build = evidence._oracle_build()
        all_inventory = evidence.execution_inventory(self.cases, self.ids, self.manifest)
        hashes = {row['path']:row['sha256'] for row in all_inventory['entries']}
        self.source = dict(reference_commit=self.frozen['reference_commit'],
            namespace_sha256=self.frozen['reference_namespace_sha256'],
            source_tree_sha256=self.frozen['reference_source_tree_sha256'],
            archive_sha256=self.frozen['reference_archive_sha256'],
            source_marker_sha256=build['marker_sha256'], installed_tree_sha256=build['installed_tree_sha256'],
            oracle_build_receipt_sha256=evidence.digest(evidence.ORACLE_BUILD),
            oracle_source_receipt_sha256=evidence.digest(evidence.ORACLE_SOURCE),
            julia_source_tree_sha256=evidence.tree_digest(self.root/'src'),
            julia_package_path=str(self.root/'src/GLLVM.jl'), julia_package_root=str(self.root),
            julia_project_path=str(self.root/'test/parity/Project.toml'),
            julia_project_sha256=hashes['test/parity/Project.toml'], julia_manifest_sha256='ABSENT',
            julia_version='1.12.6', julia_machine='synthetic', julia_threads=1, blas_threads=1,
            rcall_version='0.14', r_version='synthetic', r_home='/R', r_library_path='/R/library',
            tmb_version='1.9.21', matrix_version='1.7.6')
        self.counter = 0

    def leaf(self, ids, *, exit_code=0, source=None, edit=None, execution_root=None):
        self.counter += 1
        name = 'leaf-' + str(self.counter)
        inventory = evidence.execution_inventory(self.cases, ids, self.manifest)
        cells = {key:dict(id=key, run_id=name, status='success', execution_case_ids=[key], fixture=self.cases[key]['fixture'],
            fixture_sha256=self.cases[key]['fixture_sha256'], assertions=dict(passed=1,failed=0,errored=0,broken=0),
            execution_manifest_sha256=inventory['manifest_sha256'], contract_sha256=evidence.digest(self.manifest)) for key in ids}
        run = dict(status='success', success_marker='CORE070_PARITY_SUCCESS', exit_code=0, run_id=name,
            requested_case_ids=ids, completed_case_ids=ids, actual_assertions=len(ids), assertion_counting='execution_groups_v1',
            source=source or self.source, execution=inventory, contract_sha256=evidence.digest(self.manifest), cells=cells)
        if edit: edit(run)
        files = {'run.toml':'\n'.join(toml(run)), **{'cell-'+key+'.toml':'\n'.join(toml(cell)) for key,cell in cells.items()},
                 'build.json':evidence.ORACLE_BUILD.read_text(), 'source.json':evidence.ORACLE_SOURCE.read_text()}
        child = ('import os,json; from pathlib import Path; p=Path(os.environ["GLLVM_PARITY_RECEIPT_DIR"]); p.mkdir(); '
                 f'files=json.loads({json.dumps(files)!r}); '
                 '[ (p/name).write_text(text) for name,text in files.items() ]; '
                 f'print("synthetic receipt"); raise SystemExit({exit_code})')
        execution_root = execution_root or self.root
        plan = dict(cwd=str(execution_root), pins={r['path']:r['sha256'] for r in inventory['entries']}, timeout_seconds=5,
                    commands=[dict(id=name, argv=[sys.executable,'-c',child], parity_receipts=name)])
        path = self.root/(name+'.json'); path.write_text(json.dumps(plan))
        supervisor.run(path,self.root/(name+'-process'))
        return dict(receipts=str(execution_root/name), process_receipt=name+'-process/process-receipt.json')

    def verify(self, rows):
        collection = self.root/'collection.json'
        collection.write_text(json.dumps(dict(contract_sha256=evidence.digest(self.manifest), runs=rows)))
        self.assertTrue(hasattr(evidence, 'verify_collection'), 'missing bounded-run collection verifier')
        return evidence.verify_collection(collection, self.manifest)

    def test_two_disjoint_runs_certify_complete_collection_only(self):
        rows = [self.leaf(self.ids[:17]), self.leaf(self.ids[17:])]
        report = self.verify(rows)
        self.assertEqual(report['status'], 'PASS')
        self.assertEqual(report['required_cells'], len(self.ids))
        self.assertEqual(report['actual_assertions'], len(self.ids))
        self.assertEqual(len(report['runs']), 2)
        with self.assertRaisesRegex(evidence.EvidenceError,'INCOMPLETE_PROGRAMME'):
            evidence.verify(self.root/rows[0]['receipts'],self.manifest,self.root/rows[0]['process_receipt'])

    def test_collection_counts_shared_execution_once_and_rejects_inflation(self):
        fixtures = {}
        for id,cell in self.cases.items():fixtures.setdefault(cell['fixture'], []).append(id)
        members = sorted(next(ids[:2] for ids in fixtures.values() if len(ids) >= 2))
        def grouped(run):
            for id in members:run['cells'][id]['execution_case_ids'] = members
            run['actual_assertions'] -= 1
        row = self.leaf(self.ids, edit=grouped)
        self.assertEqual(self.verify([row])['actual_assertions'], len(self.ids)-1)
        def inflated(run):
            grouped(run);run['actual_assertions'] += 1
        with self.assertRaisesRegex(evidence.EvidenceError, 'INVALID_ASSERTION_TOTAL'):
            self.verify([self.leaf(self.ids, edit=inflated)])
        with self.assertRaisesRegex(evidence.EvidenceError, 'MISSING_EXECUTION_GROUP_SCHEMA'):
            self.verify([self.leaf(self.ids, edit=lambda run:run.pop('assertion_counting'))])

    def test_missing_duplicate_and_empty_collections_reject(self):
        row = self.leaf(self.ids[:17])
        for rows, marker in [([], 'EMPTY_COLLECTION'), ([row], 'INCOMPLETE_PROGRAMME'), ([row,row], 'DUPLICATE')]:
            with self.subTest(marker=marker), self.assertRaisesRegex(evidence.EvidenceError,marker):self.verify(rows)

    def test_external_failure_and_omitted_process_receipt_reject(self):
        rows=[self.leaf(self.ids[:17]),self.leaf(self.ids[17:],exit_code=7)]
        with self.assertRaisesRegex(evidence.EvidenceError,'EXTERNAL_PROCESS'):self.verify(rows)
        rows[0].pop('process_receipt')
        with self.assertRaisesRegex(evidence.EvidenceError,'MISSING_PROCESS'):self.verify(rows)

    def test_runtime_mismatch_and_stale_contract_reject(self):
        changed=deepcopy(self.source); changed['julia_version']='1.12.7'
        rows=[self.leaf(self.ids[:17]),self.leaf(self.ids[17:],source=changed)]
        with self.assertRaisesRegex(evidence.EvidenceError,'MIXED_RUNTIME'):self.verify(rows)
        rows=[rows[0],self.leaf(self.ids[17:],edit=lambda run:run.update(contract_sha256='0'*64))]
        with self.assertRaisesRegex(evidence.EvidenceError,'STALE_CONTRACT'):self.verify(rows)

    def test_identical_checkout_relocated_with_its_supervisor_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            other=Path(tmp)/'checkout'; shutil.copytree(self.root,other)
            changed=deepcopy(self.source)
            for key in ('julia_package_path','julia_package_root','julia_project_path'):
                changed[key]=changed[key].replace(str(self.root),str(other))
            changed['r_home']='/relocated/R'; changed['r_library_path']='/relocated/R/library'
            rows=[self.leaf(self.ids[:17]),self.leaf(self.ids[17:],source=changed,execution_root=other)]
            self.assertEqual(self.verify(rows)['status'],'PASS')
            # Moving the claimed root without moving the actual supervised checkout fails.
            rows[1]=self.leaf(self.ids[17:],source=changed)
            with self.assertRaisesRegex(evidence.EvidenceError,'WRONG_LOADED_ROOT'):self.verify(rows)

    def test_failed_assertion_cannot_hide_behind_success_marker(self):
        def fail(run):run['cells'][self.ids[-1]]['assertions']['failed']=1
        rows=[self.leaf(self.ids[:17]),self.leaf(self.ids[17:],edit=fail)]
        with self.assertRaisesRegex(evidence.EvidenceError,'INVALID_ASSERTIONS'):self.verify(rows)

    def test_missing_cell_and_stale_source_reject(self):
        rows=[self.leaf(self.ids[:17]),self.leaf(self.ids[17:])]
        self.verify(rows)
        cell=self.root/rows[0]['receipts']/('cell-'+self.ids[0]+'.toml')
        retained=cell.read_bytes(); cell.unlink()
        with self.assertRaisesRegex(evidence.EvidenceError,'MISSING_OR_EXTRA_CELL'):self.verify(rows)
        cell.write_bytes(retained)
        source=self.root/'src/GLLVM.jl'; source.write_text(source.read_text()+'\n# changed\n')
        with self.assertRaisesRegex(evidence.EvidenceError,'STALE_EXECUTION'):self.verify(rows)

    def test_unknown_case_and_duplicate_frozen_rows_reject(self):
        rows=[self.leaf(self.ids)]
        self.verify(rows)
        run,cells=evidence._load_receipts(self.root/rows[0]['receipts'])
        unknown=deepcopy(run); unknown['requested_case_ids']=['UNKNOWN']
        with self.assertRaisesRegex(evidence.EvidenceError,'INCOMPLETE_PROGRAMME'):
            evidence._verify_loaded(unknown,cells,self.frozen,self.manifest,required_subset=True)
        duplicate=deepcopy(self.frozen); duplicate['executable_case'].append(duplicate['executable_case'][0])
        with self.assertRaisesRegex(evidence.EvidenceError,'INCOMPLETE_PROGRAMME'):
            evidence._verify_loaded(run,cells,duplicate,self.manifest,required_subset=True)


if __name__ == '__main__':unittest.main()
