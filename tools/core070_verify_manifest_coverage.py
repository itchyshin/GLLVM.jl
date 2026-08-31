"""Inspect current draft coverage; historical receipts are not live inputs.

This gate checks census and mapping integrity, not complete model coverage.
Freezing remains governed by core070_manifest_coverage.require_frozen_manifest.
"""
import argparse
from collections import Counter
from datetime import datetime, timezone
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import core070_evidence as evidence
import core070_manifest_coverage as coverage

ROOT = Path(__file__).resolve().parents[1]
TESTS = [('test_core070_manifest_coverage.py', 6),
         ('test_core070_collection.py', 9),
         ('test_core070_assertion_groups.py', 4),
         ('test_core070_process_evidence.py', 5),
         ('test_core070_verify_manifest_coverage.py', 6)]


def run(argv, count=None):
    result = subprocess.run(argv, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=40)
    coverage.need(result.returncode == 0, result.stdout)
    if count is not None:
        coverage.need(re.search(r'Ran ' + str(count) + r' tests? in ', result.stdout),
                      result.stdout)
    print(result.stdout)


def inspect_draft(index, mapping, manifest):
    """Account for unmapped draft facts without accepting malformed bindings."""
    need = coverage.need
    need(manifest.get('status') == 'DRAFT_INCOMPLETE_NOT_FROZEN',
         'draft inspection cannot certify a frozen contract')
    need(index.get('reference_commit') == mapping.get('reference_commit') == coverage.REFERENCE,
         'reference pin drift')
    facts = {fact['id']: fact for fact in index['facts']}
    rows = mapping.get('rows')
    need(isinstance(rows, list) and len(rows) == len(facts) == len(index['facts']),
         'missing or duplicate census/map rows')
    need({row.get('source_id') for row in rows} == set(facts), 'source IDs differ')
    cases = [case.get('id') for case in manifest.get('executable_case', [])]
    need(all(isinstance(case, str) and case.strip() for case in cases)
         and len(cases) == len(set(cases)), 'invalid executable case IDs')
    linked = set()
    unmapped = 0
    bindings = 0
    for row in rows:
        need(row.get('classification') == facts[row['source_id']]['classification'],
             'source classification drift')
        need(isinstance(row.get('rationale'), str) and row['rationale'].strip(),
             'missing mapping rationale')
        ids = row.get('executable_case_ids')
        need(isinstance(ids, list) and all(isinstance(case, str) for case in ids),
             'invalid case links')
        need(len(ids) == len(set(ids)) and set(ids) <= set(cases),
             'duplicate or unknown executable case')
        linked.update(ids)
        bindings += len(ids)
        unmapped += not ids and row['classification'] not in {'intentionally_excluded', 'R-only presentation'}
    need(linked == set(cases), 'unaccounted executable cases')
    return dict(source_facts=len(facts), nonexcluded_unmapped=unmapped,
                executable_bindings=bindings,
                classification_counts=dict(sorted(Counter(f['classification'] for f in facts.values()).items())))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, help='Write a new receipt; refuse to overwrite evidence.')
    args = parser.parse_args()
    index = coverage.build_index(ROOT)
    coverage.need(index == coverage.read_json(ROOT / coverage.INDEX), 'saved census is stale')
    manifest = evidence.load_manifest(evidence.DEFAULT_MANIFEST)
    result = inspect_draft(index, coverage.read_json(ROOT / coverage.MAPPING), manifest)
    # Capture source bytes before running children, then reject concurrent edits.
    paths = set(index['inventories']) | {coverage.INDEX, coverage.MAPPING,
            str(evidence.DEFAULT_MANIFEST.relative_to(ROOT))}
    paths.update(str(path.relative_to(ROOT)) for path in (ROOT / 'tools').glob('*core070*.py'))
    paths.add('tools/core070_data_case_index.R')
    pins = {name: coverage.sha(coverage.safe_path(ROOT, name)) for name in sorted(paths)}
    for pattern, count in TESTS:
        run([sys.executable, '-m', 'unittest', 'discover', '-s', 'tools', '-p', pattern], count)
    run([sys.executable, 'tools/core070_evidence.py', '--self-test'])
    with tempfile.TemporaryDirectory() as folder:
        path = Path(folder) / 'false-frozen.toml'
        path.write_text(evidence.DEFAULT_MANIFEST.read_text().replace(
            'status = "DRAFT_INCOMPLETE_NOT_FROZEN"', 'status = "FROZEN"', 1))
        try:
            evidence.load_manifest(path)
        except evidence.EvidenceError as error:
            coverage.need('SOURCE_COVERAGE' in str(error), str(error))
        else:
            raise coverage.CoverageError('SOURCE_COVERAGE: label-only freeze accepted')
    for name, pin in pins.items():
        coverage.need(coverage.sha(coverage.safe_path(ROOT, name)) == pin, 'input changed during verification: ' + name)
    result.update(status='CURRENT_DRAFT_INTEGRITY_VERIFIED_NOT_PARITY_COMPLETE',
                  reference_commit=coverage.REFERENCE,
                  verified_at=datetime.now(timezone.utc).isoformat(),
                  test_count=sum(count for _, count in TESTS), artifacts=pins)
    if args.output:
        with args.output.open('x') as handle:
            json.dump(result, handle, indent=2)
            handle.write('\n')
    print(json.dumps({key: value for key, value in result.items() if key != 'artifacts'}, sort_keys=True))
    print('SOURCE_CASE_COVERAGE_GATE_VERIFIED_FULL_MANIFEST_UNFROZEN')


if __name__ == '__main__':
    main()
