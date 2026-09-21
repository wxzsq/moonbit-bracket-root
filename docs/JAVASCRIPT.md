# JavaScript and command-line integration

Install MoonBit and Node.js 18 or newer. If MoonBit is not on PATH, set
`MOON_HOME` to its installed root. Run from this repository:

```sh
node tools/run-demo.mjs sqrt 2 secant
node tools/run-demo.mjs calibration 2.375 bisect
node tools/run-demo.mjs cooling 50 secant
node tools/run-demo.mjs sqrt 2 bisect 0
node tools/test-js.mjs
```

The CLI builds MoonBit to an ES module in a new retained `build-runs` directory.
It invokes the compiled solver, with no algorithm reimplementation in JavaScript.
Exit codes are 0 (converged), 2 (invalid input) and 3 (valid but not converged).
The last example intentionally returns 3. JSON contains `ok` and either
`solution` plus `csv`, or `error`. Large square-root targets can overflow callback
values; this is reported as an error, not silently approximated.

`buildBridge()` returns the compiled `artifact` path. Import it and call
`solve_demo(scenario, target, method, atol, rtol, max_iterations)` with primitive
arguments. The caller must supply a finite integer iteration budget in 0–1,000,000
to this low-level ABI. Use `bisect` or `secant` for method, and the three scenario
names above. JSON is the interface boundary; MoonBit structs are not exposed as
an undocumented JS object layout. No npm packages or network service are used.

This bridge demonstrates three models. The general `(Double)->Double` callback
API remains available directly in MoonBit for other functions.
