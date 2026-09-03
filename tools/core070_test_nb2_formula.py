"""Deliberately corrupt copied kernel evidence; every corruption must fail."""
import json, shutil, tempfile
from pathlib import Path
import core070_verify_nb2_formula as gate

def edit_receipt(folder, change):
    path = folder / 'attempt1/process/process-receipt.json'
    receipt = json.loads(path.read_text())
    change(receipt)
    path.write_text(json.dumps(receipt))

changes = [
    ('missing receipt', lambda p: (p / 'attempt1/process/process-receipt.json').unlink()),
    ('missing plan', lambda p: (p / 'plan.json').unlink()),
    ('stale source', lambda p: edit_receipt(p, lambda r: r.update(source_unchanged=False))),
    ('nonzero test exit', lambda p: edit_receipt(p, lambda r: r['results'][1].update(exit_code=7))),
    ('omitted test', lambda p: edit_receipt(p, lambda r: r['results'].pop(1))),
    ('changed environment', lambda p: edit_receipt(p, lambda r: r.update(environment_overrides={}))),
    ('missing archive', lambda p: (p / 'source.tar').unlink()),
    ('altered output', lambda p: (p / 'attempt1/process/01.log').write_text('PASS\n')),
]
for name, change in changes:
    with tempfile.TemporaryDirectory(prefix='nb2-kernel-negative-') as tmp:
        folder = Path(tmp) / 'copy'
        shutil.copytree(gate.STATE / 'nb2-formula-green-01', folder)
        change(folder)
        try:
            gate.verify_run(folder, True)
        except (AssertionError, FileNotFoundError):
            pass
        else:
            raise AssertionError('Accepted corruption: ' + name)
print('NB2_FORMULA_ARTIFACT_NEGATIVES_PASS', len(changes))
