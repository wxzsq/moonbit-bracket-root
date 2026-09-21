/// Synthetic normalized calibration curve, valid on x in [0, 10].
/// These coefficients are illustrative, not experimental measurements.
pub fn calibration_curve(x : Double) -> Double {
  1.0 + 0.5 * x + 0.02 * x * x
}

/// Invert a strictly increasing synthetic response. Targets outside [1, 8]
/// produce NoSignChange. Nonfinite targets produce a nonfinite callback error.
pub fn calibration(
  target : Double,
  options : @root.Options,
  use_secant? : Bool = false,
) -> Result[@root.Solution, @root.RootError] {
  let f = fn(x) { calibration_curve(x) - target }
  if use_secant {
    @root.safeguarded_secant(f, 0.0, 10.0, options)
  } else {
    @root.bisect(f, 0.0, 10.0, options)
  }
}
