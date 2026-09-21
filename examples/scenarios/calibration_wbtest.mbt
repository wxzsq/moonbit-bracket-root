test "calibration recovers known inputs across its declared domain" {
  for use_secant in [false, true] {
    for x in [0.0, 0.3, 2.5, 7.1, 10.0] {
      guard calibration(calibration_curve(x), @root.Options::default(), use_secant~) is Ok(s)
        else { fail("calibration unexpectedly failed") }
      assert_true(s.converged())
      assert_true((s.root - x).abs() < 2.0e-11)
      assert_true(s.value.abs() < 2.0e-11)
    }
  }
}

test "calibration rejects out of range and nonfinite responses" {
  assert_true(calibration(0.0, @root.Options::default()) is Err(@root.NoSignChange))
  assert_true(calibration(9.0, @root.Options::default()) is Err(@root.NoSignChange))
  assert_true(calibration(0.0 / 0.0, @root.Options::default()) is Err(@root.NonFiniteValue(0.0)))
}
