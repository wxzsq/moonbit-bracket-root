fn main {
  match @scenarios.cooling_time(50.0, @root.Options::default()) {
    Ok(s) => println(s.to_json_string())
    Err(message) => abort(message)
  }
}
