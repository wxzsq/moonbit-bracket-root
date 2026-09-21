/// Input errors are distinct from a valid run that exhausts its iteration budget.
pub(all) enum RootError {
  InvalidBounds
  InvalidTolerance
  InvalidIterationLimit
  NonFiniteValue(Double)
  NoSignChange
} derive(Debug, Eq)

pub extend RootError with Eq::{equal, not_equal}
pub extend RootError with @debug.Debug::{to_repr}

pub fn RootError::message(self : RootError) -> String {
  match self {
    InvalidBounds => "bounds must be finite and strictly increasing"
    InvalidTolerance => "require finite atol >= 0, 0 <= rtol < 1, and a positive tolerance"
    InvalidIterationLimit => "max_iterations must be between 0 and 1000000"
    NonFiniteValue(x) => "callback returned a nonfinite value at x=\{x}"
    NoSignChange => "nonzero endpoint values must have opposite signs"
  }
}

/// Only ExactZero and IntervalTolerance report convergence.
pub(all) enum StopReason {
  ExactZero
  IntervalTolerance
  FloatingPointLimit
  IterationLimit
} derive(Debug, Eq)

pub extend StopReason with Eq::{equal, not_equal}
pub extend StopReason with @debug.Debug::{to_repr}

pub fn StopReason::name(self : StopReason) -> String {
  match self {
    ExactZero => "exact_zero"
    IntervalTolerance => "interval_tolerance"
    FloatingPointLimit => "floating_point_limit"
    IterationLimit => "iteration_limit"
  }
}

pub(all) struct Options {
  abs_tolerance : Double
  rel_tolerance : Double
  max_iterations : Int
} derive(Debug)

pub extend Options with @debug.Debug::{to_repr}

pub fn Options::default() -> Options {
  { abs_tolerance: 1.0e-12, rel_tolerance: 1.0e-12, max_iterations: 128 }
}

/// An immutable snapshot after initialization or an accepted iteration.
pub(all) struct Bracket {
  lower : Double
  upper : Double
  f_lower : Double
  f_upper : Double
} derive(Debug)

pub extend Bracket with @debug.Debug::{to_repr}

/// root is always an evaluated endpoint of the final bracket, never an
/// unevaluated midpoint. trace includes the initial bracket.
pub(all) struct Solution {
  root : Double
  value : Double
  bracket : Bracket
  iterations : Int
  evaluations : Int
  reason : StopReason
  trace : Array[Bracket]
} derive(Debug)

pub extend Solution with @debug.Debug::{to_repr}

pub fn Solution::converged(self : Solution) -> Bool {
  self.reason == ExactZero || self.reason == IntervalTolerance
}

fn finite(x : Double) -> Bool {
  x == x && x <= 1.7976931348623157e308 && x >= -1.7976931348623157e308
}

fn magnitude(x : Double) -> Double {
  if x < 0.0 { -x } else { x }
}

fn same_sign(a : Double, b : Double) -> Bool {
  (a < 0.0 && b < 0.0) || (a > 0.0 && b > 0.0)
}

/// Avoid both a+b overflow and b-a overflow.
fn midpoint(a : Double, b : Double) -> Double {
  if a < 0.0 && b > 0.0 { a / 2.0 + b / 2.0 } else { a + (b - a) / 2.0 }
}

fn finish(
  bracket : Bracket,
  iterations : Int,
  reason : StopReason,
  trace : Array[Bracket],
) -> Solution {
  let choose_lower = magnitude(bracket.f_lower) <= magnitude(bracket.f_upper)
  {
    root: if choose_lower { bracket.lower } else { bracket.upper },
    value: if choose_lower { bracket.f_lower } else { bracket.f_upper },
    bracket,
    iterations,
    evaluations: iterations + 2,
    reason,
    trace,
  }
}

fn narrow_enough(bracket : Bracket, options : Options) -> Bool {
  let root = if magnitude(bracket.f_lower) <= magnitude(bracket.f_upper) {
    bracket.lower
  } else {
    bracket.upper
  }
  let width = bracket.upper - bracket.lower
  let tolerance = options.abs_tolerance + options.rel_tolerance * magnitude(root)
  // A finite width is required: infinity <= infinity must not certify a root.
  finite(width) && width <= tolerance
}

