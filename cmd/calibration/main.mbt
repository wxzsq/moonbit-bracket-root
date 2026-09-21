fn main {
  match @scenarios.calibration(2.375, @root.Options::default()) {
    Ok(s) => println(s.to_json_string())
    Err(e) => abort(e.message())
  }
}
