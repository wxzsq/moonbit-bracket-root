# Capabilities, boundaries, and evidence

Checked on 2026-09-22. This is an engineering capability matrix, not a competition
approval or a claim of user adoption. Public APIs are development-version contracts;
any future incompatible change must be documented before downstream adoption.

| Capability | Supported scope | Boundary | Evidence |
|---|---|---|---|
| Scalar root solving | Bisection and central-half safeguarded secant on finite ordered brackets | Continuous, deterministic callbacks; no multidimensional or symbolic solver | `bracket_root_wbtest.mbt` |
| Termination diagnostics | Floating zero, positional tolerance, floating-point limit, iteration budget | Only the first two set `converged=true`; no automatic continuity proof | `bracket_root_wbtest.mbt`, `integration/consumer/consumer_test.mbt` |
| Storage policy | Complete trajectory by default; `record_trace=false` for constant solver storage | Callback-owned memory is outside the solver's storage guarantee | `trace_policy_wbtest.mbt` |
| Candidate discovery | Uniform finite-grid sign crossings and sampled zeros | May miss tangencies/multiple roots between samples; no completeness guarantee | `scan_wbtest.mbt` |
| Interchange | JSON schema version 1 and numeric CSV snapshots | Export solver-produced values; no partial result when callbacks return nonfinite values | `export_wbtest.mbt`, `tools/test-js.mjs` |
| Application examples | Teaching, synthetic calibration inversion, synthetic cooling threshold | Not experimental calibration/thermal validation | `examples/scenarios`, `cmd` |
| Reuse by another module | Local MoonBit workspace, custom callback, public error handling | No Mooncakes publication, no evidence of independent users yet | `tools/test-consumer.mjs`, [consumer guide](CONSUMING.md) |
| JavaScript bridge/CLI | Three named scenarios; numeric arguments and explicit failure exits | Not an arbitrary expression evaluator | `tools/test-js.mjs` |
| Interactive display | Parameter controls, trace chart/table, JSON/CSV exports | Local server; no published hosted service; browser download action not automated | 2026-09-21 manual browser checks, `web/` |
| Platforms | Windows with the recorded MoonBit toolchain, JavaScript backend | Other operating systems and compilation backends remain unverified | `tools/verify.mjs` retained version and result logs |
| Product usefulness | A testable workflow for a MoonBit developer with a scalar model | User need, onboarding time and benefit of diagnostics remain hypotheses | [trial protocol](USER-TRIAL.md) |

The solver's value is its explicit contract and diagnostics in MoonBit. We do not
claim a new root-finding algorithm or a performance advantage over established
libraries. For context, [SciPy bisect](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.bisect.html)
also requires a continuous function and a sign bracket. This is a conceptual
comparison; no SciPy speed or numerical equivalence benchmark has been run here.
