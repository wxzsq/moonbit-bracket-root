import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync, readdirSync, copyFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';

export function buildBridge() {
  const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
  const run = join(root, 'build-runs', `bridge-${Date.now()}-${randomUUID().slice(0, 8)}`);
  mkdirSync(join(run, 'tmp'), { recursive: true });
  const home = process.env.MOON_HOME;
  const bin = process.env.MOON_BIN || (home ? join(home, 'bin', process.platform === 'win32' ? 'moon.exe' : 'moon') : 'moon');
  const env = { ...process.env, TEMP: join(run, 'tmp'), TMP: join(run, 'tmp'), TMPDIR: join(run, 'tmp') };
  if (home) env.PATH = `${join(home, 'bin')}${process.platform === 'win32' ? ';' : ':'}${env.PATH || ''}`;
  const built = spawnSync(bin, ['--target-dir', join(run, 'target'), 'build', '--target', 'js', '--frozen', '--deny-warn', 'js/bridge'], { cwd: root, env, encoding: 'utf8' });
  writeFileSync(join(run, 'build.log'), `${built.stdout || ''}${built.stderr || ''}${built.error || ''}`, { flag: 'wx' });
  if (built.error || built.status !== 0) throw new Error(`Bridge build failed: ${join(run, 'build.log')}`);
  function find(path) {
    return readdirSync(path, { withFileTypes: true }).flatMap(e => e.isDirectory() ? find(join(path, e.name)) : [join(path, e.name)]);
  }
  const candidates = find(join(run, 'target')).filter(p => /[\\/]bridge\.js$/.test(p));
  if (candidates.length !== 1) throw new Error(`Expected one bridge.js artifact, got ${candidates.length}`);
  const artifact = join(run, 'solver.mjs');
  copyFileSync(candidates[0], artifact);
  return { run, artifact };
}