/// Normalize the secant weights before interpolation so fa-fb cannot overflow.
fn secant_candidate(bracket : Bracket) -> Double {
  let a = magnitude(bracket.f_lower)
  let b = magnitude(bracket.f_upper)
  let weight = if a <= b {
    let ratio = a / b
    ratio / (1.0 + ratio)
  } else {
    let ratio = b / a
    1.0 / (1.0 + ratio)
  }
  let width = bracket.upper - bracket.lower
  if finite(width) {
    bracket.lower + width * weight
  } else {
    (1.0 - weight) * bracket.lower + weight * bracket.upper
  }
}

fn solve(
  f : (Double) -> Double,
  lower : Double,
  upper : Double,
  options : Options,
  use_secant : Bool,
) -> Result[Solution, RootError] {
  if !finite(lower) || !finite(upper) || lower >= upper {
    return Err(InvalidBounds)
  }
  if !finite(options.abs_tolerance) || !finite(options.rel_tolerance) ||
     options.abs_tolerance < 0.0 || options.rel_tolerance < 0.0 ||
     options.rel_tolerance >= 1.0 ||
     (options.abs_tolerance == 0.0 && options.rel_tolerance == 0.0) {
    return Err(InvalidTolerance)
  }
  if options.max_iterations < 0 || options.max_iterations > 1000000 {
    return Err(InvalidIterationLimit)
  }
  let fl = f(lower)
  if !finite(fl) { return Err(NonFiniteValue(lower)) }
  let fu = f(upper)
  if !finite(fu) { return Err(NonFiniteValue(upper)) }
  let mut bracket = { lower, upper, f_lower: fl, f_upper: fu }
  let trace = [bracket]
  if fl == 0.0 || fu == 0.0 {
    let x = if fl == 0.0 { lower } else { upper }
    bracket = { lower: x, upper: x, f_lower: 0.0, f_upper: 0.0 }
    trace.push(bracket)
    return Ok(finish(bracket, 0, ExactZero, trace))
  }
  if same_sign(fl, fu) { return Err(NoSignChange) }
  let mut iterations = 0
  while true {
    if narrow_enough(bracket, options) {
      return Ok(finish(bracket, iterations, IntervalTolerance, trace))
    }
    if iterations >= options.max_iterations {
      return Ok(finish(bracket, iterations, IterationLimit, trace))
    }
    let mid = midpoint(bracket.lower, bracket.upper)
    if mid <= bracket.lower || mid >= bracket.upper {
      return Ok(finish(bracket, iterations, FloatingPointLimit, trace))
    }
    let mut candidate = mid
    if use_secant {
      let proposal = secant_candidate(bracket)
      let quarter = midpoint(bracket.lower, mid)
      let three_quarters = midpoint(mid, bracket.upper)
      // Accept only the central half: every iteration removes >= one quarter.
      if finite(proposal) && proposal > quarter && proposal < three_quarters {
        candidate = proposal
      }
    }
    let value = f(candidate)
    if !finite(value) { return Err(NonFiniteValue(candidate)) }
    iterations = iterations + 1
    if value == 0.0 {
      bracket = { lower: candidate, upper: candidate, f_lower: 0.0, f_upper: 0.0 }
      trace.push(bracket)
      return Ok(finish(bracket, iterations, ExactZero, trace))
    }
    bracket = if same_sign(bracket.f_lower, value) {
      { lower: candidate, upper: bracket.upper, f_lower: value, f_upper: bracket.f_upper }
    } else {
      { lower: bracket.lower, upper: candidate, f_lower: bracket.f_lower, f_upper: value }
    }
    trace.push(bracket)
  } nobreak {
    Ok(finish(bracket, iterations, IterationLimit, trace))
  }
}

/// Bisection for a continuous function with an opposite-sign bracket.
/// A zero endpoint is accepted. Function evaluations must be deterministic and
/// finite; continuity is a caller precondition, not something the solver proves.
pub fn bisect(
  f : (Double) -> Double,
  lower : Double,
  upper : Double,
  options : Options,
) -> Result[Solution, RootError] {
  solve(f, lower, upper, options, false)
}

/// Secant interpolation guarded by central-half acceptance and bisection.
/// This is not Brent's method and makes no superlinear-convergence guarantee.
pub fn safeguarded_secant(
  f : (Double) -> Double,
  lower : Double,
  upper : Double,
  options : Options,
) -> Result[Solution, RootError] {
  solve(f, lower, upper, options, true)
}
