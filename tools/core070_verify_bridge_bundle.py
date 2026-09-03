"""Reverify separate public R bridge receipts without claiming full parity.

This is a bounded evidence bundle, not the full manifest acceptance gate. Its
components intentionally distinguish runtime, same-model fits, model change,
and descriptor rejection. No component reads a cached summary as proof.
"""
import argparse
import json
from pathlib import Path
from core070_verify_bridge_descriptors import ROOT, sha, need, verify as descriptors
from core070_verify_bridge_runtime import verify as runtime
from core070_verify_bridge_models import verify as models
from core070_verify_gaussian_bridge_boundary import verify as gaussian

STATUSES = {
    'runtime': 'RUNTIME_ONLY_VERIFIED_NOT_MODEL_PARITY',
    'models': 'THREE_MODEL_BRIDGE_QUALIFICATION_NOT_FULL_PARITY',
    'gaussian': 'VERIFIED_REFERENCE_MODEL_CHANGE_NOT_PARITY',
    'descriptors': 'VERIFIED_DESCRIPTOR_OBSERVATIONS_NOT_MODEL_PARITY',
}


def check(bundle, required_ids, contract_sha):
    need(set(bundle) == set(STATUSES), 'missing or unknown component')
    for name, status in STATUSES.items():
        need(bundle[name].get('status') == status, 'failed or overclaimed component ' + name)
    need(bundle['models'].get('required_case_ids') == required_ids and
         len(set(required_ids)) == len(required_ids) == 3, 'required bridge case IDs differ')
    need(bundle['models'].get('subcontract_sha256') == contract_sha, 'stale model subcontract')


def verify(self_test=False):
    path = ROOT / 'docs/dev-log/core070/public-bridge-required-cases.json'
    contract = json.loads(path.read_text())
    bundle = dict(runtime=runtime(self_test), models=models(self_test),
                  gaussian=gaussian(self_test), descriptors=descriptors(self_test))
    check(bundle, contract['required_case_ids'], sha(path))
    print('BRIDGE_BOUNDED_BUNDLE_VERIFIED_FULL_PROGRAMME_UNPAID')
    return dict(status='BOUNDED_BRIDGE_EVIDENCE_VERIFIED_NOT_FULL_PARITY',
        scope='Runtime, three original model cases, Gaussian model-change boundary, and 69 descriptors.',
        reference_commit=contract['reference_commit'], components=bundle,
        remaining='Model-specific admission in full manifest, remaining interfaces/models, independent '
                  'scope review, full package checks, recovery/coverage, performance, final documentation.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = verify(args.self_test)
    if args.output:
        with args.output.open('x') as handle:
            json.dump(result, handle, indent=2)
            handle.write('\n')
