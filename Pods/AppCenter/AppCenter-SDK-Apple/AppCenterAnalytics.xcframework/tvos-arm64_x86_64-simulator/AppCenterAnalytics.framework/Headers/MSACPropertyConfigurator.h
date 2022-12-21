// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PropertyConfigurator)
@interface MSACPropertyConfigurator : NSObject

/**
 * Override the application version.
 *
 */
@property(nonatomic, copy) NSString *_Nullable appVersion;

/**
 * Override the application name.
 *
 */
@property(nonatomic, copy) NSString *_Nullable appName;

/**
 * Override the application locale.
 *
 */
@property(nonatomic, copy) NSString *_Nullable appLocale;

/**
 * User identifier.
 * The identifier needs to start with c: or i: or d: or w: prefixes.
 *
 */
@property(nonatomic, copy) NSString *_Nullable userId;

/**
 * Set a string event property to be attached to events tracked by this transmission target and its child transmission targets.
 *
 * @param propertyValue Property value.
 * @param propertyKey Property key.
 *
 * @discussion A property set in a child transmission target overrides a property with the same key inherited from its parents. Also, the
 * properties passed to the `trackEvent:withProperties:` or `trackEvent:withTypedProperties:` override any property with the same key from
 * the transmission target itself or its parents.
 */
- (void)setEventPropertyString:(NSString *)propertyValue forKey:(NSString *)propertyKey NS_SWIFT_NAME(setEventProperty(_:forKey:));

/**
 * Set a double event property to be attached to events tracked by this transmission target and its child transmission targets.
 *
 * @param propertyValue Property value. Must be finite (`NAN` and `INFINITY` not allowed).
 * @param propertyKey Property key.
 *
 * @discussion A property set in a child transmission target overrides a property with the same key inherited from its parents. Also, the
 * properties passed to the `trackEvent:withProperties:` or `trackEvent:withTypedProperties:` override any property with the same key from
 * the transmission target itself or its parents.
 */
- (void)setEventPropertyDouble:(double)propertyValue forKey:(NSString *)propertyKey NS_SWIFT_NAME(setEventProperty(_:forKey:));

/**
 * Set a 64-bit integer event property to be attached to events tracked by this transmission target and its child transmission targets.
 *
 * @param propertyValue Property value.
 * @param propertyKey Property key.
 *
 * @discussion A property set in a child transmission target overrides a property with the same key inherited from its parents. Also, the
 * properties passed to the `trackEvent:withProperties:` or `trackEvent:withTypedProperties:` override any property with the same key from
 * the transmission target itself or its parents.
 */
- (void)setEventPropertyInt64:(int64_t)propertyValue forKey:(NSString *)propertyKey NS_SWIFT_NAME(setEventProperty(_:forKey:));

/**
 * Set a boolean event property to be attached to events tracked by this transmission target and its child transmission targets.
 *
 * @param propertyValue Property value.
 * @param propertyKey Property key.
 *
 * @discussion A property set in a child transmission target overrides a property with the same key inherited from its parents. Also, the
 * properties passed to the `trackEvent:withProperties:` or `trackEvent:withTypedProperties:` override any property with the same key from
 * the transmission target itself or its parents.
 */
- (void)setEventPropertyBool:(BOOL)propertyValue forKey:(NSString *)propertyKey NS_SWIFT_NAME(setEventProperty(_:forKey:));

/**
 * Set a date event property to be attached to events tracked by this transmission target and its child transmission targets.
 *
 * @param propertyValue Property value.
 * @param propertyKey Property key.
 *
 * @discussion A property set in a child transmission target overrides a property with the same key inherited from its parents. Also, the
 * properties passed to the `trackEvent:withProperties:` or `trackEvent:withTypedProperties:` override any property with the same key from
 * the transmission target itself or its parents.
 */
- (void)setEventPropertyDate:(NSDate *)propertyValue forKey:(NSString *)propertyKey NS_SWIFT_NAME(setEventProperty(_:forKey:));

/**
 * Remove an event property from this transmission target.
 *
 * @param propertyKey Property key.
 *
 * @discussion This won't remove properties with the same name declared in other nested transmission targets.
 */
- (void)removeEventPropertyForKey:(NSString *)propertyKey NS_SWIFT_NAME(removeEventProperty(forKey:));

/**
 * Once called, the App Center SDK will automatically add UIDevice.identifierForVendor to common schema logs.
 *
 * @discussion Call this before starting the SDK. This setting is not persisted, so you need to call this when setting up the SDK every
 * time. If you want to provide a way for users to opt-in or opt-out of this setting, it is on you to persist their choice and configure the
 * App Center SDK accordingly.
 */
- (void)collectDeviceId;

NS_ASSUME_NONNULL_END

@end
