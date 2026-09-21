fn is_finite(x : Double) -> Bool {
  x == x && x.abs() <= 1.7976931348623157e308
}

/// Newton cooling illustration: temperatures in Celsius, time in minutes,
/// rate in inverse minutes. Inputs are synthetic, not measured thermal data.
pub fn cooling_time(
  target : Double,
  options : @root.Options,
  initial? : Double = 80.0,
  ambient? : Double = 20.0,
  rate? : Double = 0.1,
  horizon? : Double = 60.0,
  use_secant? : Bool = false,
) -> Result[@root.Solution, String] {
  if !is_finite(initial) || !is_finite(ambient) || !is_finite(initial - ambient) ||
     !is_finite(rate) || !is_finite(horizon) ||
     initial <= ambient || rate <= 0.0 || horizon <= 0.0 {
    return Err("require finite initial > ambient, rate > 0 and horizon > 0")
  }
  if !is_finite(target) { return Err("target must be finite") }
  let temperature = fn(t) { ambient + (initial - ambient) * @math.exp(-rate * t) }
  if target > initial || target <= ambient || target < temperature(horizon) {
    return Err("target is not reachable in the selected time interval")
  }
  let f = fn(t) { temperature(t) - target }
  let result = if use_secant {
    @root.safeguarded_secant(f, 0.0, horizon, options)
  } else {
    @root.bisect(f, 0.0, horizon, options)
  }
  match result {
    Ok(s) => Ok(s)
    Err(e) => Err(e.message())
  }
}
