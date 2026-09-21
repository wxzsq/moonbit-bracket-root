fn Bracket::json_value(self : Bracket) -> Json {
  { "lower": self.lower.to_json(), "upper": self.upper.to_json(),
    "f_lower": self.f_lower.to_json(), "f_upper": self.f_upper.to_json() }
}

/// Versioned interchange format for solutions returned by the solvers.
pub fn Solution::to_json_string(self : Solution) -> String {
  let value : Json = {
    "schema_version": 1,
    "root": self.root.to_json(), "value": self.value.to_json(),
    "converged": self.converged().to_json(),
    "reason": self.reason.name().to_json(),
    "iterations": self.iterations.to_json(), "evaluations": self.evaluations.to_json(),
    "bracket": self.bracket.json_value(),
    "trace": @json.to_json(self.trace.map(b => b.json_value())),
  }
  value.stringify()
}

/// One row per saved snapshot; snapshot is not an iteration counter.
pub fn Solution::trace_csv(self : Solution) -> String {
  let rows = ["snapshot,lower,upper,f_lower,f_upper"]
  for i, b in self.trace {
    rows.push("\{i},\{b.lower},\{b.upper},\{b.f_lower},\{b.f_upper}")
  }
  rows.join("\n") + "\n"
}
