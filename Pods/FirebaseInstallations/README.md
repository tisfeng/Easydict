<p align="center">
  <a href="https://cocoapods.org/pods/Firebase">
    <img src="https://img.shields.io/github/v/release/Firebase/firebase-ios-sdk?style=flat&label=CocoaPods"/>
  </a>
  <a href="https://swiftpackageindex.com/firebase/firebase-ios-sdk">
    <img src="https://img.shields.io/github/v/release/Firebase/firebase-ios-sdk?style=flat&label=Swift%20Package%20Index&color=red"/>
  </a>
  <a href="https://cocoapods.org/pods/Firebase">
    <img src="https://img.shields.io/github/license/Firebase/firebase-ios-sdk?style=flat"/>
  </a><br/>
  <a href="https://swiftpackageindex.com/firebase/firebase-ios-sdk">
    <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffirebase%2Ffirebase-ios-sdk%2Fbadge%3Ftype%3Dplatforms"/>
  </a>
  <a href="https://swiftpackageindex.com/firebase/firebase-ios-sdk">
    <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffirebase%2Ffirebase-ios-sdk%2Fbadge%3Ftype%3Dswift-versions"/>
  </a>
</p>

# Firebase Apple Open Source Development

This repository contains the source code for all Apple platform Firebase SDKs except FirebaseAnalytics.

