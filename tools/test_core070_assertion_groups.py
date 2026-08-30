"""Do not confuse per-family attribution with independent executed assertions."""
from copy import deepcopy
import unittest
import core070_evidence as evidence


class ExecutionGroups(unittest.TestCase):
    def cells(self):
        return {id: dict(execution_case_ids=['a','b','c'], fixture='shared.jl',
            fixture_sha256='abc', assertions=dict(passed=28,failed=0,errored=0,broken=0))
            for id in ['a','b','c']}

    def test_shared_execution_counts_once(self):
        self.assertEqual(evidence.execution_assertion_counts(self.cells()),
                         dict(passed=28,failed=0,errored=0,broken=0))

    def test_same_file_independent_executions_count_separately(self):
        cells=self.cells()
        for id,cell in cells.items():cell['execution_case_ids']=[id]
        cells['b']['assertions']['passed']=2
        self.assertEqual(evidence.execution_assertion_counts(cells)['passed'],58)

    def test_shared_failure_is_retained_once(self):
        cells=self.cells()
        for cell in cells.values():cell['assertions']['failed']=1
        self.assertEqual(evidence.execution_assertion_counts(cells)['failed'],1)

    def test_malformed_groups_are_rejected(self):
        mutations=[
            lambda c:c['a'].pop('execution_case_ids'),
            lambda c:c['a'].update(execution_case_ids=[]),
            lambda c:c['a'].update(execution_case_ids=['b','c']),
            lambda c:c['a'].update(execution_case_ids=['a','a','b','c']),
            lambda c:c['a'].update(execution_case_ids=['a','b','unknown']),
            lambda c:c['b'].update(execution_case_ids=['b']),
            lambda c:c.pop('c'),
            lambda c:c['b'].update(fixture='other.jl'),
            lambda c:c['b'].update(fixture_sha256='changed'),
            lambda c:c['b']['assertions'].update(passed=29),
            lambda c:c['b']['assertions'].update(passed=True),
        ]
        for mutate in mutations:
            with self.subTest(mutation=mutate):
                cells=self.cells();mutate(cells)
                with self.assertRaises(evidence.EvidenceError):evidence.execution_assertion_counts(cells)


if __name__=='__main__':unittest.main()
