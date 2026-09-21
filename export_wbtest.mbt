test "JSON preserves nonconverged termination and numerical fields" {
  let s = solved(bisect(x => x * x - 2.0, 1.0, 2.0,
    { ..Options::default(), max_iterations: 0 }))
  let json = @json.parse(s.to_json_string()[:])
  assert_true(json is Object({ "schema_version": Number(1, ..),
    "reason": String("iteration_limit"), "converged": False,
    "root": Number(1, ..), "evaluations": Number(2, ..), .. }))
  assert_true(json is Object({ "trace": Array([Object({
    "lower": Number(1, ..), "upper": Number(2, ..), .. })]), .. }))
}

test "CSV endpoint history and compact export" {
  let s = solved(bisect(x => x, 0.0, 1.0, Options::default()))
  assert_eq(s.trace_csv(), "snapshot,lower,upper,f_lower,f_upper\n0,0,1,0,1\n1,0,0,0,0\n")
  let compact = solved(bisect(x => x, 0.0, 1.0, Options::default(), record_trace=false))
  assert_eq(compact.trace_csv(), "snapshot,lower,upper,f_lower,f_upper\n")
  assert_true(@json.parse(compact.to_json_string()[:]) is Object({ "trace": Array([]), .. }))
}
