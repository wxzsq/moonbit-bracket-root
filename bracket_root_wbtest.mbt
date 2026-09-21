fn solved(result : Result[Solution, RootError]) -> Solution {
  match result {
    Ok(solution) => solution
    Err(error) => abort("unexpected error: \{error.message()}")
  }
}

fn expect_error(result : Result[Solution, RootError], expected : RootError) -> Unit raise {
  match result {
    Err(error) => assert_eq(error, expected)
    Ok(_) => fail("expected an input error")
  }
}

fn check_trace(solution : Solution, expected_root : Double) -> Unit raise {
  let mut last_lower = solution.trace[0].lower
  let mut last_upper = solution.trace[0].upper
  for bracket in solution.trace {
    assert_true(finite(bracket.lower) && finite(bracket.upper))
    assert_true(bracket.lower <= bracket.upper)
    assert_true(bracket.lower >= last_lower && bracket.upper <= last_upper)
    assert_true(bracket.lower <= expected_root && expected_root <= bracket.upper)
    assert_true(!same_sign(bracket.f_lower, bracket.f_upper))
    last_lower = bracket.lower
    last_upper = bracket.upper
  }
  assert_true(solution.root >= solution.bracket.lower && solution.root <= solution.bracket.upper)
  assert_eq(solution.evaluations, solution.iterations + 2)
}

test "sqrt2 analytic reference and nested sign brackets" {
  for use_secant in [false, true] {
    let solution = solved(solve(x => x * x - 2.0, 1.0, 2.0, Options::default(), use_secant))
    assert_true(solution.converged())
    assert_true(magnitude(solution.root - 1.4142135623730951) < 3.0e-12)
    check_trace(solution, 1.4142135623730951)
  }
}

test "endpoint root is identified without iterations" {
  for use_secant in [false, true] {
    for root in [0.0, 2.0] {
      let s = solved(solve(x => x - root, 0.0, 2.0, Options::default(), use_secant))
      assert_eq(s.reason, ExactZero)
      assert_eq(s.root, root)
      assert_eq(s.iterations, 0)
      check_trace(s, root)
    }
  }
}

test "same-sign endpoint underflow does not masquerade as bracket" {
  expect_error(bisect(x => (x + 2.0) * 1.0e-300, 0.0, 1.0, Options::default()), NoSignChange)
}

test "opposite-sign subnormal-scale values remain usable" {
  let s = solved(safeguarded_secant(x => (x - 0.375) * 1.0e-300, 0.0, 1.0, Options::default()))
  assert_true(s.converged())
  assert_true(magnitude(s.root - 0.375) < 1.0e-12)
  check_trace(s, 0.375)
}

test "large opposite bounds and overflowing function differences" {
  let max = 1.7976931348623157e308
  for use_secant in [false, true] {
    let s = solved(solve(x => x, -max, max, Options::default(), use_secant))
    assert_eq(s.reason, ExactZero)
    assert_eq(s.root, 0.0)
    check_trace(s, 0.0)
  }
}

test "same-sign extreme bounds do not overflow midpoint" {
  for use_secant in [false, true] {
    let s = solved(solve(x => x / 1.0e308 - 1.25, 1.0e308, 1.7e308, Options::default(), use_secant))
    assert_true(s.converged())
    assert_true(magnitude(s.root / 1.0e308 - 1.25) < 3.0e-12)
    check_trace(s, 1.25e308)
  }
}

test "invalid bounds and configuration are typed errors" {
  let defaults = Options::default()
  expect_error(bisect(x => x, 1.0, 1.0, defaults), InvalidBounds)
  expect_error(bisect(x => x, 2.0, 1.0, defaults), InvalidBounds)
  expect_error(bisect(x => x, 0.0 / 0.0, 1.0, defaults), InvalidBounds)
  expect_error(bisect(x => x, 0.0, 1.0 / 0.0, defaults), InvalidBounds)
  for bad in [
    { abs_tolerance: -1.0, rel_tolerance: 0.0, max_iterations: 10 },
    { abs_tolerance: 0.0, rel_tolerance: 0.0, max_iterations: 10 },
    { abs_tolerance: 1.0e-12, rel_tolerance: 1.0, max_iterations: 10 },
    { abs_tolerance: 0.0 / 0.0, rel_tolerance: 0.0, max_iterations: 10 },
  ] {
    expect_error(bisect(x => x, -1.0, 1.0, bad), InvalidTolerance)
  }
  expect_error(bisect(x => x, -1.0, 1.0, { ..defaults, max_iterations: -1 }), InvalidIterationLimit)
}

test "nonfinite endpoint and interior callback values are rejected" {
  expect_error(bisect(_ => 1.0 / 0.0, 0.0, 1.0, Options::default()), NonFiniteValue(0.0))
  expect_error(bisect(x => if x == 0.0 { -1.0 } else if x == 1.0 { 1.0 } else { 0.0 / 0.0 }, 0.0, 1.0, Options::default()), NonFiniteValue(0.5))
}

