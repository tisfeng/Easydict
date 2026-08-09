# Build and Test

## When to run Xcode validation

Run `xcodebuild` when any of the following applies:

- Swift, Objective-C, or other Xcode-compiled app source changes exceed 100
  substantive lines. Documentation, scripts, comments, and project metadata do
  not count toward this threshold.
- A test source under `EasydictTests/**/*.swift` is added or changed.
- The user explicitly requests a build or test.

Evaluate the threshold after implementation. Count added and deleted
substantive lines in the task-owned diff, excluding blank lines and unrelated
pre-existing changes. Recalculate if the implementation changes again.

Do not run concurrent `xcodebuild` commands against the same workspace and
DerivedData location. If the default DerivedData location is unavailable, use
an external temporary directory and remove it after validation.

## Common commands

```bash
# Build
xcodebuild build \
  -workspace Easydict.xcworkspace \
  -scheme Easydict | xcbeautify

# Test all tests
xcodebuild test \
  -workspace Easydict.xcworkspace \
  -scheme Easydict | xcbeautify

# Build for repeated test runs
xcodebuild build-for-testing \
  -workspace Easydict.xcworkspace \
  -scheme Easydict | xcbeautify

# Run a test suite after a compatible build-for-testing
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -only-testing:EasydictTests/<TestSuiteOrClass> | xcbeautify

# Run one test method
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -only-testing:EasydictTests/<TestSuiteOrClass>/<testMethod> | xcbeautify
```

Use `-only-testing:` when the changed test mapping is known. If the mapping is
unclear, run the relevant broader test target.

## Non-Xcode checks

- `git diff --check` for every change.
- `jq -e .` for changed `.xcstrings` or JSON data where applicable.
- `bash -n` for changed shell scripts.
- `swiftformat --lint` or the repository's existing formatter when Swift source
  changes.
- `scripts/check-agent-docs.sh` for repository documentation changes.
