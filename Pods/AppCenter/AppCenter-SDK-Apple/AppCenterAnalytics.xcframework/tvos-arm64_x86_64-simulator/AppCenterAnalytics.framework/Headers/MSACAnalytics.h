// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef MSAC_ANALYTICS_H
#define MSAC_ANALYTICS_H

#if __has_include(<AppCenter/MSACServiceAbstract.h>)
#import <AppCenter/MSACServiceAbstract.h>
#else
#import "MSACServiceAbstract.h"
#endif

#if __has_include(<AppCenterAnalytics/MSACAnalyticsTransmissionTarget.h>)
#import <AppCenterAnalytics/MSACAnalyticsTransmissionTarget.h>
#else
#import "MSACAnalyticsTransmissionTarget.h"
#endif

@class MSACEventProperties;

NS_ASSUME_NONNULL_BEGIN

/**
 * App Center analytics service.
 */
NS_SWIFT_NAME(Analytics)
@interface MSACAnalytics : MSACServiceAbstract

/**
 * Track an event.
 *
 * @param eventName  Event name. Cannot be `nil` or empty.
 *
 * @discussion Validation rules apply depending on the configured secret.
 *
 * For App Center, the name cannot be longer than 256 and is truncated otherwise.
 *
 * For One Collector, the name needs to match the `[a-zA-Z0-9]((\.(?!(\.|$)))|[_a-zA-Z0-9]){3,99}` regular expression.
 */
+ (void)trackEvent:(NSString *)eventName;

/**
 * Track a custom event with optional string properties.
 *
 * @param eventName  Event name. Cannot be `nil` or empty.
 * @param properties Dictionary of properties. Keys and values must not be `nil`.
 *
 * @discussion Additional validation rules apply depending on the configured secret.
 *
 * For App Center:
 *
 * - The event name cannot be longer than 256 and is truncated otherwise.
 *
 * - The property names cannot be empty.
 *
 * - The property names and values are limited to 125 characters each (truncated).
 *
 * - The number of properties per event is limited to 20 (truncated).
 *
 *
 * For One Collector:
 *
 * - The event name needs to match the `[a-zA-Z0-9]((\.(?!(\.|$)))|[_a-zA-Z0-9]){3,99}` regular expression.
 *
 * - The `baseData` and `baseDataType` properties are reserved and thus discarded.
 *
 * - The full event size when encoded as a JSON string cannot be larger than 1.9MB.
 */
+ (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

/**
 * Track a custom event with optional string properties.
 *
 * @param eventName  Event name. Cannot be `nil` or empty.
 * @param properties Dictionary of properties. Keys and values must not be `nil`.
 * @param flags      Optional flags. Events tracked with the MSACFlagsCritical flag will take precedence over all other events in
 * storage. An event tracked with this option will only be dropped if storage must make room for a newer event that is also marked with the
 * MSACFlagsCritical flag.
 *
 * @discussion Additional validation rules apply depending on the configured secret.
 *
 * For App Center:
 *
 * - The event name cannot be longer than 256 and is truncated otherwise.
 *
 * - The property names cannot be empty.
 *
 * - The property names and values are limited to 125 characters each (truncated).
 *
 * - The number of properties per event is limited to 20 (truncated).
 *
 *
 * For One Collector:
 *
 * - The event name needs to match the `[a-zA-Z0-9]((\.(?!(\.|$)))|[_a-zA-Z0-9]){3,99}` regular expression.
 *
 * - The `baseData` and `baseDataType` properties are reserved and thus discarded.
 *
 * - The full event size when encoded as a JSON string cannot be larger than 1.9MB.
 */
+ (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties flags:(MSACFlags)flags;

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
 *
 * For App Center:
 *
 * - The event name cannot be longer than 256 and is truncated otherwise.
 *
 * - The property names cannot be empty.
 *
 * - The property names and values are limited to 125 characters each (truncated).
 *
 * - The number of properties per event is limited to 20 (truncated).
 *
 *
 * For One Collector:
 *
 * - The event name needs to match the `[a-zA-Z0-9]((\.(?!(\.|$)))|[_a-zA-Z0-9]){3,99}` regular expression.
 *
 * - The `baseData` and `baseDataType` properties are reserved and thus discarded.
 *
 * - The full event size when encoded as a JSON string cannot be larger than 1.9MB.
 */
+ (void)trackEvent:(NSString *)eventName
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
 *
 * For App Center:
 *
 * - The event name cannot be longer than 256 and is truncated otherwise.
 *
 * - The property names cannot be empty.
 *
 * - The property names and values are limited to 125 characters each (truncated).
 *
 * - The number of properties per event is limited to 20 (truncated).
 *
 *
 * For One Collector:
 *
 * - The event name needs to match the `[a-zA-Z0-9]((\.(?!(\.|$)))|[_a-zA-Z0-9]){3,99}` regular expression.
 *
 * - The `baseData` and `baseDataType` properties are reserved and thus discarded.
 *
 * - The full event size when encoded as a JSON string cannot be larger than 1.9MB.
 */
+ (void)trackEvent:(NSString *)eventName
    withTypedProperties:(nullable MSACEventProperties *)properties
                  flags:(MSACFlags)flags NS_SWIFT_NAME(trackEvent(_:withProperties:flags:));

/**
 * Pause transmission of Analytics logs. While paused, Analytics logs are saved to disk.
 *
 * @see resume
 */
+ (void)pause;

/**
 * Resume transmission of Analytics logs. Any Analytics logs that accumulated on disk while paused are sent to the
 * server.
 *
 * @see pause
 */
+ (void)resume;

/**
 * Start a new session if manual session tracker is enabled, otherwise do nothing.
 */
+ (void)startSession;

/**
 * Enable manual session tracker.
 */
+ (void)enableManualSessionTracker;

/**
 * Get a transmission target.
 *
 * @param token The token of the transmission target to retrieve.
 *
 * @returns The transmission target object.
 *
 * @discussion This method does not need to be annotated with
 * NS_SWIFT_NAME(transmissionTarget(forToken:)) as this is a static method that
 * doesn't get translated like a setter in Swift.
 *
 * @see MSACAnalyticsTransmissionTarget for comparison.
 */
+ (MSACAnalyticsTransmissionTarget *)transmissionTargetForToken:(NSString *)token NS_SWIFT_NAME(transmissionTarget(forToken:));

/**
 * Send time interval for non-critical logs.
 * Must be between 3 seconds and 86400 seconds (1 day).
 * Must be called before Analytics service start.
 */
@property(class, atomic) NSUInteger transmissionInterval;

@end

NS_ASSUME_NONNULL_END

#endif
