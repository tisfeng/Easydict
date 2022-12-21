// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>

#ifndef FIREBASE_BUILD_CMAKE
@import FirebaseCoreInternal;
#endif  // FIREBASE_BUILD_CMAKE

#import "FirebaseCore/Extension/FIRAppInternal.h"
#import "FirebaseCore/Extension/FIRHeartbeatLogger.h"

#ifndef FIREBASE_BUILD_CMAKE
NSString *_Nullable FIRHeaderValueFromHeartbeatsPayload(FIRHeartbeatsPayload *heartbeatsPayload) {
  if ([heartbeatsPayload isEmpty]) {
    return nil;
  }

  return [heartbeatsPayload headerValue];
}
#endif  // FIREBASE_BUILD_CMAKE

@interface FIRHeartbeatLogger ()
#ifndef FIREBASE_BUILD_CMAKE
@property(nonatomic, readonly) FIRHeartbeatController *heartbeatController;
#endif  // FIREBASE_BUILD_CMAKE
@property(copy, readonly) NSString * (^userAgentProvider)(void);
@end

@implementation FIRHeartbeatLogger

- (instancetype)initWithAppID:(NSString *)appID {
  return [self initWithAppID:appID userAgentProvider:[[self class] currentUserAgentProvider]];
}

- (instancetype)initWithAppID:(NSString *)appID
            userAgentProvider:(NSString * (^)(void))userAgentProvider {
  self = [super init];
  if (self) {
#ifndef FIREBASE_BUILD_CMAKE
    _heartbeatController = [[FIRHeartbeatController alloc] initWithId:[appID copy]];
#endif  // FIREBASE_BUILD_CMAKE
    _userAgentProvider = [userAgentProvider copy];
  }
  return self;
}

+ (NSString * (^)(void))currentUserAgentProvider {
  return ^NSString * {
    return [FIRApp firebaseUserAgent];
  };
}

- (void)log {
  NSString *userAgent = _userAgentProvider();
#ifndef FIREBASE_BUILD_CMAKE
  [_heartbeatController log:userAgent];
#endif  // FIREBASE_BUILD_CMAKE
}

#ifndef FIREBASE_BUILD_CMAKE
- (FIRHeartbeatsPayload *)flushHeartbeatsIntoPayload {
  FIRHeartbeatsPayload *payload = [_heartbeatController flush];
  return payload;
}
#endif  // FIREBASE_BUILD_CMAKE

- (FIRDailyHeartbeatCode)heartbeatCodeForToday {
#ifndef FIREBASE_BUILD_CMAKE
  FIRHeartbeatsPayload *todaysHeartbeatPayload = [_heartbeatController flushHeartbeatFromToday];

  if ([todaysHeartbeatPayload isEmpty]) {
    return FIRDailyHeartbeatCodeNone;
  } else {
    return FIRDailyHeartbeatCodeSome;
  }
#else
  return FIRDailyHeartbeatCodeNone;
#endif  // FIREBASE_BUILD_CMAKE
}

@end
