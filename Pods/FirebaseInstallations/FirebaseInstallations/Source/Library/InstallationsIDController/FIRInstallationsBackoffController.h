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

#import <Foundation/Foundation.h>

#import "FirebaseInstallations/Source/Library/InstallationsIDController/FIRCurrentDateProvider.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FIRInstallationsBackoffEvent) {
  FIRInstallationsBackoffEventSuccess,
  FIRInstallationsBackoffEventRecoverableFailure,
  FIRInstallationsBackoffEventUnrecoverableFailure
};

/** The protocol defines API for a class that encapsulates backoff logic that prevents the SDK from
 * sending unnecessary server requests. See API docs for the methods for more details. */

@protocol FIRInstallationsBackoffControllerProtocol <NSObject>

/** The client must call the method each time a protected server request succeeds of fails. It will
 * affect the `isNextRequestAllowed` method result for the current time, e.g. when 3 recoverable
 * errors were logged in a row, then `isNextRequestAllowed` will return `YES` only in `pow(2, 3)`
 * seconds. */
- (void)registerEvent:(FIRInstallationsBackoffEvent)event;

/** Returns if sending a next protected is recommended based on the time and the sequence of logged
 * events and the current time. See also `registerEvent:`. */
- (BOOL)isNextRequestAllowed;

@end

/** An implementation of `FIRInstallationsBackoffControllerProtocol` with exponential backoff for
 * recoverable errors and constant backoff for recoverable errors. */
@interface FIRInstallationsBackoffController : NSObject <FIRInstallationsBackoffControllerProtocol>

- (instancetype)initWithCurrentDateProvider:(FIRCurrentDateProvider)currentDateProvider;

@end

NS_ASSUME_NONNULL_END
