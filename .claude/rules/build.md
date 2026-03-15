# Build Commands

```bash
# Open workspace in Xcode (NOT the .xcodeproj)
open Easydict.xcworkspace

# Uses this machine's Xcode DerivedData directory. Update the home path if needed on another Mac.
# Install xcbeautify first, for example: brew install xcbeautify

# Build
xcodebuild build \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData | xcbeautify

# Build for testing
xcodebuild build-for-testing \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData | xcbeautify

# e.g. run specific test class, -only-testing:<Target>/<TestClass>
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData \
  -only-testing:EasydictTests/UtilityFunctionsTests | xcbeautify

# e.g. run specific test method, -only-testing:<Target>/<TestClass>/<testMethod>
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData \
  -only-testing:EasydictTests/UtilityFunctionsTests/testAES | xcbeautify
```
