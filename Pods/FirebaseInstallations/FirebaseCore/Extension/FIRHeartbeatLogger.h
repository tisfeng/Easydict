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

NS_ASSUME_NONNULL_BEGIN

#ifndef FIREBASE_BUILD_CMAKE
@class FIRHeartbeatsPayload;
#endif  // FIREBASE_BUILD_CMAKE

/// Enum representing different daily heartbeat codes.
/// This enum is only used by clients using platform logging V1. This is because
/// the V1 payload only supports a single daily heartbeat.
typedef NS_ENUM(NSInteger, FIRDailyHeartbeatCode) {
  /// Represents the absence of a daily heartbeat.
  FIRDailyHeartbeatCodeNone = 0,
  /// Represents the presence of a daily heartbeat.
  FIRDailyHeartbeatCodeSome = 2,
};

@protocol FIRHeartbeatLoggerProtocol <NSObject>

/// Asynchronously logs a heartbeat.
- (void)log;

#ifndef FIREBASE_BUILD_CMAKE
/// Flushes heartbeats from storage into a structured payload of heartbeats.
- (FIRHeartbeatsPayload *)flushHeartbeatsIntoPayload;
#endif  // FIREBASE_BUILD_CMAKE

/// Gets the heartbeat code for today.
- (FIRDailyHeartbeatCode)heartbeatCodeForToday;

@end

#ifndef FIREBASE_BUILD_CMAKE
/// Returns a nullable string header value from a given heartbeats payload.
///
/// This API returns `nil` when the given heartbeats payload is considered empty.
///
/// @param heartbeatsPayload The heartbeats payload.
NSString *_Nullable FIRHeaderValueFromHeartbeatsPayload(FIRHeartbeatsPayload *heartbeatsPayload);
#endif  // FIREBASE_BUILD_CMAKE

/// A thread safe, synchronized object that logs and flushes platform logging info.
@interface FIRHeartbeatLogger : NSObject <FIRHeartbeatLoggerProtocol>

/// Designated initializer.
///
/// @param appID The app ID that this heartbeat logger corresponds to.
- (instancetype)initWithAppID:(NSString *)appID;

/// Asynchronously logs a new heartbeat corresponding to the Firebase User Agent, if needed.
///
/// @note This API is thread-safe.
- (void)log;

#ifndef FIREBASE_BUILD_CMAKE
/// Flushes heartbeats from storage into a structured payload of heartbeats.
///
/// This API is for clients using platform logging V2.
///
/// @note This API is thread-safe.
/// @return A payload of heartbeats.
- (FIRHeartbeatsPayload *)flushHeartbeatsIntoPayload;
#endif  // FIREBASE_BUILD_CMAKE

/// Gets today's corresponding heartbeat code.
///
/// This API is for clients using platform logging V1.
///
/// @note This API is thread-safe.
/// @return Heartbeat code indicating whether or not there is an unsent global heartbeat.
- (FIRDailyHeartbeatCode)heartbeatCodeForToday;

@end

NS_ASSUME_NONNULL_END
