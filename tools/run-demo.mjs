import { pathToFileURL } from 'node:url';
import { buildBridge } from './build-js.mjs';

const [scenario = 'sqrt', targetText, method = 'bisect', budgetText = '128'] = process.argv.slice(2);
const defaults = { sqrt: 2, calibration: 2.375, cooling: 50 };
const target = targetText === undefined ? defaults[scenario] : Number(targetText);
const budget = Number(budgetText);
if (!Object.hasOwn(defaults, scenario) || !['bisect', 'secant'].includes(method) ||
    !Number.isFinite(target) || !Number.isInteger(budget) || budget < 0 || budget > 1000000 || process.argv.length > 6) {
  console.error('Usage: node tools/run-demo.mjs [sqrt|calibration|cooling] [target] [bisect|secant] [iterations:0..1000000]');
  process.exitCode = 2;
} else {
  const { artifact } = buildBridge();
  const { solve_demo } = await import(pathToFileURL(artifact));
  const result = JSON.parse(solve_demo(scenario, target, method, 1e-12, 1e-12, budget));
  console.log(JSON.stringify(result, null, 2));
  process.exitCode = !result.ok ? 2 : result.solution.converged ? 0 : 3;
}
