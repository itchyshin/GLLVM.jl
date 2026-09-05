#!/usr/bin/env python3
"""Smoke: parity tools default to frozen gllvmTMB 0.7.0 oracle (P13)."""
import argparse
import subprocess
import sys
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))

import parity_oracle  # noqa: E402
import parity_ledger  # noqa: E402


class ParityOracleDefaults(unittest.TestCase):
    def test_frozen_oracle_constant(self):
        self.assertEqual(
            parity_oracle.FROZEN_GLLVMTMB_ORACLE,
            "b4d5fee64def88bc768dda1f1f77c29b295edd86",
        )
        self.assertEqual(parity_oracle.DEFAULT_R_REF, parity_oracle.FROZEN_GLLVMTMB_ORACLE)
        self.assertEqual(parity_ledger.DEFAULT_REF, parity_oracle.DEFAULT_R_REF)

    def test_argparse_defaults(self):
        ap = argparse.ArgumentParser()
        ap.add_argument("--ref", default=parity_ledger.DEFAULT_REF)
        ap.add_argument("--r-ref", default=None)
        ns = ap.parse_args([])
        self.assertEqual(ns.ref, parity_oracle.FROZEN_GLLVMTMB_ORACLE)
        self.assertIsNone(ns.r_ref)

    def test_self_test_passes(self):
        out = subprocess.run(
            [sys.executable, str(TOOLS / "parity_ledger.py"), "--self-test"],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(out.returncode, 0, out.stderr or out.stdout)
        self.assertIn("SELFTEST_OK", out.stdout)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
