// Portable, dependency-free verification. Every run retains its own outputs.
import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const run = join(root, 'build-runs', `${new Date().toISOString().replaceAll(':', '-')}-${randomUUID().slice(0, 8)}`);
mkdirSync(join(run, 'tmp'), { recursive: true });
const home = process.env.MOON_HOME;
const executable = process.env.MOON_BIN || (home
  ? join(home, 'bin', process.platform === 'win32' ? 'moon.exe' : 'moon')
  : 'moon');
if (home && !existsSync(executable)) throw new Error('MOON_HOME does not contain the MoonBit executable.');
const env = { ...process.env, TEMP: join(run, 'tmp'), TMP: join(run, 'tmp'), TMPDIR: join(run, 'tmp') };
if (home) env.PATH = `${join(home, 'bin')}${process.platform === 'win32' ? ';' : ':'}${env.PATH || ''}`;

function execute(name, args, program = executable) {
  const result = spawnSync(program, args, { cwd: root, env, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
  const log = `${result.stdout || ''}${result.stderr || ''}${result.error ? `\n${result.error.message}\n` : ''}`;
  writeFileSync(join(run, `${name}.log`), log, { flag: 'wx' });
  process.stdout.write(log);
  if (result.error || result.status !== 0) throw new Error(`${name} failed; see ${run}`);
  return log;
}

execute('moon-version', ['version', '--all']);
execute('tests', ['--target-dir', join(run, 'test'), 'test', '--target', 'js', '--frozen', '--deny-warn']);
execute('sqrt-demo', ['--target-dir', join(run, 'sqrt'), 'run', '--target', 'js', '--frozen', 'cmd/main']);
execute('calibration-demo', ['--target-dir', join(run, 'calibration'), 'run', '--target', 'js', '--frozen', 'cmd/calibration']);
execute('cooling-demo', ['--target-dir', join(run, 'cooling'), 'run', '--target', 'js', '--frozen', 'cmd/cooling']);
execute('javascript-integration', [join(root, 'tools', 'test-js.mjs')], process.execPath);
writeFileSync(join(run, 'result.json'), JSON.stringify({ status: 'passed', target: 'js', finishedAt: new Date().toISOString() }, null, 2), { flag: 'wx' });
console.log(`Verification passed. Logs retained: ${run}`);
