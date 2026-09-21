fn main {
  let f = fn(x : Double) -> Double { x * x - 2.0 }
  for result in [
    @root.bisect(f, 1.0, 2.0, @root.Options::default()),
    @root.safeguarded_secant(f, 1.0, 2.0, @root.Options::default()),
  ] {
    match result {
      Ok(solution) => {
        println("root=\{solution.root}, f(root)=\{solution.value}, reason=\{solution.reason.name()}")
        println("iterations=\{solution.iterations}, evaluations=\{solution.evaluations}, converged=\{solution.converged()}")
      }
      Err(error) => println("input error: \{error.message()}")
    }
  }
}
