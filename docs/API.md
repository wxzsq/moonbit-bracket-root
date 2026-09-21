# API reference

`bisect(f, lower, upper, options)` and `safeguarded_secant(f, lower, upper, options)` return `Result[Solution, RootError]`. The callback type is `(Double) -> Double`; no derivative is required. Pure, finite-valued deterministic callbacks are expected.

| Type | Public fields or cases |
|---|---|
| `Options` | `abs_tolerance: Double`, `rel_tolerance: Double`, `max_iterations: Int`; `Options::default()` |
| `Bracket` | `lower`, `upper`, `f_lower`, `f_upper`: Double |
| `Solution` | `root`, `value`: Double; `bracket: Bracket`; `iterations`, `evaluations`: Int; `reason: StopReason`; `trace: Array[Bracket]` |
| `StopReason` | `ExactZero`, `IntervalTolerance`, `FloatingPointLimit`, `IterationLimit`; `name()` returns a stable readable identifier |
| `RootError` | `InvalidBounds`, `InvalidTolerance`, `InvalidIterationLimit`, `NonFiniteValue(x)`, `NoSignChange`; `message()` explains the problem |

`Solution::converged()` returns true only for ExactZero and IntervalTolerance. A caller should inspect this method before using a result as a converged estimate. Function errors do not expose a partial trajectory; recoverable termination due to budget or floating-point limits does.

`trace[0]` stores the initial evaluated bracket. Each accepted candidate adds one snapshot; an endpoint zero adds a collapsed final snapshot without increasing the iteration count. Thus trace length is normally `iterations+1`, except for an endpoint zero where it is 2. The final bracket always contains the returned point.

The interval criterion bounds position relative to a root only under the documented continuity and sign-fidelity assumptions. `value` is the callback output at `root`, not an independent residual estimate. See the README for tolerance and resource limits.

Both solvers accept an optional named argument `record_trace=false`. This keeps
`trace` empty while preserving the final bracket, termination reason, callback
count and numerical result. It uses constant solver storage for batch work;
the default remains `true` for teaching and diagnostics. This option does not
change the iteration budget or suppress callback errors.

### Exporting results

`solution.to_json_string()` produces JSON with `schema_version: 1`, `root`,
`value`, `converged`, `reason`, `iterations`, `evaluations`, `bracket` and
`trace`. Brackets use the same four field names as the MoonBit type. Consumers
must inspect `converged`; valid JSON can describe an exhausted iteration budget.
`solution.trace_csv()` exports numeric snapshots with a header and LF newlines.
The snapshot index differs from iteration count for endpoint roots. With tracing
disabled, CSV contains only its header. Export is intended for solver-produced
solutions, whose numerical fields are finite. No spreadsheet or runtime dependency
is required beyond the MoonBit standard library.

### Discovering candidate brackets

`scan_brackets(f, lower, upper, segments)` returns `Result[ScanResult, ScanError]`.
It evaluates `segments + 1` uniformly spaced samples (1–1,000,000 segments),
reports adjacent **nonzero opposite-sign** pairs in `brackets`, and reports sampled
zeros separately in `exact_zeros`. Pass each bracket's bounds to a solver to refine
it; those solver endpoint evaluations are additional to the scan's count.
An empty scan is not proof of no roots: tangent roots and multiple crossings
between samples can be missed. There is no completeness or uniqueness guarantee.
Invalid bounds, segment counts, nonfinite callbacks and indistinguishable floating
samples return typed errors. A failed scan returns no partial results.
