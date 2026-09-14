import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const path = 'docs/dev-log/core070/true-parity-gate-tier-2026-09-05.md';
const oracle = 'b4d5fee64def88bc768dda1f1f77c29b295edd86';
export function rows(text) {
  const result = [...text.matchAll(/^\| ([ABCD]\d+) \| `([^`]+)` \|/gm)]
    .map(([, id, capability]) => ({id, capability}));
  assert.equal(new Set(result.map(x => x.id)).size, result.length, 'duplicate row ID');
  assert.equal(new Set(result.map(x => x.capability)).size, result.length, 'duplicate capability');
  return result;
}
function reconcile(text, signed) {
  assert.ok(text.includes(oracle), 'frozen reference missing or changed');
  assert.deepEqual(rows(text), rows(signed), 'named signed scope changed');
}
const signed = execFileSync('git', ['show', `ede4e2d7b53b28229d95276f9e6835787247da70:${path}`], {encoding:'utf8'});
const proposal = execFileSync('git', ['show', `1b38906c:${path}`], {encoding:'utf8'});
const current = readFileSync(path, 'utf8');
reconcile(current, signed);
assert.deepEqual(rows(proposal), rows(signed), 'proposal/signing row change requires review');
// A scope checker must reject omission, extra rows, duplication and a changed oracle.
assert.throws(() => reconcile(current.replace(/^\| B4 .*\n/m, ''), signed));
assert.throws(() => reconcile(current + '\n| A16 | `invented/CAPABILITY` | extra |', signed));
assert.throws(() => reconcile(current + '\n| B4 | `duplicate/CAPABILITY` | extra |', signed));
assert.throws(() => reconcile(current.replaceAll(oracle, 'wrong-reference'), signed));
const counts = Object.fromEntries(['A','B','C','D'].map(k => [k,rows(current).filter(r=>r.id.startsWith(k)).length]));
console.log(JSON.stringify({oracle,counts,enumerated:rows(current).length,
  declared:42,disposition:'enumerated rows preserved; unsupported ten-row expansion prohibited',
  rows:rows(current)}, null, 2));
console.log('SCOPE_HISTORY_AND_NEGATIVE_CONTROLS_PASS');
