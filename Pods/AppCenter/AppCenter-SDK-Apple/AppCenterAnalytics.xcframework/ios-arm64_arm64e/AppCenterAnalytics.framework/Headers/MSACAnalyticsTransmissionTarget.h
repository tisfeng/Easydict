// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#ifndef ANALYTICS_TRANSMISSION_TARGET
#define ANALYTICS_TRANSMISSION_TARGET

#if __has_include(<AppCenter/MSACConstants+Flags.h>)
#import <AppCenter/MSACConstants+Flags.h>
#else
#import "MSACConstants+Flags.h"
#endif

#if __has_include(<AppCenterAnalytics/MSACAnalyticsAuthenticationProvider.h>)
#import <AppCenterAnalytics/MSACAnalyticsAuthenticationProvider.h>
#import <AppCenterAnalytics/MSACPropertyConfigurator.h>
#else
#import "MSACAnalyticsAuthenticationProvider.h"
#import "MSACPropertyConfigurator.h"
#endif

@class MSACEventProperties;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AnalyticsTransmissionTarget)
@interface MSACAnalyticsTransmissionTarget : NSObject

/**
 * Property configurator.
 */
@property(nonatomic, readonly, strong) MSACPropertyConfigurator *propertyConfigurator;

+ (void)addAuthenticationProvider:(MSACAnalyticsAuthenticationProvider *)authenticationProvider
    NS_SWIFT_NAME(addAuthenticationProvider(authenticationProvider:));

/**
 * Track an event.
 *
 * @param eventName  event name.
 */
- (void)trackEvent:(NSString *)eventName;

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 */
- (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 * @param flags      Optional flags. Events tracked with the MSACFlagsCritical flag will take precedence over all other events in
 * storage. An event tracked with this option will only be dropped if storage must make room for a newer event that is also marked with the
 * MSACFlagsCritical flag.
 */
- (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties flags:(MSACFlags)flags;

/**
 * Track a custom event with name and optional typed properties.
 *
 * @param eventName  Event name.
 * @param properties Typed properties.
 *
 * @discussion The following validation rules are applied:
 *
 * The name cannot be null or empty.
 *
 * The property names or values cannot be null.
 *
 * Double values must be finite (NaN or Infinite values are discarded).
 *
 * Additional validation rules apply depending on the configured secret.
 *
 * - The event name needs to match the `[a-zA-Z0-9]((\.(?!(\.|$)))|[_a-zA-Z0-9]){3,99}` regular expression.
 *
 * - The `baseData` and `baseDataType` properties are reserved and thus discarded.
 *
 * - The full event size when encoded as a JSON string cannot be larger than 1.9MB.
 */
- (void)trackEvent:(NSString *)eventName
    withTypedProperties:(nullable MSACEventProperties *)properties NS_SWIFT_NAME(trackEvent(_:withProperties:));

/**
 * Track a custom event with name and optional typed properties.
 *
 * @param eventName  Event name.
 * @param properties Typed properties.
 * @param flags      Optional flags. Events tracked with the MSACFlagsCritical flag will take precedence over all other events in
 * storage. An event tracked with this option will only be dropped if storage must make room for a newer event that is also marked with the
 * MSACFlagsCritical flag.
 *
 * @discussion The following validation rules are applied:
 *
 * The name cannot be null or empty.
 *
 * The property names or values cannot be null.
 *
 * Double values must be finite (NaN or Infinite values are discarded).
 *
 * Additional validation rules apply depending on the configured secret.
 *
 * - The event name needs to match the `[a-zA-Z0-9]((\.(?!(\.|$)))|[_a-zA-Z0-9]){3,99}` regular expression.
 *
 * - The `baseData` and `baseDataType` properties are reserved and thus discarded.
 *
 * - The full event size when encoded as a JSON string cannot be larger than 1.9MB.
 */
- (void)trackEvent:(NSString *)eventName
    withTypedProperties:(nullable MSACEventProperties *)properties
                  flags:(MSACFlags)flags NS_SWIFT_NAME(trackEvent(_:withProperties:flags:));

/**
 * Get a nested transmission target.
 *
 * @param token The token of the transmission target to retrieve.
 *
 * @returns A transmission target object nested to this parent transmission target.
 */
- (MSACAnalyticsTransmissionTarget *)transmissionTargetForToken:(NSString *)token NS_SWIFT_NAME(transmissionTarget(forToken:));

/**
 * The flag indicates whether or not this transmission target is enabled. Changing its state will also change states of nested transmission
 * targets.
 */
@property(nonatomic, getter=isEnabled, setter=setEnabled:) BOOL enabled NS_SWIFT_NAME(enabled);

/**
 * Pause sending logs for the transmission target. It doesn't pause any of its decendants.
 *
 * @see resume
 */
- (void)pause;

/**
 * Resume sending logs for the transmission target.
 *
 * @see pause
 */
- (void)resume;

@end

NS_ASSUME_NONNULL_END

#endif
