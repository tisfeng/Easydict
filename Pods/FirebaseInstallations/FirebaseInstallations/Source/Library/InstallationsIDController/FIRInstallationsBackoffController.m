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

#import "FirebaseInstallations/Source/Library/InstallationsIDController/FIRInstallationsBackoffController.h"

static const NSTimeInterval k24Hours = 24 * 60 * 60;
static const NSTimeInterval k30Minutes = 30 * 60;

/** The class represents `FIRInstallationsBackoffController` sate required to calculate next allowed
 request time. The properties of the class are intentionally immutable because changing them
 separately leads to an inconsistent state. */
@interface FIRInstallationsBackoffEventData : NSObject

@property(nonatomic, readonly) FIRInstallationsBackoffEvent eventType;
@property(nonatomic, readonly) NSDate *lastEventDate;
@property(nonatomic, readonly) NSInteger eventCount;

@property(nonatomic, readonly) NSTimeInterval backoffTimeInterval;

@end

@implementation FIRInstallationsBackoffEventData

- (instancetype)initWithEvent:(FIRInstallationsBackoffEvent)eventType
                lastEventDate:(NSDate *)lastEventDate
                   eventCount:(NSInteger)eventCount {
  self = [super init];
  if (self) {
    _eventType = eventType;
    _lastEventDate = lastEventDate;
    _eventCount = eventCount;

    _backoffTimeInterval = [[self class] backoffTimeIntervalWithEvent:eventType
                                                           eventCount:eventCount];
  }
  return self;
}

+ (NSTimeInterval)backoffTimeIntervalWithEvent:(FIRInstallationsBackoffEvent)eventType
                                    eventCount:(NSInteger)eventCount {
  switch (eventType) {
    case FIRInstallationsBackoffEventSuccess:
      return 0;
      break;

    case FIRInstallationsBackoffEventRecoverableFailure:
      return [self recoverableErrorBackoffTimeForAttemptNumber:eventCount];
      break;

    case FIRInstallationsBackoffEventUnrecoverableFailure:
      return k24Hours;
      break;
  }
}

+ (NSTimeInterval)recoverableErrorBackoffTimeForAttemptNumber:(NSInteger)attemptNumber {
  NSTimeInterval exponentialInterval = pow(2, attemptNumber) + [self randomMilliseconds];
  return MIN(exponentialInterval, k30Minutes);
}

+ (NSTimeInterval)randomMilliseconds {
  int32_t random_millis = ABS(arc4random() % 1000);
  return (double)random_millis * 0.001;
}

@end

@interface FIRInstallationsBackoffController ()

@property(nonatomic, readonly) FIRCurrentDateProvider currentDateProvider;

@property(nonatomic, nullable) FIRInstallationsBackoffEventData *lastEventData;

@end

@implementation FIRInstallationsBackoffController

- (instancetype)init {
  return [self initWithCurrentDateProvider:FIRRealCurrentDateProvider()];
}

- (instancetype)initWithCurrentDateProvider:(FIRCurrentDateProvider)currentDateProvider {
  self = [super init];
  if (self) {
    _currentDateProvider = [currentDateProvider copy];
  }
  return self;
}

- (BOOL)isNextRequestAllowed {
  @synchronized(self) {
    if (self.lastEventData == nil) {
      return YES;
    }

    NSTimeInterval timeSinceLastEvent =
        [self.currentDateProvider() timeIntervalSinceDate:self.lastEventData.lastEventDate];
    return timeSinceLastEvent >= self.lastEventData.backoffTimeInterval;
  }
}

- (void)registerEvent:(FIRInstallationsBackoffEvent)event {
  @synchronized(self) {
    // Event of the same type as was registered before.
    if (self.lastEventData && self.lastEventData.eventType == event) {
      self.lastEventData = [[FIRInstallationsBackoffEventData alloc]
          initWithEvent:event
          lastEventDate:self.currentDateProvider()
             eventCount:self.lastEventData.eventCount + 1];
    } else {  // A different event.
      self.lastEventData =
          [[FIRInstallationsBackoffEventData alloc] initWithEvent:event
                                                    lastEventDate:self.currentDateProvider()
                                                       eventCount:1];
    }
  }
}

@end
