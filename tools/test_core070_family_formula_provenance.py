"""The formula red baseline may drift only in the programme-wide case count."""
import unittest

from core070_verify_family_formulas import registry_test_without_programme_count


class FormulaRedProvenance(unittest.TestCase):
    def test_programme_count_is_normalized(self):
        old = "@test length(requested_ids()) == 23\n@test length(INTERFACE_IDS) == 5\n"
        new = "@test length(requested_ids()) == 41\n@test length(INTERFACE_IDS) == 5\n"
        self.assertEqual(registry_test_without_programme_count(old),
                         registry_test_without_programme_count(new))

    def test_formula_assertion_change_is_not_normalized(self):
        old = "@test length(requested_ids()) == 23\n@test length(INTERFACE_IDS) == 5\n"
        new = "@test length(requested_ids()) == 41\n@test length(INTERFACE_IDS) == 6\n"
        self.assertNotEqual(registry_test_without_programme_count(old),
                            registry_test_without_programme_count(new))

    def test_missing_or_duplicate_count_fails(self):
        for text in ("@test length(INTERFACE_IDS) == 5\n",
                     "@test length(requested_ids()) == 23\n@test length(requested_ids()) == 41\n"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                registry_test_without_programme_count(text)


if __name__ == '__main__':
    unittest.main()