Firebase is an app development platform with tools to help you build, grow, and
monetize your app. More information about Firebase can be found on the
[official Firebase website](https://firebase.google.com).

## Installation

See the subsections below for details about the different installation methods. Where
available, it's recommended to install any libraries with a `Swift` suffix to get the
best experience when writing your app in Swift.

1. [Standard pod install](#standard-pod-install)
2. [Swift Package Manager](#swift-package-manager)
3. [Installing from the GitHub repo](#installing-from-github)
4. [Experimental Carthage](#carthage-ios-only)

### Standard pod install

For instructions on the standard pod install, visit:
[https://firebase.google.com/docs/ios/setup](https://firebase.google.com/docs/ios/setup).

### Swift Package Manager

Instructions for [Swift Package Manager](https://swift.org/package-manager/) support can be
found in the [SwiftPackageManager.md](SwiftPackageManager.md) Markdown file.

### Installing from GitHub

These instructions can be used to access the Firebase repo at other branches,
tags, or commits.

#### Background

See [the Podfile Syntax Reference](https://guides.cocoapods.org/syntax/podfile.html#pod)
for instructions and options about overriding pod source locations.

#### Accessing Firebase Source Snapshots

All official releases are tagged in this repo and available via CocoaPods. To access a local
source snapshot or unreleased branch, use Podfile directives like the following:

To access FirebaseFirestore via a branch:
```ruby
pod 'FirebaseCore', :git => 'https://github.com/firebase/firebase-ios-sdk.git', :branch => 'master'
pod 'FirebaseFirestore', :git => 'https://github.com/firebase/firebase-ios-sdk.git', :branch => 'master'
```

To access FirebaseMessaging via a checked-out version of the firebase-ios-sdk repo:
```ruby
pod 'FirebaseCore', :path => '/path/to/firebase-ios-sdk'
pod 'FirebaseMessaging', :path => '/path/to/firebase-ios-sdk'
```

### Carthage (iOS only)

Instructions for the experimental Carthage distribution can be found at
[Carthage.md](Carthage.md).

### Using Firebase from a Framework or a library

For details on using Firebase from a Framework or a library, refer to [firebase_in_libraries.md](docs/firebase_in_libraries.md).

## Development

To develop Firebase software in this repository, ensure that you have at least
the following software:

* Xcode 14.1 (or later)

CocoaPods is still the canonical way to develop, but much of the repo now supports
development with Swift Package Manager.

### CocoaPods

Install the following:
* CocoaPods 1.10.0 (or later)
* [CocoaPods generate](https://github.com/square/cocoapods-generate)

For the pod that you want to develop:

```ruby
pod gen Firebase{name here}.podspec --local-sources=./ --auto-open --platforms=ios
```

Note: If the CocoaPods cache is out of date, you may need to run
`pod repo update` before the `pod gen` command.

Note: Set the `--platforms` option to `macos` or `tvos` to develop/test for
those platforms. Since 10.2, Xcode does not properly handle multi-platform
CocoaPods workspaces.

Firestore has a self-contained Xcode project. See
[Firestore/README](Firestore/README.md) Markdown file.

#### Development for Catalyst
* `pod gen {name here}.podspec --local-sources=./ --auto-open --platforms=ios`
* Check the Mac box in the App-iOS Build Settings
* Sign the App in the Settings Signing & Capabilities tab
* Click Pods in the Project Manager
* Add Signing to the iOS host app and unit test targets
* Select the Unit-unit scheme
* Run it to build and test

Alternatively, disable signing in each target:
* Go to Build Settings tab
* Click `+`
* Select `Add User-Defined Setting`
* Add `CODE_SIGNING_REQUIRED` setting with a value of `NO`

### Swift Package Manager
* To enable test schemes: `./scripts/setup_spm_tests.sh`
* `open Package.swift` or double click `Package.swift` in Finder.
* Xcode will open the project
  * Choose a scheme for a library to build or test suite to run
  * Choose a target platform by selecting the run destination along with the scheme

### Adding a New Firebase Pod

Refer to [AddNewPod](AddNewPod.md) Markdown file for details.

### Managing Headers and Imports

For information about managing headers and imports, see [HeadersImports](HeadersImports.md) Markdown file.

### Code Formatting

To ensure that the code is formatted consistently, run the script
[./scripts/check.sh](https://github.com/firebase/firebase-ios-sdk/blob/master/scripts/check.sh)
before creating a pull request (PR).

GitHub Actions will verify that any code changes are done in a style-compliant
way. Install `clang-format` and `mint`:

```console
brew install clang-format@17
brew install mint
```

### Running Unit Tests

Select a scheme and press Command-u to build a component and run its unit tests.

### Running Sample Apps
To run the sample apps and integration tests, you'll need a valid
`GoogleService-Info.plist
` file. The Firebase Xcode project contains dummy plist
files without real values, but they can be replaced with real plist files. To get your own
`GoogleService-Info.plist` files:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Create a new Firebase project, if you don't already have one
3. For each sample app you want to test, create a new Firebase app with the sample app's bundle
identifier (e.g., `com.google.Database-Example`)
4. Download the resulting `GoogleService-Info.plist` and add it to the Xcode project.

### Coverage Report Generation

For coverage report generation instructions, see [scripts/code_coverage_report/README](scripts/code_coverage_report/README.md) Markdown file.

## Specific Component Instructions
See the sections below for any special instructions for those components.

### Firebase Auth

For specific Firebase Auth development, refer to the [Auth Sample README](FirebaseAuth/Tests/Sample/README.md) for instructions about
building and running the FirebaseAuth pod along with various samples and tests.

### Firebase Database

The Firebase Database Integration tests can be run against a locally running Database Emulator
or against a production instance.

To run against a local emulator instance, invoke `./scripts/run_database_emulator.sh start` before
running the integration test.

To run against a production instance, provide a valid `GoogleServices-Info.plist` and copy it to
`FirebaseDatabase/Tests/Resources/GoogleService-Info.plist`. Your Security Rule must be set to
[public](https://firebase.google.com/docs/database/security/quickstart) while your tests are
running.

### Firebase Performance Monitoring

For specific Firebase Performance Monitoring development, see
[the Performance README](FirebasePerformance/README.md) for instructions about building the SDK
and [the Performance TestApp README](FirebasePerformance/Tests/TestApp/README.md) for instructions about
integrating Performance with the dev test App.

### Firebase Storage

To run the Storage Integration tests, follow the instructions in
[StorageIntegration.swift](FirebaseStorage/Tests/Integration/StorageIntegration.swift).

#### Push Notifications

Push notifications can only be delivered to specially provisioned App IDs in the developer portal.
In order to test receiving push notifications, you will need to:

1. Change the bundle identifier of the sample app to something you own in your Apple Developer
account and enable that App ID for push notifications.
2. You'll also need to
[upload your APNs Provider Authentication Key or certificate to the
Firebase Console](https://firebase.google.com/docs/cloud-messaging/ios/certs)
at **Project Settings > Cloud Messaging > [Your Firebase App]**.
3. Ensure your iOS device is added to your Apple Developer portal as a test device.

#### iOS Simulator

The iOS Simulator cannot register for remote notifications and will not receive push notifications.
To receive push notifications, follow the steps above and run the app on a physical device.

## Building with Firebase on Apple platforms

Firebase 8.9.0 introduced official beta support for macOS, Catalyst, and tvOS. watchOS continues
to be community supported. Thanks to community contributions for many of the multi-platform PRs.

At this time, most of Firebase's products are available across Apple platforms. There are still
a few gaps, especially on watchOS. For details about the current support matrix, see
[this chart](https://firebase.google.com/docs/ios/learn-more#firebase_library_support_by_platform)
in Firebase's documentation.

### watchOS
Thanks to contributions from the community, many of Firebase SDKs now compile, run unit tests, and
work on watchOS. See the [Independent Watch App Sample](Example/watchOSSample).

Keep in mind that watchOS is not officially supported by Firebase. While we can catch basic unit
test issues with GitHub Actions, there may be some changes where the SDK no longer works as expected
on watchOS. If you encounter this, please
[file an issue](https://github.com/firebase/firebase-ios-sdk/issues).

During app setup in the console, you may get to a step that mentions something like "Checking if the
app has communicated with our servers". This relies on Analytics and will not work on watchOS.
**It's safe to ignore the message and continue**, the rest of the SDKs will work as expected.

#### Additional Crashlytics Notes
* watchOS has limited support. Due to watchOS restrictions, mach exceptions and signal crashes are
not recorded. (Crashes in SwiftUI are generated as mach exceptions, so will not be recorded)

## Combine
Thanks to contributions from the community, _FirebaseCombineSwift_ contains support for Apple's Combine
framework. This module is currently under development and not yet supported for use in production
environments. For more details, please refer to the [docs](FirebaseCombineSwift/README.md).

## Roadmap

See [Roadmap](ROADMAP.md) for more about the Firebase Apple SDK Open Source
plans and directions.

## Contributing

See [Contributing](CONTRIBUTING.md) for more information on contributing to the Firebase
Apple SDK.

## License

The contents of this repository are licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

Your use of Firebase is governed by the
[Terms of Service for Firebase Services](https://firebase.google.com/terms/).
