// Build a real second MoonBit module in a fresh local workspace. No registry
// publication is assumed, and no generated directory is reused or deleted.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const run = join(root, 'build-runs', `consumer-${Date.now()}-${randomUUID().slice(0, 8)}`);
const consumer = join(run, 'consumer');
mkdirSync(consumer, { recursive: true });
mkdirSync(join(run, 'tmp'));
for (const file of ['moon.mod','moon.pkg','main.mbt','consumer_test.mbt']) {
  copyFileSync(join(root, 'integration', 'consumer', file), join(consumer, file));
}
// MoonBit's moon.work syntax accepts quoted relative paths.
const member = relative(run, root).replaceAll('\\', '/');
writeFileSync(join(run, 'moon.work'), `members = [${JSON.stringify(member)}, "consumer"]\n`, { flag: 'wx' });
const home = process.env.MOON_HOME;
const executable = process.env.MOON_BIN || (home ? join(home, 'bin', process.platform === 'win32' ? 'moon.exe' : 'moon') : 'moon');
const env = {...process.env, TEMP:join(run,'tmp'), TMP:join(run,'tmp'), TMPDIR:join(run,'tmp')};
if (home) env.PATH = `${join(home,'bin')}${process.platform === 'win32' ? ';' : ':'}${env.PATH || ''}`;
function execute(name, command, args = []) {
  const result = spawnSync(executable, ['--target-dir',join(run,name),command,'--target','js','--frozen','--deny-warn',...args], {cwd:consumer,env,encoding:'utf8',maxBuffer:16*1024*1024});
  writeFileSync(join(run,`${name}.log`),`${result.stdout || ''}${result.stderr || ''}${result.error || ''}`,{flag:'wx'});
  if (result.error || result.status !== 0) throw Error(`${name} failed; inspect ${join(run,`${name}.log`)}`);
  return result.stdout;
}
const testOutput = execute('consumer-tests','test',['.']);
const output = execute('consumer-run','run',['.']);
const solution = JSON.parse(output);
assert.equal(solution.converged,true);
assert.ok(Math.abs(solution.root - Math.cbrt(2)) < 1e-11);
assert.ok(Math.abs(solution.value) < 1e-10);
writeFileSync(join(run,'result.json'),JSON.stringify({status:'passed',root:solution.root,reference:Math.cbrt(2),tests:testOutput.trim(),userFeedback:false},null,2),{flag:'wx'});
console.log(`Independent consumer passed: cube root=${solution.root}; ${testOutput.trim()}; retained: ${run}`);
