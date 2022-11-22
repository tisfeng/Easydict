# [KVOController](https://github.com/facebook/KVOController)
[![Build Status](https://img.shields.io/travis/facebook/KVOController/master.svg?style=flat)](https://travis-ci.org/facebook/KVOController)
[![Coverage Status](https://img.shields.io/codecov/c/github/facebook/KVOController/master.svg)](https://codecov.io/github/facebook/KVOController)
[![Version](https://img.shields.io/cocoapods/v/KVOController.svg?style=flat)](http://cocoadocs.org/docsets/KVOController)
[![Platform](https://img.shields.io/cocoapods/p/KVOController.svg?style=flat)](http://cocoadocs.org/docsets/KVOController)

Key-value observing is a particularly useful technique for communicating between layers in a Model-View-Controller application. KVOController builds on Cocoa's time-tested key-value observing implementation. It offers a simple, modern API, that is also thread safe. Benefits include:

- Notification using blocks, custom actions, or NSKeyValueObserving callback.
- No exceptions on observer removal.
- Implicit observer removal on controller dealloc.
- Thread-safety with special guards against observer resurrection – [rdar://15985376](http://openradar.appspot.com/radar?id=5305010728468480).

For more information on KVO, see Apple's [Introduction to Key-Value Observing](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html).

## Usage

Example apps for iOS and OS X are included with the project. Here is one simple usage pattern:

```objective-c
// create KVO controller with observer
FBKVOController *KVOController = [FBKVOController controllerWithObserver:self];
self.KVOController = KVOController;

// observe clock date property
[self.KVOController observe:clock keyPath:@"date" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew block:^(ClockView *clockView, Clock *clock, NSDictionary *change) {

  // update clock view with new value
  clockView.date = change[NSKeyValueChangeNewKey];
}];
```

While simple, the above example is complete. A clock view creates a KVO controller to observe the clock date property. A block callback is used to handle initial and change notification. Unobservation happens implicitly on controller deallocation, since a strong reference to the `KVOController` is kept. 

Note: the observer specified must support weak references. The zeroing weak reference guards against notification of a deallocated observer instance.

#### NSObject Category
For an even easier usage, just `#import <KVOController/NSObject+FBKVOController.h>` for an automatic `KVOController` property on all objects.

```objc
[self.KVOController observe:clock keyPath:@"date" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew action:@selector(updateClockWithDateChange:)];
```

## Prerequisites

KVOController takes advantage of recent Objective-C runtime advances, including ARC and weak collections. It requires:

- iOS 6 or later.
- OS X 10.7 or later.

## Installation

To install using [CocoaPods](https://github.com/cocoapods/cocoapods), add the following to your project Podfile:

```ruby
pod 'KVOController'
```

To install using [Carthage](https://github.com/carthage/carthage), add the following to your project Cartfile:

```
github "facebook/KVOController"
```

Alternatively, drag and drop FBKVOController.h and FBKVOController.m into your Xcode project, agreeing to copy files if needed. For iOS applications, you can choose to link against the static library target of the KVOController project.

Having installed using CocoaPods or Carthage, add the following to import in Objective-C:
```objective-c
#import <KVOController/KVOController.h>
```

## Testing

The unit tests included use CocoaPods for managing dependencies. Install CocoaPods if you haven't already done so. Then, at the command line, navigate to the root KVOController directory and type:

```sh
pod install
```

This will install and add test dependencies on OCHamcrest and OCMockito. Re-open the Xcode KVOController workspace and Test, ⌘U.

## License

KVOController is released under a BSD License. See LICENSE file for details.