test "iteration budget is a nonconverged diagnostic" {
  let s = solved(bisect(x => x * x - 2.0, 1.0, 2.0, { ..Options::default(), max_iterations: 1 }))
  assert_eq(s.reason, IterationLimit)
  assert_true(!s.converged())
  assert_eq(s.iterations, 1)
  assert_eq(s.evaluations, 3)
}

test "no half-width error certificate for an endpoint estimate" {
  let f = fn(x : Double) -> Double {
    let scale = 1.0 + 63.0 * x
    (x - 0.875) * scale * scale
  }
  let s = solved(bisect(f, 0.0, 1.0, { abs_tolerance: 0.5, rel_tolerance: 0.0, max_iterations: 0 }))
  assert_eq(s.reason, IterationLimit)
  assert_eq(s.root, 0.0)
  assert_true(!s.converged())
}

test "adjacent doubles signal floating point limit" {
  let options = { abs_tolerance: 5.0e-324, rel_tolerance: 0.0, max_iterations: 128 }
  for use_secant in [false, true] {
    let s = solved(solve(x => (x - 1.0) - 1.1102230246251565e-16, 1.0, 1.0000000000000002, options, use_secant))
    assert_eq(s.reason, FloatingPointLimit)
    assert_true(!s.converged())
    assert_eq(s.iterations, 0)
  }
}

test "secant safeguard contracts poorly scaled brackets" {
  let s = solved(safeguarded_secant(x => x * x * x * x * x * x * x * x * x * x - 1.0, 0.0, 4.0, Options::default()))
  assert_true(s.converged())
  check_trace(s, 1.0)
  for i = 1; i < s.trace.length(); i = i + 1 {
    let before = s.trace[i - 1].upper - s.trace[i - 1].lower
    let after = s.trace[i].upper - s.trace[i].lower
    assert_true(after <= 0.750000000000001 * before)
  }
}

test "500 deterministic scaled linear problems per method" {
  for i = 1; i <= 500; i = i + 1 {
    let root = (i - 251).to_double() / 7.0
    let scale = if i % 2 == 0 { 1.0e-200 } else { -1.0e200 }
    for use_secant in [false, true] {
      let s = solved(solve(x => (x - root) * scale, root - 3.0, root + 7.0, Options::default(), use_secant))
      assert_true(s.converged())
      assert_true(magnitude(s.root - root) <= 1.0e-12 + 1.0e-12 * magnitude(s.root))
      check_trace(s, root)
    }
  }
}

test "callback count matches reported evaluations" {
  let mut calls = 0
  let f = fn(x : Double) -> Double { calls = calls + 1; x * x - 2.0 }
  let s = solved(safeguarded_secant(f, 1.0, 2.0, Options::default()))
  assert_eq(calls, s.evaluations)
}

test "discontinuity is not certified by the numerical solver" {
  let s = solved(bisect(x => if x < 0.25 { -1.0 } else { 1.0 }, 0.0, 1.0, Options::default()))
  assert_eq(s.reason, IntervalTolerance)
  assert_eq(magnitude(s.value), 1.0)
  // This documents the continuity precondition, not a claim that a root exists.
}

test "negative zero endpoint is accepted" {
  let s = solved(bisect(x => -x, 0.0, 1.0, Options::default()))
  assert_eq(s.reason, ExactZero)
  assert_eq(s.root, 0.0)
}

test "overflowing secant denominator retains a finite trial" {
  let max = 1.7976931348623157e308
  let s = solved(safeguarded_secant(x => max * x, -1.0, 1.0, Options::default()))
  assert_eq(s.reason, ExactZero)
  assert_eq(s.root, 0.0)
}

test "zero budget never evaluates an interior point" {
  let calls : Array[Double] = []
  let f = fn(x : Double) -> Double { calls.push(x); x - 0.3 }
  let s = solved(safeguarded_secant(f, -1.0, 1.0, { ..Options::default(), max_iterations: 0 }))
  assert_eq(s.reason, IterationLimit)
  assert_eq(s.iterations, 0)
  assert_eq(calls.length(), 2)
  assert_eq(calls[0], -1.0)
  assert_eq(calls[1], 1.0)
}

test "tiny residual never replaces positional tolerance" {
  for scale in [1.0, 1.0e-300, 1.0e300] {
    for use_secant in [false, true] {
      let s = solved(solve(x => scale * (x - 0.5), -1.0, 1.0, Options::default(), use_secant))
      assert_true(s.converged())
      assert_true(magnitude(s.root - 0.5) <= 1.5e-12)
      check_trace(s, 0.5)
    }
  }
}
