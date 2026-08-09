# Testing Rules

- Do not use one agent session to both modify production code and add unit
  tests. Assign those responsibilities to separate agents when delegation is
  available.
- Do not add tests for UI-only changes.
- Add or update tests for meaningful behavior or correctness risk. Skip trivial
  pass-through code, obvious accessors, and behavior already covered elsewhere.
- Prefer concrete production behavior and high-signal assertions. Avoid
  test-only protocols, mocks, overrides, or invasive production hooks for low
  value tests.
- When test sources change, follow `build-and-test.md` and run the relevant
  `xcodebuild test` scope.
