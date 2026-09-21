# Computing a threshold-crossing time

An illustrative cooling model is `T(t) = 20 + 60*exp(-0.1*t)`: temperature is
in degrees Celsius, time in minutes, and rate in inverse minutes. All parameters
are **synthetic**. The question is when temperature first reaches 50 °C within
60 minutes. Solving `T(t)-50=0` gives approximately **6.9314718056 minutes**.

Run `moon run --target js --frozen cmd/cooling`, or the portable verification
runner. It prints JSON with a time estimate, temperature residual and termination
diagnostics. The tests compare multiple targets against the independently
computed logarithmic inverse, `-ln((target-ambient)/(initial-ambient))/rate`.

`@scenarios.cooling_time(target, options)` allows named `initial`, `ambient`,
`rate`, `horizon`, and `use_secant` arguments. It rejects nonfinite or invalid
model parameters and targets outside the chosen time window. An ambient-temperature
target is asymptotic and is rejected, even when exponential underflow rounds a
late sample to ambient. Budget exhaustion remains `Ok(solution)` with
`converged=false`; callers must inspect it before accepting a crossing time.

This demonstrates reuse of the same numerical library; it is not an experimentally
validated cooling predictor. Real applications must supply an appropriate model
and uncertainty analysis. Position tolerance here is measured in minutes.
