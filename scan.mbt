pub(all) enum ScanError {
  InvalidScanBounds
  InvalidSegments
  IndistinguishableSamples
  NonFiniteSample(Double)
} derive(Debug, Eq)
pub extend ScanError with Eq::{equal, not_equal}
pub extend ScanError with @debug.Debug::{to_repr}

pub(all) struct ScanResult {
  brackets : Array[Bracket]
  exact_zeros : Array[Double]
  evaluations : Int
} derive(Debug)
pub extend ScanResult with @debug.Debug::{to_repr}

/// Sample a bounded uniform grid. Finding no sign changes does not prove that
/// no roots exist. Continuity and finite, deterministic callbacks are required.
pub fn scan_brackets(
  f : (Double) -> Double,
  lower : Double,
  upper : Double,
  segments : Int,
) -> Result[ScanResult, ScanError] {
  if !finite(lower) || !finite(upper) || lower >= upper {
    return Err(InvalidScanBounds)
  }
  if segments < 1 || segments > 1000000 { return Err(InvalidSegments) }
  let brackets = []
  let exact_zeros = []
  let mut previous = lower
  let mut value = f(lower)
  if !finite(value) { return Err(NonFiniteSample(lower)) }
  if value == 0.0 { exact_zeros.push(lower) }
  for i = 1; i <= segments; i = i + 1 {
    let ratio = i.to_double() / segments.to_double()
    let x = if i == segments { upper } else if finite(upper - lower) {
      lower + ratio * (upper - lower)
    } else {
      (1.0 - ratio) * lower + ratio * upper
    }
    if !finite(x) || x <= previous || x > upper {
      return Err(IndistinguishableSamples)
    }
    let next_value = f(x)
    if !finite(next_value) { return Err(NonFiniteSample(x)) }
    if next_value == 0.0 { exact_zeros.push(x) }
    if value != 0.0 && next_value != 0.0 && !same_sign(value, next_value) {
      brackets.push({ lower: previous, upper: x, f_lower: value, f_upper: next_value })
    }
    previous = x
    value = next_value
  }
  Ok({ brackets, exact_zeros, evaluations: segments + 1 })
}
