//
//  RACEvent.h
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2013-01-07.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Describes the type of a RACEvent.
///
/// RACEventTypeCompleted - A `completed` event.
/// RACEventTypeError     - An `error` event.
/// RACEventTypeNext      - A `next` event.
typedef NS_ENUM(NSUInteger, RACEventType) {
    RACEventTypeCompleted,
    RACEventTypeError,
    RACEventTypeNext
};

/// Represents an event sent by a RACSignal.
///
/// This corresponds to the `Notification` class in Rx.
@interface RACEvent<__covariant ValueType> : NSObject <NSCopying>

/// Returns a singleton RACEvent representing the `completed` event.
+ (RACEvent<ValueType> *)completedEvent;

/// Returns a new event of type RACEventTypeError, containing the given error.
+ (RACEvent<ValueType> *)eventWithError:(nullable NSError *)error;

/// Returns a new event of type RACEventTypeNext, containing the given value.
+ (RACEvent<ValueType> *)eventWithValue:(nullable ValueType)value;

/// The type of event represented by the receiver.
@property (nonatomic, assign, readonly) RACEventType eventType;

/// Returns whether the receiver is of type RACEventTypeCompleted or
/// RACEventTypeError.
@property (nonatomic, getter = isFinished, assign, readonly) BOOL finished;

/// The error associated with an event of type RACEventTypeError. This will be
/// nil for all other event types.
@property (nonatomic, strong, readonly, nullable) NSError *error;

/// The value associated with an event of type RACEventTypeNext. This will be
/// nil for all other event types.
@property (nonatomic, strong, readonly, nullable) ValueType value;

@end

NS_ASSUME_NONNULL_END
