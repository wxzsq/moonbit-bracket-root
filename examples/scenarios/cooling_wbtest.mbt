test "cooling threshold agrees with independent logarithmic inverse" {
  for use_secant in [false, true] {
    for target in [80.0, 70.0, 50.0, 21.0] {
      guard cooling_time(target, @root.Options::default(), use_secant~) is Ok(s)
        else { fail("valid cooling input rejected") }
      let analytic = -@math.ln((target - 20.0) / 60.0) / 0.1
      assert_true(s.converged())
      assert_true((s.root - analytic).abs() < 1.0e-10)
      assert_true(s.value.abs() < 1.0e-10)
    }
  }
}

test "cooling supports alternative units-consistent model parameters" {
  guard cooling_time(30.0, @root.Options::default(), initial=50.0,
    ambient=10.0, rate=0.2, horizon=10.0) is Ok(s)
    else { fail("custom cooling input rejected") }
  assert_true((s.root - @math.ln(2.0) / 0.2).abs() < 1.0e-10)
}

test "cooling rejects unreachable targets and invalid model parameters" {
  for target in [20.0, 19.0, 81.0, 0.0 / 0.0] {
    assert_true(cooling_time(target, @root.Options::default()) is Err(_))
  }
  assert_true(cooling_time(50.0, @root.Options::default(), horizon=1.0) is Err(_))
  assert_true(cooling_time(50.0, @root.Options::default(), rate=0.0) is Err(_))
  assert_true(cooling_time(50.0, @root.Options::default(), initial=10.0) is Err(_))
  assert_true(cooling_time(50.0, @root.Options::default(), horizon=1.0/0.0) is Err(_))
}

test "cooling does not turn budget exhaustion into a usable time" {
  guard cooling_time(50.0, { ..@root.Options::default(), max_iterations: 0 }) is Ok(s)
    else { fail("expected diagnostic result") }
  assert_false(s.converged())
  assert_true(s.reason is @root.IterationLimit)
}
