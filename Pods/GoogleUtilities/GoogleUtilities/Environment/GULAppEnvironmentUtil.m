// Copyright 2017 Google
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GoogleUtilities/Environment/Public/GoogleUtilities/GULAppEnvironmentUtil.h"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

#import "third_party/IsAppEncrypted/Public/IsAppEncrypted.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@implementation GULAppEnvironmentUtil

/// A key for the Info.plist to enable or disable checking if the App Store is running in a sandbox.
/// This will affect your data integrity when using Firebase Analytics, as it will disable some
/// necessary checks.
static NSString *const kFIRAppStoreReceiptURLCheckEnabledKey =
    @"FirebaseAppStoreReceiptURLCheckEnabled";

/// The file name of the sandbox receipt. This is available on iOS >= 8.0
static NSString *const kFIRAIdentitySandboxReceiptFileName = @"sandboxReceipt";

static BOOL HasSCInfoFolder(void) {
#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH
  NSString *bundlePath = [NSBundle mainBundle].bundlePath;
  NSString *scInfoPath = [bundlePath stringByAppendingPathComponent:@"SC_Info"];
  return [[NSFileManager defaultManager] fileExistsAtPath:scInfoPath];
#elif TARGET_OS_OSX
  return NO;
#endif
}

static BOOL HasEmbeddedMobileProvision(void) {
#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH
  return [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"].length > 0;
#elif TARGET_OS_OSX
  return NO;
#endif
}

+ (BOOL)isFromAppStore {
  static dispatch_once_t isEncryptedOnce;
  static BOOL isEncrypted = NO;

  dispatch_once(&isEncryptedOnce, ^{
    isEncrypted = IsAppEncrypted();
  });

  if ([GULAppEnvironmentUtil isSimulator]) {
    return NO;
  }

  // If an app contain the sandboxReceipt file, it means its coming from TestFlight
  // This must be checked before the SCInfo Folder check below since TestFlight apps may
  // also have an SCInfo folder.
  if ([GULAppEnvironmentUtil isAppStoreReceiptSandbox]) {
    return NO;
  }

  if (HasSCInfoFolder()) {
    // When iTunes downloads a .ipa, it also gets a customized .sinf file which is added to the
    // main SC_Info directory.
    return YES;
  }

  // For iOS >= 8.0, iTunesMetadata.plist is moved outside of the sandbox. Any attempt to read
  // the iTunesMetadata.plist outside of the sandbox will be rejected by Apple.
  // If the app does not contain the embedded.mobileprovision which is stripped out by Apple when
  // the app is submitted to store, then it is highly likely that it is from Apple Store.
  return isEncrypted && !HasEmbeddedMobileProvision();
}

+ (BOOL)isAppStoreReceiptSandbox {
  // Since checking the App Store's receipt URL can be memory intensive, check the option in the
  // Info.plist if developers opted out of this check.
  id enableSandboxCheck =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:kFIRAppStoreReceiptURLCheckEnabledKey];
  if (enableSandboxCheck && [enableSandboxCheck isKindOfClass:[NSNumber class]] &&
      ![enableSandboxCheck boolValue]) {
    return NO;
  }

  NSURL *appStoreReceiptURL = [NSBundle mainBundle].appStoreReceiptURL;
  NSString *appStoreReceiptFileName = appStoreReceiptURL.lastPathComponent;
  return [appStoreReceiptFileName isEqualToString:kFIRAIdentitySandboxReceiptFileName];
}

+ (BOOL)isSimulator {
#if TARGET_OS_SIMULATOR
  return YES;
#elif TARGET_OS_MACCATALYST
  return NO;
#elif TARGET_OS_IOS || TARGET_OS_TV
  NSString *platform = [GULAppEnvironmentUtil deviceModel];
  return [platform isEqual:@"x86_64"] || [platform isEqual:@"i386"];
#elif TARGET_OS_OSX
  return NO;
#endif
  return NO;
}

+ (NSString *)getSysctlEntry:(const char *)sysctlKey {
  static NSString *entryValue;
  size_t size;
  sysctlbyname(sysctlKey, NULL, &size, NULL, 0);
  if (size > 0) {
    char *entryValueCStr = malloc(size);
    sysctlbyname(sysctlKey, entryValueCStr, &size, NULL, 0);
    entryValue = [NSString stringWithCString:entryValueCStr encoding:NSUTF8StringEncoding];
    free(entryValueCStr);
    return entryValue;
  } else {
    return nil;
  }
}

+ (NSString *)deviceModel {
  static dispatch_once_t once;
  static NSString *deviceModel;

#if TARGET_OS_OSX || TARGET_OS_MACCATALYST
  dispatch_once(&once, ^{
    // The `uname` function only returns x86_64 for Macs. Use `sysctlbyname` instead, but fall back
    // to the `uname` function if it fails.
    deviceModel = [GULAppEnvironmentUtil getSysctlEntry:"hw.model"];
    if (deviceModel.length == 0) {
      struct utsname systemInfo;
      if (uname(&systemInfo) == 0) {
        deviceModel = [NSString stringWithUTF8String:systemInfo.machine];
      }
    }
  });
#else
  dispatch_once(&once, ^{
    struct utsname systemInfo;
    if (uname(&systemInfo) == 0) {
      deviceModel = [NSString stringWithUTF8String:systemInfo.machine];
    }
  });
#endif  // TARGET_OS_OSX || TARGET_OS_MACCATALYST
  return deviceModel;
}

