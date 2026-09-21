// Read-only network request; writes a new download file without overwriting.
import { writeFile } from 'node:fs/promises';
import https from 'node:https';
const [url, output] = process.argv.slice(2);
if (!url || !output) throw new Error('Usage: node fetch-toolchain.mjs URL OUTPUT');
const parsed = new URL(url);
if (parsed.protocol !== 'https:' || !['cli.moonbitlang.com', 'cli.moonbitlang.cn', 'github.com'].includes(parsed.hostname)) {
  throw new Error('Only the documented official HTTPS hosts are accepted.');
}
async function download(target, redirects = 0) {
  if (redirects > 5) throw new Error('Too many HTTPS redirects');
  return new Promise((resolve, reject) => {
    const request = https.get(target, { timeout: 30000 }, response => {
      if ([301, 302, 303, 307, 308].includes(response.statusCode)) {
        const next = new URL(response.headers.location, target);
        response.resume();
        if (next.protocol !== 'https:') return reject(new Error('Refuse non-HTTPS redirect'));
        download(next, redirects + 1).then(resolve, reject);
      } else if (response.statusCode !== 200) {
        response.resume();
        reject(new Error(`HTTP ${response.statusCode}`));
      } else {
        const chunks = [];
        response.on('data', chunk => chunks.push(chunk));
        response.on('end', () => resolve(Buffer.concat(chunks)));
        response.on('error', reject);
      }
    });
    request.on('timeout', () => request.destroy(new Error('HTTPS timeout')));
    request.on('error', reject);
  });
}
await writeFile(output, await download(url), { flag: 'wx' });
console.log(`Saved ${url} to ${output}`);
