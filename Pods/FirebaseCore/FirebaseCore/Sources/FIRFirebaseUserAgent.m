/*
 * Copyright 2020 Google LLC
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

#import "FirebaseCore/Sources/FIRFirebaseUserAgent.h"

#import <GoogleUtilities/GULAppEnvironmentUtil.h>

@interface FIRFirebaseUserAgent ()

@property(nonatomic, readonly) NSMutableDictionary<NSString *, NSString *> *valuesByComponent;
@property(nonatomic, readonly) NSDictionary<NSString *, NSString *> *environmentComponents;
@property(nonatomic, readonly) NSString *firebaseUserAgent;

@end

@implementation FIRFirebaseUserAgent

@synthesize firebaseUserAgent = _firebaseUserAgent;
@synthesize environmentComponents = _environmentComponents;

- (instancetype)init {
  self = [super init];
  if (self) {
    _valuesByComponent = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (NSString *)firebaseUserAgent {
  @synchronized(self) {
    if (_firebaseUserAgent == nil) {
      NSMutableDictionary<NSString *, NSString *> *allComponents =
          [self.valuesByComponent mutableCopy];
      [allComponents setValuesForKeysWithDictionary:self.environmentComponents];

      __block NSMutableArray<NSString *> *components =
          [[NSMutableArray<NSString *> alloc] initWithCapacity:self.valuesByComponent.count];
      [allComponents enumerateKeysAndObjectsUsingBlock:^(
                         NSString *_Nonnull name, NSString *_Nonnull value, BOOL *_Nonnull stop) {
        [components addObject:[NSString stringWithFormat:@"%@/%@", name, value]];
      }];
      [components sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
      _firebaseUserAgent = [components componentsJoinedByString:@" "];
    }
    return _firebaseUserAgent;
  }
}

- (void)setValue:(nullable NSString *)value forComponent:(NSString *)componentName {
  @synchronized(self) {
    self.valuesByComponent[componentName] = value;
    // Reset cached user agent string.
    _firebaseUserAgent = nil;
  }
}

- (void)reset {
  @synchronized(self) {
    // Reset components.
    _valuesByComponent = [[[self class] environmentComponents] mutableCopy];
    // Reset cached user agent string.
    _firebaseUserAgent = nil;
  }
}

#pragma mark - Environment components

- (NSDictionary<NSString *, NSString *> *)environmentComponents {
  if (_environmentComponents == nil) {
    _environmentComponents = [[self class] environmentComponents];
  }
  return _environmentComponents;
}

+ (NSDictionary<NSString *, NSString *> *)environmentComponents {
  NSMutableDictionary<NSString *, NSString *> *components = [NSMutableDictionary dictionary];

  NSDictionary<NSString *, id> *info = [[NSBundle mainBundle] infoDictionary];
  NSString *xcodeVersion = info[@"DTXcodeBuild"];
  NSString *appleSdkVersion = info[@"DTSDKBuild"];
  NSString *isFromAppstoreFlagValue = [GULAppEnvironmentUtil isFromAppStore] ? @"true" : @"false";

  components[@"apple-platform"] = [GULAppEnvironmentUtil applePlatform];
  components[@"apple-sdk"] = appleSdkVersion;
  components[@"appstore"] = isFromAppstoreFlagValue;
  components[@"deploy"] = [GULAppEnvironmentUtil deploymentType];
  components[@"device"] = [GULAppEnvironmentUtil deviceModel];
  components[@"os-version"] = [GULAppEnvironmentUtil systemVersion];
  components[@"xcode"] = xcodeVersion;

  return [components copy];
}

@end
