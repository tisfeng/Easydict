/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

#import "GULHeartbeatDateStorable.h"

NS_ASSUME_NONNULL_BEGIN

/// Stores either a date or a dictionary to a specified file.
@interface GULHeartbeatDateStorageUserDefaults : NSObject <GULHeartbeatDateStorable>

/**
 * Default initializer. tvOS can only write to the cache directory and
 * there are no guarantees that the directory will persist. User defaults will
 * be retained, so that should be used instead.
 * @param defaults User defaults instance to store the heartbeat information.
 * @param key The key to be used with the user defaults instance.
 */
- (instancetype)initWithDefaults:(NSUserDefaults *)defaults key:(NSString *)key;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Reads the date from the specified file for the given tag.
 * @return Returns date if exists, otherwise `nil`.
 */
- (nullable NSDate *)heartbeatDateForTag:(NSString *)tag;

/**
 * Saves the date for the specified tag in the specified file.
 * @return YES on success, NO otherwise.
 */
- (BOOL)setHearbeatDate:(NSDate *)date forTag:(NSString *)tag;

@end

NS_ASSUME_NONNULL_END
