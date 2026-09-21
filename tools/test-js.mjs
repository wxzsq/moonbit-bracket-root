import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { buildBridge } from './build-js.mjs';

const { artifact, run } = buildBridge();
const { solve_demo } = await import(pathToFileURL(artifact));
let checks = 0;
for (const method of ['bisect', 'secant']) {
  for (const [scenario, target, expected] of [['sqrt', 2, Math.sqrt(2)], ['calibration', 2.375, 2.5], ['cooling', 50, Math.log(2) / 0.1]]) {
    const result = JSON.parse(solve_demo(scenario, target, method, 1e-12, 1e-12, 128));
    assert.equal(result.ok, true);
    assert.equal(result.solution.schema_version, 1);
    assert.equal(result.solution.converged, true);
    assert.ok(Math.abs(result.solution.root - expected) < 1e-10);
    const rows = result.csv.trim().split('\n');
    assert.equal(rows.length, result.solution.trace.length + 1);
    const last = rows.at(-1).split(',').map(Number);
    assert.equal(last[1], result.solution.bracket.lower);
    assert.equal(last[2], result.solution.bracket.upper);
    checks++;
  }
}
for (const args of [['bad', 2, 'bisect', 1e-12, 1e-12, 128], ['sqrt', -1, 'bisect', 1e-12, 1e-12, 128], ['cooling', 20, 'bisect', 1e-12, 1e-12, 128], ['sqrt', 2, 'bad', 1e-12, 1e-12, 128], ['sqrt', NaN, 'bisect', 1e-12, 1e-12, 128], ['sqrt', 2, 'bisect', -1, 1e-12, 128]]) {
  assert.equal(JSON.parse(solve_demo(...args)).ok, false);
  checks++;
}
const exhausted = JSON.parse(solve_demo('sqrt', 2, 'bisect', 1e-12, 1e-12, 0));
assert.equal(exhausted.ok, true);
assert.equal(exhausted.solution.converged, false);
assert.equal(exhausted.solution.reason, 'iteration_limit');
checks++;
writeFileSync(join(run, 'interop-test.json'), JSON.stringify({ checks, status: 'passed' }), { flag: 'wx' });
console.log(`${checks} JavaScript integration cases passed; retained artifacts: ${run}`);
