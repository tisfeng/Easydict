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

@end

NS_ASSUME_NONNULL_END
