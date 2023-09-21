#import <Foundation/Foundation.h>

#import "FIRAnalytics.h"

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(macCatalyst, macos, tvos, watchos)
@interface FIRAnalytics (OnDevice)

/// Initiates on-device conversion measurement given a user email address. Requires dependency
/// GoogleAppMeasurementOnDeviceConversion to be linked in, otherwise it is a no-op.
/// @param emailAddress User email address. Include a domain name for all email addresses
///   (e.g. gmail.com or hotmail.co.jp).
+ (void)initiateOnDeviceConversionMeasurementWithEmailAddress:(NSString *)emailAddress
    NS_SWIFT_NAME(initiateOnDeviceConversionMeasurement(emailAddress:));

/// Initiates on-device conversion measurement given a phone number in E.164 format. Requires
/// dependency GoogleAppMeasurementOnDeviceConversion to be linked in, otherwise it is a no-op.
/// @param phoneNumber User phone number. Must be in E.164 format, which means it must be
///   limited to a maximum of 15 digits and must include a plus sign (+) prefix and country code
///   with no dashes, parentheses, or spaces.
+ (void)initiateOnDeviceConversionMeasurementWithPhoneNumber:(NSString *)phoneNumber
    NS_SWIFT_NAME(initiateOnDeviceConversionMeasurement(phoneNumber:));

@end

NS_ASSUME_NONNULL_END
