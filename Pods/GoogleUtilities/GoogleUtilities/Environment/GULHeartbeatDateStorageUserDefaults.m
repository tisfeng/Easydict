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

#import "GoogleUtilities/Environment/Public/GoogleUtilities/GULHeartbeatDateStorageUserDefaults.h"

@interface GULHeartbeatDateStorageUserDefaults ()

/** The storage to store the date of the last sent heartbeat. */
@property(nonatomic, readonly) NSUserDefaults *userDefaults;

/** The key for user defaults to store heartbeat information. */
@property(nonatomic, readonly) NSString *key;

@end

@implementation GULHeartbeatDateStorageUserDefaults

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults key:(NSString *)key {
  self = [super init];
  if (self) {
    _userDefaults = defaults;
    _key = key;
  }
  return self;
}

- (NSMutableDictionary *)heartbeatDictionaryFromDefaults {
  NSDictionary *heartbeatDict = [self.userDefaults objectForKey:self.key];
  if (heartbeatDict != nil) {
    return [heartbeatDict mutableCopy];
  } else {
    return [NSMutableDictionary dictionary];
  }
}

- (nullable NSDate *)heartbeatDateForTag:(NSString *)tag {
  NSDate *date = nil;
  @synchronized(self.userDefaults) {
    NSMutableDictionary *dict = [self heartbeatDictionaryFromDefaults];
    date = dict[tag];
  }

  return date;
}

- (BOOL)setHearbeatDate:(NSDate *)date forTag:(NSString *)tag {
  @synchronized(self.userDefaults) {
    NSMutableDictionary *dict = [self heartbeatDictionaryFromDefaults];
    dict[tag] = date;
    [self.userDefaults setObject:dict forKey:self.key];
  }
  return true;
}

@end
