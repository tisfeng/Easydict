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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The type of network that the device is running with. Values should correspond to the NetworkType
/// values in android/play/playlog/proto/clientanalytics.proto
typedef NS_ENUM(NSInteger, GULNetworkType) {
  GULNetworkTypeNone = -1,
  GULNetworkTypeMobile = 0,
  GULNetworkTypeWIFI = 1,
};

/// Collection of utilities to read network status information
@interface GULNetworkInfo : NSObject

/// Returns the cellular mobile country code (mcc) if CoreTelephony is supported, otherwise nil
+ (NSString *_Nullable)getNetworkMobileCountryCode;

/// Returns the cellular mobile network code (mnc) if CoreTelephony is supported, otherwise nil
+ (NSString *_Nullable)getNetworkMobileNetworkCode;

/**
 * Returns the formatted MccMnc if the inputs are valid, otherwise nil
 * @param mcc The Mobile Country Code returned from `getNetworkMobileCountryCode`
 * @param mnc The Mobile Network Code returned from `getNetworkMobileNetworkCode`
 * @returns A string with the concatenated mccMnc if both inputs are valid, otherwise nil
 */
+ (NSString *_Nullable)formatMcc:(NSString *_Nullable)mcc andMNC:(NSString *_Nullable)mnc;

/// Returns an enum indicating the network type. The enum values should be easily transferrable to
/// the NetworkType value in android/play/playlog/proto/clientanalytics.proto. Right now this always
/// returns None on platforms other than iOS. This should be updated in the future to return Wi-Fi
/// values for the other platforms when applicable.
+ (GULNetworkType)getNetworkType;

/// Returns a string indicating the radio access technology used by the app. The return value will
/// be one of CTRadioAccess constants defined in
/// https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/radio_access_technology_constants
+ (NSString *)getNetworkRadioType;

@end

NS_ASSUME_NONNULL_END
