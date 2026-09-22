# Use bracket-root from another MoonBit project

The general library accepts your own `(Double) -> Double` callback. The three
web/CLI presets are demonstrations, not the limit of the MoonBit API. The module
is currently named `local/bracket_root` and is **not published to Mooncakes**;
do not assume `moon add local/bracket_root` will work.

## Verified local dependency workflow

With the installed MoonBit toolchain and Node.js 18+, run from this repository:

```sh
node tools/test-consumer.mjs
```

The script copies the four files in `integration/consumer` into a fresh second
module under `build-runs/consumer-.../consumer`. Its parent `moon.work` resolves
the library from this checkout. It does not copy private solver functions into
the consumer, publish a package or fetch registry dependencies. It runs three
consumer tests and the consumer executable, retaining sources and logs.

The executable solves `x³ - 2 = 0` and its JSON root is independently compared
with JavaScript `Math.cbrt(2)` within `1e-11`. The tests cover both algorithms,
the trace opt-out, exhausted budgets versus input errors, and scan → refine →
export using public types. This checks integration, not real-user adoption.

## Set up your own sibling project

Use this layout, copying `integration/consumer` as the starting application:

```text
trial/
  moon.work
  bracket-root/     # this repository checkout
  consumer/         # the four files from integration/consumer
```

`trial/moon.work`:

```text
members = ["bracket-root", "consumer"]
```

`consumer/moon.mod` declares `import { "local/bracket_root@0.1.0" }` and its
`moon.pkg` imports `"local/bracket_root" @root`. The workspace resolves this
dependency to the checked-out source; it is not a registry installation.
From `trial`, run `moon -C consumer run . --target js --frozen`. For a retained,
fresh-directory verification use the script above. The current tested toolchain
is recorded in [REPRODUCING.md](REPRODUCING.md).

## Replace the equation and handle every outcome

```moonbit
match @root.bisect(x => x * x * x - 2.0, 1.0, 2.0, @root.Options::default()) {
  Ok(s) => {
    if s.converged() {
      println(s.to_json_string())
    } else {
      println("not converged: \{s.reason.name()}")
    }
  }
  Err(e) => println(e.message())
}
```

`Ok` means a diagnostic result is available, not necessarily convergence.
Ensure continuity, deterministic finite evaluations, and an appropriate bracket.
Interpret absolute position tolerance in the units of your unknown; inspect
residual separately. A residual tolerance is not a replacement for the solver's
position stopping contract. See [API](API.md) and [capability matrix](CAPABILITIES.md).

Local workspaces follow the [official MoonBit module guidance](https://docs.moonbitlang.com/en/stable/toolchain/moon/module.html#dependency-management).
