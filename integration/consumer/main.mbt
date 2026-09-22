// This is a separate application module, using only the documented public API.
// Its callback is intentionally different from the three fixed demo scenarios.
fn main {
  match @root.safeguarded_secant(
    x => x * x * x - 2.0, 1.0, 2.0, @root.Options::default(),
  ) {
    Ok(s) => {
      if !s.converged() { abort("estimate not converged: \{s.reason.name()}") }
      println(s.to_json_string())
    }
    Err(e) => abort(e.message())
  }
}
