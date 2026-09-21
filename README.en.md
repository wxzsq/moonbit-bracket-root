# bracket-root

Small MoonBit solvers for a scalar continuous function with a known sign-changing bracket. The library provides bisection and a safeguarded secant method, typed input errors, explicit termination reasons, evaluation counts, and an auditable bracket trace.

## Quick start

With a MoonBit toolchain available:

```text
moon test --target js --frozen --deny-warn
moon run --target js --frozen cmd/main
```

The project-local Windows wrapper `pwsh -NoProfile -File tools/test.ps1 -Target js -Demo` retains every build in a new directory. The module is currently named `local/bracket_root`; it has not been published to the registry. See `cmd/main/moon.pkg` for a working package import.

```moonbit
let result = @root.safeguarded_secant(
  x => x * x - 2.0,
  1.0,
  2.0,
  @root.Options::default(),
)
match result {
  Ok(solution) => println(solution.root)
  Err(error) => println(error.message())
}
```

## Contract

The callback must be deterministic and continuous over the initial interval and return finite values at all evaluated points. The solver cannot establish continuity. A discontinuous sign jump can satisfy the width criterion without having a root. A small residual is never used as a stopping criterion.

Bounds must be finite and strictly increasing. Defaults are absolute tolerance `1e-12`, relative tolerance `1e-12`, and 128 iterations. Tolerances must be finite, nonnegative, and not both zero; relative tolerance must be less than one. The integer iteration limit may be zero and is capped at one million to bound accidental resource use. All parameters are validated before invoking the callback.

Both endpoints are evaluated before accepting an endpoint zero. Each internal iteration evaluates one candidate. `evaluations == iterations + 2` for every returned `Solution`. A callback error result does not return a partial `Solution`.

The returned point is the evaluated endpoint with the smaller absolute callback value. `IntervalTolerance` means the **full** bracket width satisfies `width <= atol + rtol * abs(root)`; using half the width would not justify this endpoint estimate. Under the mathematical continuity and faithful-sign assumptions, that width bounds the distance to at least one root in the bracket. ExactZero means that the floating-point callback returned zero, including signed zero; it is not a proof of an exact mathematical root or freedom from underflow.

`FloatingPointLimit` and `IterationLimit` return the last bracket but report `converged() == false`. Invalid bounds, tolerances, iteration limit, missing sign change, and nonfinite callback values are typed `RootError` values.

## Safeguard and scope

Secant interpolation normalizes absolute endpoint values to avoid overflowing `f(b)-f(a)`. Only proposals in the central half of the bracket are accepted; other proposals use an overflow-aware midpoint. In real arithmetic, each successful update keeps at most three quarters of the previous width. This is not Brent's method and is not promised to outperform bisection.

All trace snapshots are retained, using O(iterations) storage. No external numerical or paid API is required. The project deliberately excludes multivariate optimization, symbolic analysis, and automatic bracket discovery.

## Validation and provenance

On 2026-09-21, MoonBit `v0.10.14+7d59c7ec9`, build tool `0.1.20260920`, Windows and the JavaScript backend passed 19 tests with warnings denied. One property-oriented test covers 1,000 deterministic scaled linear problems. Regression cases include extreme bounds, sign underflow, secant denominator overflow, adjacent doubles, zero budget, endpoint error-bound misuse, nonfinite callbacks, negative zero, and evaluation accounting. Other backends remain unverified.

See [algorithm notes](docs/ALGORITHM.md), [API details](docs/API.md), and [toolchain provenance](tools/TOOLCHAIN.md). The source and tests were developed with AI assistance and independently reviewed against floating-point counterexamples. Local tests do not establish competition acceptance or payment.

Project source: [MIT license](LICENSE). Compiler and standard-library licenses remain their own upstream licenses.
