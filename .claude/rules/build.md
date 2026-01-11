# Build Commands

```bash
# Open workspace in Xcode (NOT the .xcodeproj)
open Easydict.xcworkspace

# Build
xcodebuild build \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ./DerivedData | xcbeautify

# Build for testing
xcodebuild build-for-testing \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ./DerivedData | xcbeautify

# e.g. run specific test class, -only-testing:<Target>/<TestClass>
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ./DerivedData \
  -only-testing:EasydictTests/UtilityFunctionsTests | xcbeautify

# e.g. run specific test method, -only-testing:<Target>/<TestClass>/<testMethod>
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ./DerivedData \
  -only-testing:EasydictTests/UtilityFunctionsTests/testAES | xcbeautify
```
