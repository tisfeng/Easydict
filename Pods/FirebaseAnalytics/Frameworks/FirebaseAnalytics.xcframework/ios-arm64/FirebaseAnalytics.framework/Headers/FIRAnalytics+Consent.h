#import <Foundation/Foundation.h>

#import "FIRAnalytics.h"

NS_ASSUME_NONNULL_BEGIN

/// The type of consent to set. Supported consent types are `ConsentType.adStorage` and
/// `ConsentType.analyticsStorage`. Omitting a type retains its previous status.
typedef NSString *FIRConsentType NS_TYPED_ENUM NS_SWIFT_NAME(ConsentType);
extern FIRConsentType const FIRConsentTypeAdStorage;
extern FIRConsentType const FIRConsentTypeAnalyticsStorage;

/// The status value of the consent type. Supported statuses are `ConsentStatus.granted` and
/// `ConsentStatus.denied`.
typedef NSString *FIRConsentStatus NS_TYPED_ENUM NS_SWIFT_NAME(ConsentStatus);
extern FIRConsentStatus const FIRConsentStatusDenied;
extern FIRConsentStatus const FIRConsentStatusGranted;

/// Sets the applicable end user consent state.
@interface FIRAnalytics (Consent)

/// Sets the applicable end user consent state (e.g. for device identifiers) for this app on this
/// device. Use the consent settings to specify individual consent type values. Settings are
/// persisted across app sessions. By default consent types are set to `ConsentStatus.granted`.
///
/// @param consentSettings A Dictionary of consent types. Supported consent type keys are
///   `ConsentType.adStorage` and `ConsentType.analyticsStorage`. Valid values are
///   `ConsentStatus.granted` and `ConsentStatus.denied`.
+ (void)setConsent:(NSDictionary<FIRConsentType, FIRConsentStatus> *)consentSettings;

@end

NS_ASSUME_NONNULL_END
