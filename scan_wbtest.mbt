test "scan locates two separate crossings and feeds each solver" {
  let f = fn(x) { (x - 0.3) * (x - 0.7) }
  let mut calls = 0
  let result = scan_brackets(fn(x) { calls = calls + 1; f(x) }, 0.0, 1.0, 2)
  guard result is Ok(scan) else { fail("scan failed") }
  assert_eq(scan.evaluations, calls)
  assert_eq(scan.evaluations, 3)
  assert_eq(scan.brackets.length(), 2)
  for i, b in scan.brackets {
    let s = solved(bisect(f, b.lower, b.upper, Options::default()))
    assert_true(magnitude(s.root - [0.3, 0.7][i]) < 2.0e-12)
  }
}

test "sampled zeros appear once and are not ambiguous zero brackets" {
  guard scan_brackets(x => x * (x - 0.5) * (x - 1.0), 0.0, 1.0, 4) is Ok(s)
    else { fail("scan failed") }
  assert_eq(s.exact_zeros, [0.0, 0.5, 1.0])
  assert_eq(s.brackets.length(), 0)
}

test "scan explicitly cannot discover an unsampled tangent root" {
  guard scan_brackets(x => (x - 0.3) * (x - 0.3), 0.0, 1.0, 2) is Ok(s)
    else { fail("scan failed") }
  assert_eq(s.brackets.length(), 0)
  assert_eq(s.exact_zeros.length(), 0)
}

test "scan validates resource limits nonfinite values and representability" {
  assert_true(scan_brackets(x => x, 1.0, 0.0, 2) is Err(InvalidScanBounds))
  for n in [0, -1, 1000001] {
    assert_true(scan_brackets(x => x, 0.0, 1.0, n) is Err(InvalidSegments))
  }
  assert_true(scan_brackets(_ => 1.0 / 0.0, 0.0, 1.0, 2) is Err(NonFiniteSample(0.0)))
  assert_true(scan_brackets(x => x, 1.0, 1.0000000000000002, 2) is Err(IndistinguishableSamples))
  guard scan_brackets(x => x, -1.7e308, 1.7e308, 2) is Ok(s)
    else { fail("extreme scan failed") }
  assert_eq(s.exact_zeros, [0.0])
}
