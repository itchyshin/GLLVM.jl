"""A bridge subset cannot hide missing evidence or claim programme completion."""
from copy import deepcopy
import unittest
from core070_verify_bridge_bundle import check, STATUSES


class BridgeBundle(unittest.TestCase):
    def fixture(self):
        bundle = {name: dict(status=status) for name, status in STATUSES.items()}
        bundle['models'].update(required_case_ids=['case-a', 'case-b', 'case-c'],
                                subcontract_sha256='synthetic-sha')
        return bundle

    def test_exact_subset(self):
        check(self.fixture(), ['case-a', 'case-b', 'case-c'], 'synthetic-sha')

    def test_missing_failed_and_overclaimed_components(self):
        for name in STATUSES:
            for change in ['missing', 'failed', 'full-parity']:
                bundle = deepcopy(self.fixture())
                if change == 'missing':
                    bundle.pop(name)
                else:
                    bundle[name]['status'] = change
                with self.subTest(name=name, change=change), self.assertRaises(ValueError):
                    check(bundle, ['case-a', 'case-b', 'case-c'], 'synthetic-sha')

    def test_case_identity_pin_and_unknown_component(self):
        for mutate in [lambda b: b['models']['required_case_ids'].pop(),
                       lambda b: b['models'].update(required_case_ids=['case-a'] * 3),
                       lambda b: b['models'].update(subcontract_sha256='stale'),
                       lambda b: b.update(programme={'status': 'PASS'})]:
            bundle = self.fixture()
            mutate(bundle)
            with self.assertRaises(ValueError):
                check(bundle, ['case-a', 'case-b', 'case-c'], 'synthetic-sha')


if __name__ == '__main__':
    unittest.main()
