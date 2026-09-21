fn failure(message : String) -> String {
  let value : Json = { "ok": false, "error": message.to_json() }
  value.stringify()
}

/// Primitive JS ABI: strings, numbers and a versioned JSON result.
pub fn solve_demo(
  scenario : String,
  target : Double,
  algorithm : String,
  abs_tolerance : Double,
  rel_tolerance : Double,
  max_iterations : Int,
) -> String {
  if algorithm != "bisect" && algorithm != "secant" { return failure("unknown algorithm") }
  if target != target || target.abs() > 1.7976931348623157e308 {
    return failure("target must be finite")
  }
  let use_secant = algorithm == "secant"
  let options : @root.Options = { abs_tolerance, rel_tolerance, max_iterations }
  let result = match scenario {
    "calibration" => match @scenarios.calibration(target, options, use_secant~) {
      Ok(s) => Ok(s)
      Err(e) => Err(e.message())
    }
    "cooling" => @scenarios.cooling_time(target, options, use_secant~)
    "sqrt" => {
      if target < 0.0 { return failure("square-root target must be nonnegative") }
      let upper = if target > 1.0 { target } else { 1.0 }
      let f = fn(x) { x * x - target }
      let solved = if use_secant {
        @root.safeguarded_secant(f, 0.0, upper, options)
      } else {
        @root.bisect(f, 0.0, upper, options)
      }
      match solved { Ok(s) => Ok(s); Err(e) => Err(e.message()) }
    }
    _ => Err("unknown scenario")
  }
  match result {
    Ok(s) => "{\"ok\":true,\"solution\":" + s.to_json_string() +
      ",\"csv\":" + s.trace_csv().to_json().stringify() + "}"
    Err(message) => failure(message)
  }
}
