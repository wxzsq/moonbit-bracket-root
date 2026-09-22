test "consumer can change a model and use either solver with compact history" {
  for secant in [false, true] {
    let f = fn(x) { x * x * x - 2.0 }
    let result = if secant {
      @root.safeguarded_secant(f, 1.0, 2.0, @root.Options::default(), record_trace=false)
    } else {
      @root.bisect(f, 1.0, 2.0, @root.Options::default(), record_trace=false)
    }
    guard result is Ok(s) else { fail("public solver rejected a valid model") }
    assert_true(s.converged())
    assert_true(s.value.abs() < 1.0e-10)
    assert_eq(s.trace.length(), 0)
    assert_eq(s.evaluations, s.iterations + 2)
  }
}

test "consumer handles nonconvergence separately from invalid inputs" {
  let options = { ..@root.Options::default(), max_iterations: 0 }
  guard @root.bisect(x => x * x * x - 2.0, 1.0, 2.0, options) is Ok(s)
    else { fail("expected budget diagnostic") }
  assert_false(s.converged())
  assert_true(s.reason is @root.IterationLimit)
  assert_true(@root.bisect(x => x * x + 1.0, -1.0, 1.0, options) is Err(@root.NoSignChange))
}

test "consumer can scan refine and export using only public types" {
  let f = fn(x) { (x - 0.3) * (x - 0.7) }
  guard @root.scan_brackets(f, 0.0, 1.0, 2) is Ok(scan)
    else { fail("candidate scan failed") }
  assert_eq(scan.brackets.length(), 2)
  for b in scan.brackets {
    guard @root.bisect(f, b.lower, b.upper, @root.Options::default()) is Ok(s)
      else { fail("candidate refinement failed") }
    assert_true(s.converged())
    assert_true(s.to_json_string().contains("\"schema_version\":1"))
    assert_true(s.trace_csv().has_prefix("snapshot,lower,upper,f_lower,f_upper\n"))
  }
  assert_true(@root.scan_brackets(f, 0.0, 1.0, 0) is Err(@root.InvalidSegments))
}
