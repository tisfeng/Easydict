// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#ifndef EVENT_PROPERTIES
#define EVENT_PROPERTIES

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains typed event properties.
 */
NS_SWIFT_NAME(EventProperties)
@interface MSACEventProperties : NSObject <NSSecureCoding>

/**
 * Set a string property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (instancetype)setString:(NSString *)value forKey:(NSString *)key NS_SWIFT_NAME(setEventProperty(_:forKey:));

/**
 * Set a double property.
 *
 * @param value Property value. Must be finite (`NAN` and `INFINITY` not allowed).
 * @param key Property key.
 */
- (instancetype)setDouble:(double)value forKey:(NSString *)key NS_SWIFT_NAME(setEventProperty(_:forKey:));

/**
 * Set a 64-bit integer property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (instancetype)setInt64:(int64_t)value forKey:(NSString *)key NS_SWIFT_NAME(setEventProperty(_:forKey:));

/**
 * Set a boolean property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (instancetype)setBool:(BOOL)value forKey:(NSString *)key NS_SWIFT_NAME(setEventProperty(_:forKey:));

/**
 * Set a date property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (instancetype)setDate:(NSDate *)value forKey:(NSString *)key NS_SWIFT_NAME(setEventProperty(_:forKey:));

@end

NS_ASSUME_NONNULL_END

#endif
