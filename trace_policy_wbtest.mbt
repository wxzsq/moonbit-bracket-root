test "disabling history preserves numerical results and callback counts" {
  for use_secant in [false, true] {
    let mut calls = 0
    let compact = solved(solve(fn(x) {
      calls = calls + 1
      x * x - 2.0
    }, 1.0, 2.0, Options::default(), use_secant, record_trace=false))
    let recorded = solved(solve(x => x * x - 2.0, 1.0, 2.0, Options::default(), use_secant))
    assert_eq(compact.root, recorded.root)
    assert_eq(compact.value, recorded.value)
    assert_eq(compact.bracket.lower, recorded.bracket.lower)
    assert_eq(compact.bracket.upper, recorded.bracket.upper)
    assert_eq(compact.reason, recorded.reason)
    assert_eq(compact.iterations, recorded.iterations)
    assert_eq(compact.evaluations, calls)
    assert_eq(compact.trace.length(), 0)
    assert_true(recorded.trace.length() > 1)
  }
}

test "public APIs omit endpoint and budget histories when requested" {
  let endpoint = solved(bisect(x => x, 0.0, 1.0, Options::default(), record_trace=false))
  assert_eq(endpoint.reason, ExactZero)
  assert_eq(endpoint.trace.length(), 0)
  let budget = solved(safeguarded_secant(x => x * x - 2.0, 1.0, 2.0,
    { ..Options::default(), max_iterations: 0 }, record_trace=false))
  assert_eq(budget.reason, IterationLimit)
  assert_eq(budget.trace.length(), 0)
  assert_eq(budget.evaluations, 2)
}
