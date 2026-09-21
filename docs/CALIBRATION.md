# Inverting a calibration curve

A caller knows an output response and needs the corresponding model input.
This example uses a **synthetic**, dimensionless normalized response:
`y(x) = 1 + 0.5*x + 0.02*x²`, on `0 <= x <= 10`. Its derivative is positive
throughout that domain, so every response from 1 to 8 has one inverse there.

Run `moon run --target js --frozen cmd/calibration` or use the portable runner.
The sample requests response `2.375`; the expected input is `2.5`. The JSON
output includes the recovered input, response residual, final bracket and reason.
Callers should check `converged`, then interpret position tolerance in input units.

Import `local/bracket_root/examples/scenarios` as `@scenarios` and call
`@scenarios.calibration(response, @root.Options::default(), use_secant=true)`.
The runnable configuration is in `cmd/calibration/moon.pkg`. Targets outside the
domain return `NoSignChange`; nonfinite targets cause a nonfinite callback error.
No extrapolation, curve fitting, measurement uncertainty or hardware validation
is performed. Replace the illustrative model and bracket with a validated model
before applying the root library to real instrument data.
