// Copyright 2022 Google LLC
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

#import "GoogleUtilities/Environment/Public/GoogleUtilities/GULNetworkInfo.h"

#import <Foundation/Foundation.h>

#import <TargetConditionals.h>
#if __has_include("CoreTelephony/CTTelephonyNetworkInfo.h") && !TARGET_OS_MACCATALYST && \
                  !TARGET_OS_OSX && !TARGET_OS_TV && !TARGET_OS_WATCH
#define TARGET_HAS_MOBILE_CONNECTIVITY
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#endif

@implementation GULNetworkInfo

#ifdef TARGET_HAS_MOBILE_CONNECTIVITY
+ (CTTelephonyNetworkInfo *)getNetworkInfo {
  static CTTelephonyNetworkInfo *networkInfo;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    networkInfo = [[CTTelephonyNetworkInfo alloc] init];
  });
  return networkInfo;
}
#endif

+ (NSString *_Nullable)getNetworkMobileCountryCode {
#ifdef TARGET_HAS_MOBILE_CONNECTIVITY
  CTTelephonyNetworkInfo *networkInfo = [GULNetworkInfo getNetworkInfo];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  CTCarrier *provider = networkInfo.subscriberCellularProvider;
#pragma clang diagnostic push
  return provider.mobileCountryCode;
#endif
  return nil;
}

+ (NSString *_Nullable)getNetworkMobileNetworkCode {
#ifdef TARGET_HAS_MOBILE_CONNECTIVITY
  CTTelephonyNetworkInfo *networkInfo = [GULNetworkInfo getNetworkInfo];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  CTCarrier *provider = networkInfo.subscriberCellularProvider;
#pragma clang diagnostic push
  return provider.mobileNetworkCode;
#endif
  return nil;
}

/**
 * Returns the formatted MccMnc if the inputs are valid, otherwise nil
 * @param mcc The Mobile Country Code returned from `getNetworkMobileCountryCode`
 * @param mnc The Mobile Network Code returned from `getNetworkMobileNetworkCode`
 * @returns A string with the concatenated mccMnc if both inputs are valid, otherwise nil
 */
+ (NSString *_Nullable)formatMcc:(NSString *)mcc andMNC:(NSString *)mnc {
  // These are both nil if the target does not support mobile connectivity
  if (mcc == nil && mnc == nil) {
    return nil;
  }

  if (mcc.length != 3 || mnc.length < 2 || mnc.length > 3) {
    return nil;
  }

  // If the resulting appended mcc + mnc contains characters that are not
  // decimal digits, return nil
  static NSCharacterSet *notDigits;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
  });
  NSString *mccMnc = [mcc stringByAppendingString:mnc];
  if ([mccMnc rangeOfCharacterFromSet:notDigits].location != NSNotFound) {
    return nil;
  }

  return mccMnc;
}

+ (GULNetworkType)getNetworkType {
  GULNetworkType networkType = GULNetworkTypeNone;

#ifdef TARGET_HAS_MOBILE_CONNECTIVITY
  static SCNetworkReachabilityRef reachabilityRef = 0;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorSystemDefault, "google.com");
  });

  if (!reachabilityRef) {
    return GULNetworkTypeNone;
  }

  SCNetworkReachabilityFlags reachabilityFlags = 0;
  SCNetworkReachabilityGetFlags(reachabilityRef, &reachabilityFlags);

  // Parse the network flags to set the network type.
  if (reachabilityFlags & kSCNetworkReachabilityFlagsReachable) {
    if (reachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN) {
      networkType = GULNetworkTypeMobile;
    } else {
      networkType = GULNetworkTypeWIFI;
    }
  }
#endif

  return networkType;
}

+ (NSString *)getNetworkRadioType {
#ifdef TARGET_HAS_MOBILE_CONNECTIVITY
  CTTelephonyNetworkInfo *networkInfo = [GULNetworkInfo getNetworkInfo];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  return networkInfo.currentRadioAccessTechnology;
#pragma clang diagnostic pop
#else
  return @"";
#endif
}

@end
