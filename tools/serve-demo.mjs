import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { buildBridge } from './build-js.mjs';

const { artifact } = buildBridge();
const routes = new Map([
  ['/', [fileURLToPath(new URL('../web/index.html',import.meta.url)), 'text/html; charset=utf-8']],
  ['/app.mjs', [fileURLToPath(new URL('../web/app.mjs',import.meta.url)), 'text/javascript; charset=utf-8']],
  ['/style.css', [fileURLToPath(new URL('../web/style.css',import.meta.url)), 'text/css; charset=utf-8']],
  ['/solver.mjs', [artifact, 'text/javascript; charset=utf-8']],
]);
const port=Number(process.env.PORT || 4317);
if (!Number.isInteger(port) || port < 1024 || port > 65535) throw Error('PORT must be an integer in 1024..65535');
createServer((req,res)=>{
  const route=routes.get((req.url || '').split('?')[0]);
  if (!['GET','HEAD'].includes(req.method)) { res.writeHead(405); res.end(); return; }
  if (!route) { res.writeHead(404); res.end('Not found'); return; }
  res.writeHead(200,{'Content-Type':route[1],'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});
  res.end(req.method==='HEAD' ? undefined : readFileSync(route[0]));
}).listen(port,'127.0.0.1',()=>console.log(`MoonBit demo: http://127.0.0.1:${port}\nCompiled module: ${artifact}\nPress Ctrl+C to stop.`));
