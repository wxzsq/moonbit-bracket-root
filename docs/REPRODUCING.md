# Reproduce the library checks

Prerequisites: Node.js 18+ and a MoonBit toolchain. No npm packages or paid services
are required. Tests use the standard library bundled with your toolchain and
`--frozen` prevents dependency updates.

From the repository root:

```sh
node tools/verify.mjs
```

If `moon` is not on PATH, set `MOON_HOME` to your existing toolchain directory
(the directory containing `bin` and `lib`). Alternatively, `MOON_BIN` selects an
executable while keeping the existing MoonBit environment.

```powershell
$env:MOON_HOME = 'D:\tools\moonbit'
node tools/verify.mjs
```

The runner checks the compiler version, executes every JavaScript target test,
and runs square-root, calibration and cooling examples, then the JavaScript ABI
and CLI exit-code checks. A nonzero exit means verification failed.
Each run creates a unique `build-runs/` directory, redirects temporary files
there, and retains logs. It never cleans or deletes previous results. Compiler
versions appear in `moon-version.log`; success is recorded in `result.json`.

This is a software check, not competition acceptance. Other backends are not
claimed as validated by this JavaScript-only command.