+ (NSString *)deviceSimulatorModel {
  static dispatch_once_t once;
  static NSString *model = nil;

  dispatch_once(&once, ^{
#if TARGET_OS_SIMULATOR
#if TARGET_OS_WATCH
    model = @"watchOS Simulator";
#elif TARGET_OS_TV
    model = @"tvOS Simulator";
#elif defined(TARGET_OS_VISION) && TARGET_OS_VISION
    model = @"visionOS Simulator";
#elif TARGET_OS_IOS
    switch ([[UIDevice currentDevice] userInterfaceIdiom]) {
      case UIUserInterfaceIdiomPhone:
        model = @"iOS Simulator (iPhone)";
        break;
      case UIUserInterfaceIdiomPad:
        model = @"iOS Simulator (iPad)";
        break;
      default:
        model = @"iOS Simulator (Unknown)";
        break;
    }
#endif
#elif TARGET_OS_EMBEDDED
    model = [GULAppEnvironmentUtil getSysctlEntry:"hw.machine"];
#else
    model = [GULAppEnvironmentUtil getSysctlEntry:"hw.model"];
#endif
  });

  return model;
}

+ (NSString *)systemVersion {
#if TARGET_OS_IOS
  return [UIDevice currentDevice].systemVersion;
#elif TARGET_OS_OSX || TARGET_OS_TV || TARGET_OS_WATCH || \
    (defined(TARGET_OS_VISION) && TARGET_OS_VISION)
  // Assemble the systemVersion, excluding the patch version if it's 0.
  NSOperatingSystemVersion osVersion = [NSProcessInfo processInfo].operatingSystemVersion;
  NSMutableString *versionString = [[NSMutableString alloc]
      initWithFormat:@"%ld.%ld", (long)osVersion.majorVersion, (long)osVersion.minorVersion];
  if (osVersion.patchVersion != 0) {
    [versionString appendFormat:@".%ld", (long)osVersion.patchVersion];
  }
  return versionString;
#endif
}

+ (BOOL)isAppExtension {
#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH
  // Documented by <a href="https://goo.gl/RRB2Up">Apple</a>
  BOOL appExtension = [[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"];
  return appExtension;
#elif TARGET_OS_OSX
  return NO;
#endif
}

+ (BOOL)isIOS7OrHigher {
  return YES;
}

+ (BOOL)hasSwiftRuntime {
  // The class
  // [Swift._SwiftObject](https://github.com/apple/swift/blob/5eac3e2818eb340b11232aff83edfbd1c307fa03/stdlib/public/runtime/SwiftObject.h#L35)
  // is a part of Swift runtime, so it should be present if Swift runtime is available.

  BOOL hasSwiftRuntime =
      objc_lookUpClass("Swift._SwiftObject") != nil ||
      // Swift object class name before
      // https://github.com/apple/swift/commit/9637b4a6e11ddca72f5f6dbe528efc7c92f14d01
      objc_getClass("_TtCs12_SwiftObject") != nil;

  return hasSwiftRuntime;
}

+ (NSString *)applePlatform {
  NSString *applePlatform = @"unknown";

  // When a Catalyst app is run on macOS then both `TARGET_OS_MACCATALYST` and `TARGET_OS_IOS` are
  // `true`, which means the condition list is order-sensitive.
#if TARGET_OS_MACCATALYST
  applePlatform = @"maccatalyst";
#elif TARGET_OS_IOS && (!defined(TARGET_OS_VISION) || !TARGET_OS_VISION)
#if defined(__IPHONE_14_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
  if (@available(iOS 14.0, *)) {
    // Early iOS 14 betas do not include isiOSAppOnMac (#6969)
    applePlatform = ([[NSProcessInfo processInfo] respondsToSelector:@selector(isiOSAppOnMac)] &&
                     [NSProcessInfo processInfo].isiOSAppOnMac)
                        ? @"ios_on_mac"
                        : @"ios";
  } else {
    applePlatform = @"ios";
  }
#else   // defined(__IPHONE_14_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
  applePlatform = @"ios";
#endif  // defined(__IPHONE_14_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000

#elif TARGET_OS_TV
  applePlatform = @"tvos";
#elif TARGET_OS_OSX
  applePlatform = @"macos";
#elif TARGET_OS_WATCH
  applePlatform = @"watchos";
#elif defined(TARGET_OS_VISION) && TARGET_OS_VISION
  applePlatform = @"visionos";
#endif  // TARGET_OS_MACCATALYST

  return applePlatform;
}

+ (NSString *)appleDevicePlatform {
  NSString *firebasePlatform = [GULAppEnvironmentUtil applePlatform];
#if TARGET_OS_IOS
  // This check is necessary because iOS-only apps running on iPad
  // will report UIUserInterfaceIdiomPhone via UI_USER_INTERFACE_IDIOM().
  if ([firebasePlatform isEqualToString:@"ios"] &&
      ([[UIDevice currentDevice].model.lowercaseString containsString:@"ipad"] ||
       [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
    return @"ipados";
  }
#endif

  return firebasePlatform;
}

+ (NSString *)deploymentType {
#if SWIFT_PACKAGE
  NSString *deploymentType = @"swiftpm";
#elif FIREBASE_BUILD_CARTHAGE
  NSString *deploymentType = @"carthage";
#elif FIREBASE_BUILD_ZIP_FILE
  NSString *deploymentType = @"zip";
#elif COCOAPODS
  NSString *deploymentType = @"cocoapods";
#else
  NSString *deploymentType = @"unknown";
#endif

  return deploymentType;
}

@end
