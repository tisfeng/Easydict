//
//  RACSignal.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 3/1/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RACAnnotations.h"
#import "RACStream.h"

@class RACDisposable;
@class RACScheduler;
@class RACSubject;
@class RACTuple;
@class RACTwoTuple<__covariant First, __covariant Second>;
@protocol RACSubscriber;

NS_ASSUME_NONNULL_BEGIN

@interface RACSignal<__covariant ValueType> : RACStream

/// Creates a new signal. This is the preferred way to create a new signal
/// operation or behavior.
///
/// Events can be sent to new subscribers immediately in the `didSubscribe`
/// block, but the subscriber will not be able to dispose of the signal until
/// a RACDisposable is returned from `didSubscribe`. In the case of infinite
/// signals, this won't _ever_ happen if events are sent immediately.
///
/// To ensure that the signal is disposable, events can be scheduled on the
/// +[RACScheduler currentScheduler] (so that they're deferred, not sent
/// immediately), or they can be sent in the background. The RACDisposable
/// returned by the `didSubscribe` block should cancel any such scheduling or
/// asynchronous work.
///
/// didSubscribe - Called when the signal is subscribed to. The new subscriber is
///                passed in. You can then manually control the <RACSubscriber> by
///                sending it -sendNext:, -sendError:, and -sendCompleted,
///                as defined by the operation you're implementing. This block
///                should return a RACDisposable which cancels any ongoing work
///                triggered by the subscription, and cleans up any resources or
///                disposables created as part of it. When the disposable is
///                disposed of, the signal must not send any more events to the
///                `subscriber`. If no cleanup is necessary, return nil.
///
/// **Note:** The `didSubscribe` block is called every time a new subscriber
/// subscribes. Any side effects within the block will thus execute once for each
/// subscription, not necessarily on one thread, and possibly even
/// simultaneously!
+ (RACSignal<ValueType> *)createSignal:(RACDisposable * _Nullable (^)(id<RACSubscriber> subscriber))didSubscribe RAC_WARN_UNUSED_RESULT;

/// Returns a signal that immediately sends the given error.
+ (RACSignal<ValueType> *)error:(nullable NSError *)error RAC_WARN_UNUSED_RESULT;

/// Returns a signal that never completes.
+ (RACSignal<ValueType> *)never RAC_WARN_UNUSED_RESULT;

/// Immediately schedules the given block on the given scheduler. The block is
/// given a subscriber to which it can send events.
///
/// scheduler - The scheduler on which `block` will be scheduled and results
///             delivered. Cannot be nil.
/// block     - The block to invoke. Cannot be NULL.
///
/// Returns a signal which will send all events sent on the subscriber given to
/// `block`. All events will be sent on `scheduler` and it will replay any missed
/// events to new subscribers.
+ (RACSignal<ValueType> *)startEagerlyWithScheduler:(RACScheduler *)scheduler block:(void (^)(id<RACSubscriber> subscriber))block;

/// Invokes the given block only on the first subscription. The block is given a
/// subscriber to which it can send events.
///
/// Note that disposing of the subscription to the returned signal will *not*
/// dispose of the underlying subscription. If you need that behavior, see
/// -[RACMulticastConnection autoconnect]. The underlying subscription will never
/// be disposed of. Because of this, `block` should never return an infinite
/// signal since there would be no way of ending it.
///
/// scheduler - The scheduler on which the block should be scheduled. Note that 
///             if given +[RACScheduler immediateScheduler], the block will be
///             invoked synchronously on the first subscription. Cannot be nil.
/// block     - The block to invoke on the first subscription. Cannot be NULL.
///
/// Returns a signal which will pass through the events sent to the subscriber
/// given to `block` and replay any missed events to new subscribers.
+ (RACSignal<ValueType> *)startLazilyWithScheduler:(RACScheduler *)scheduler block:(void (^)(id<RACSubscriber> subscriber))block RAC_WARN_UNUSED_RESULT;

@end

@interface RACSignal<__covariant ValueType> (RACStream)

/// Returns a signal that immediately sends the given value and then completes.
+ (RACSignal<ValueType> *)return:(nullable ValueType)value RAC_WARN_UNUSED_RESULT;

/// Returns a signal that immediately completes.
+ (RACSignal<ValueType> *)empty RAC_WARN_UNUSED_RESULT;

/// A block which accepts a value from a RACSignal and returns a new signal.
///
/// Setting `stop` to `YES` will cause the bind to terminate after the returned
/// value. Returning `nil` will result in immediate termination.
typedef RACSignal * _Nullable (^RACSignalBindBlock)(ValueType _Nullable value, BOOL *stop);

/// Lazily binds a block to the values in the receiver.
///
/// This should only be used if you need to terminate the bind early, or close
/// over some state. -flattenMap: is more appropriate for all other cases.
///
/// block - A block returning a RACSignalBindBlock. This block will be invoked
///         each time the bound signal is re-evaluated. This block must not be
///         nil or return nil.
///
/// Returns a new signal which represents the combined result of all lazy
/// applications of `block`.
- (RACSignal *)bind:(RACSignalBindBlock (^)(void))block RAC_WARN_UNUSED_RESULT;

/// Subscribes to `signal` when the source signal completes.
- (RACSignal *)concat:(RACSignal *)signal RAC_WARN_UNUSED_RESULT;

/// Zips the values in the receiver with those of the given signal to create
/// RACTuples.
///
/// The first `next` of each signal will be combined, then the second `next`,
/// and so forth, until either signal completes or errors.
///
/// signal - The signal to zip with. This must not be `nil`.
///
/// Returns a new signal of RACTuples, representing the combined values of the
/// two signals. Any error from one of the original signals will be forwarded on
/// the returned signal.
- (RACSignal<RACTwoTuple<ValueType, id> *> *)zipWith:(RACSignal *)signal RAC_WARN_UNUSED_RESULT;

@end

/// Redeclarations of operations built on the RACStream primitives with more
/// precise ValueType information.
///
/// In cases where the ValueType of the result of the operation is not able to
/// be inferred, the ValueType is erased in the result.
///
/// In cases where instancetype is a valid return type, the operation is not
/// redeclared here.
@interface RACSignal<__covariant ValueType> (RACStreamOperations)

/// Maps `block` across the values in the receiver and flattens the result.
///
/// Note that operators applied _after_ -flattenMap: behave differently from
/// operators _within_ -flattenMap:. See the Examples section below.
///
/// This corresponds to the `SelectMany` method in Rx.
///
/// block - A block which accepts the values in the receiver and returns a new
///         instance of the receiver's class. Returning `nil` from this block is
///         equivalent to returning an empty signal.
///
/// Examples
///
///   [signal flattenMap:^(id x) {
///       // Logs each time a returned signal completes.
///       return [[RACSignal return:x] logCompleted];
///   }];
///
///   [[signal
///       flattenMap:^(id x) {
///           return [RACSignal return:x];
///       }]
///       // Logs only once, when all of the signals complete.
///       logCompleted];
///
/// Returns a new signal which represents the combined signals resulting from
/// mapping `block`.
- (RACSignal *)flattenMap:(__kindof RACSignal * _Nullable (^)(ValueType _Nullable value))block RAC_WARN_UNUSED_RESULT;

/// Flattens a signal of signals.
///
/// This corresponds to the `Merge` method in Rx.
///
/// Returns a signal consisting of the combined signals obtained from the
/// receiver.
- (RACSignal *)flatten RAC_WARN_UNUSED_RESULT;

/// Maps `block` across the values in the receiver.
///
/// This corresponds to the `Select` method in Rx.
///
/// Returns a new signal with the mapped values.
- (RACSignal *)map:(id _Nullable (^)(ValueType _Nullable value))block RAC_WARN_UNUSED_RESULT;

/// Replaces each value in the receiver with the given object.
///
/// Returns a new signal which includes the given object once for each value in
/// the receiver.
- (RACSignal *)mapReplace:(nullable id)object RAC_WARN_UNUSED_RESULT;

/// Filters out values in the receiver that don't pass the given test.
///
/// This corresponds to the `Where` method in Rx.
///
/// Returns a new signal with only those values that passed.
- (RACSignal<ValueType> *)filter:(BOOL (^)(ValueType _Nullable value))block RAC_WARN_UNUSED_RESULT;

/// Filters out values in the receiver that equal (via -isEqual:) the provided
/// value.
///
/// value - The value can be `nil`, in which case it ignores `nil` values.
///
/// Returns a new signal containing only the values which did not compare equal
/// to `value`.
- (RACSignal<ValueType> *)ignore:(nullable ValueType)value RAC_WARN_UNUSED_RESULT;

/// Unpacks each RACTuple in the receiver and maps the values to a new value.
///
/// reduceBlock - The block which reduces each RACTuple's values into one value.
///               It must take as many arguments as the number of tuple elements
///               to process. Each argument will be an object argument. The
///               return value must be an object. This argument cannot be nil.
///
/// Returns a new signal of reduced tuple values.
- (RACSignal *)reduceEach:(RACReduceBlock)reduceBlock RAC_WARN_UNUSED_RESULT;

/// Returns a signal consisting of `value`, followed by the values in the
/// receiver.
- (RACSignal<ValueType> *)startWith:(nullable ValueType)value RAC_WARN_UNUSED_RESULT;

/// Skips the first `skipCount` values in the receiver.
///
/// Returns the receiver after skipping the first `skipCount` values. If
/// `skipCount` is greater than the number of values in the signal, an empty
/// signal is returned.
- (RACSignal<ValueType> *)skip:(NSUInteger)skipCount RAC_WARN_UNUSED_RESULT;

/// Returns a signal of the first `count` values in the receiver. If `count` is
/// greater than or equal to the number of values in the signal, a signal
/// equivalent to the receiver is returned.
- (RACSignal<ValueType> *)take:(NSUInteger)count RAC_WARN_UNUSED_RESULT;

/// Zips the values in the given signals to create RACTuples.
///
/// The first value of each signals will be combined, then the second value, and
/// so forth, until at least one of the signals is exhausted.
///
/// signals - The signals to combine. If this collection is empty, the returned
///           signal will be empty.
///
/// Returns a new signal containing RACTuples of the zipped values from the
/// signals.
+ (RACSignal<RACTuple *> *)zip:(id<NSFastEnumeration>)signals RAC_WARN_UNUSED_RESULT;

/// Zips signals using +zip:, then reduces the resulting tuples into a single
/// value using -reduceEach:
///
/// signals     - The signals to combine. If this collection is empty, the
///               returned signal will be empty.
/// reduceBlock - The block which reduces the values from all the signals
///               into one value. It must take as many arguments as the
///               number of signals given. Each argument will be an object
///               argument. The return value must be an object. This argument
///               must not be nil.
///
/// Example:
///
///   [RACSignal zip:@[ stringSignal, intSignal ]
///       reduce:^(NSString *string, NSNumber *number) {
///           return [NSString stringWithFormat:@"%@: %@", string, number];
///       }];
///
/// Returns a new signal containing the results from each invocation of
/// `reduceBlock`.
+ (RACSignal<ValueType> *)zip:(id<NSFastEnumeration>)signals reduce:(RACGenericReduceBlock)reduceBlock RAC_WARN_UNUSED_RESULT;

/// Returns a signal obtained by concatenating `signals` in order.
+ (RACSignal<ValueType> *)concat:(id<NSFastEnumeration>)signals RAC_WARN_UNUSED_RESULT;

/// Combines values in the receiver from left to right using the given block.
///
/// The algorithm proceeds as follows:
///
///  1. `startingValue` is passed into the block as the `running` value, and the
///  first element of the receiver is passed into the block as the `next` value.
///  2. The result of the invocation is added to the returned signal.
///  3. The result of the invocation (`running`) and the next element of the
///  receiver (`next`) is passed into `block`.
///  4. Steps 2 and 3 are repeated until all values have been processed.
///
/// startingValue - The value to be combined with the first element of the
///                 receiver. This value may be `nil`.
/// reduceBlock   - The block that describes how to combine values of the
///                 receiver. If the receiver is empty, this block will never be
///                 invoked. Cannot be nil.
///
/// Examples
///
///      RACSequence *numbers = @[ @1, @2, @3, @4 ].rac_sequence;
///
///      // Contains 1, 3, 6, 10
///      RACSequence *sums = [numbers scanWithStart:@0 reduce:^(NSNumber *sum, NSNumber *next) {
///          return @(sum.integerValue + next.integerValue);
///      }];
///
/// Returns a new signal that consists of each application of `reduceBlock`. If
/// the receiver is empty, an empty signal is returned.
- (RACSignal *)scanWithStart:(nullable id)startingValue reduce:(id _Nullable (^)(id _Nullable running, ValueType _Nullable next))reduceBlock RAC_WARN_UNUSED_RESULT;

/// Combines values in the receiver from left to right using the given block
/// which also takes zero-based index of the values.
///
/// startingValue - The value to be combined with the first element of the
///                 receiver. This value may be `nil`.
/// reduceBlock   - The block that describes how to combine values of the
///                 receiver. This block takes zero-based index value as the last
///                 parameter. If the receiver is empty, this block will never
///                 be invoked. Cannot be nil.
///
/// Returns a new signal that consists of each application of `reduceBlock`. If
/// the receiver is empty, an empty signal is returned.
- (RACSignal *)scanWithStart:(nullable id)startingValue reduceWithIndex:(id _Nullable (^)(id _Nullable running, ValueType _Nullable next, NSUInteger index))reduceBlock RAC_WARN_UNUSED_RESULT;

/// Combines each previous and current value into one object.
///
/// This method is similar to -scanWithStart:reduce:, but only ever operates on
/// the previous and current values (instead of the whole signal), and does not
/// pass the return value of `reduceBlock` into the next invocation of it.
///
/// start       - The value passed into `reduceBlock` as `previous` for the
///               first value.
/// reduceBlock - The block that combines the previous value and the current
///               value to create the reduced value. Cannot be nil.
///
/// Examples
///
///      RACSignal<NSNumber *> *numbers = [@[ @1, @2, @3, @4 ].rac_sequence
///          signalWithScheduler:RACScheduler.immediateScheduler];
///
///      // Contains 1, 3, 5, 7
///      RACSignal *sums = [numbers combinePreviousWithStart:@0 reduce:^(NSNumber *previous, NSNumber *next) {
///          return @(previous.integerValue + next.integerValue);
///      }];
///
/// Returns a new signal consisting of the return values from each application of
/// `reduceBlock`.
- (RACSignal *)combinePreviousWithStart:(nullable ValueType)start reduce:(id _Nullable (^)(ValueType _Nullable previous, ValueType _Nullable current))reduceBlock RAC_WARN_UNUSED_RESULT;

/// Takes values until the given block returns `YES`.
///
/// Returns a signal of the initial values in the receiver that fail `predicate`.
/// If `predicate` never returns `YES`, a signal equivalent to the receiver is
/// returned.
- (RACSignal<ValueType> *)takeUntilBlock:(BOOL (^)(ValueType _Nullable x))predicate RAC_WARN_UNUSED_RESULT;

/// Takes values until the given block returns `NO`.
///
/// Returns a signal of the initial values in the receiver that pass `predicate`.
/// If `predicate` never returns `NO`, a signal equivalent to the receiver is
/// returned.
- (RACSignal<ValueType> *)takeWhileBlock:(BOOL (^)(ValueType _Nullable x))predicate RAC_WARN_UNUSED_RESULT;

/// Skips values until the given block returns `YES`.
///
/// Returns a signal containing the values of the receiver that follow any
/// initial values failing `predicate`. If `predicate` never returns `YES`,
/// an empty signal is returned.
- (RACSignal<ValueType> *)skipUntilBlock:(BOOL (^)(ValueType _Nullable x))predicate RAC_WARN_UNUSED_RESULT;

/// Skips values until the given block returns `NO`.
///
/// Returns a signal containing the values of the receiver that follow any
/// initial values passing `predicate`. If `predicate` never returns `NO`, an
/// empty signal is returned.
- (RACSignal<ValueType> *)skipWhileBlock:(BOOL (^)(ValueType _Nullable x))predicate RAC_WARN_UNUSED_RESULT;

/// Returns a signal of values for which -isEqual: returns NO when compared to the
/// previous value.
- (RACSignal<ValueType> *)distinctUntilChanged RAC_WARN_UNUSED_RESULT;

@end

@interface RACSignal<__covariant ValueType> (Subscription)

/// Subscribes `subscriber` to changes on the receiver. The receiver defines which
/// events it actually sends and in what situations the events are sent.
///
/// Subscription will always happen on a valid RACScheduler. If the
/// +[RACScheduler currentScheduler] cannot be determined at the time of
/// subscription (e.g., because the calling code is running on a GCD queue or
/// NSOperationQueue), subscription will occur on a private background scheduler.
/// On the main thread, subscriptions will always occur immediately, with a
/// +[RACScheduler currentScheduler] of +[RACScheduler mainThreadScheduler].
///
/// This method must be overridden by any subclasses.
///
/// Returns nil or a disposable. You can call -[RACDisposable dispose] if you
/// need to end your subscription before it would "naturally" end, either by
/// completing or erroring. Once the disposable has been disposed, the subscriber
/// won't receive any more events from the subscription.
- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber;

/// Convenience method to subscribe to the `next` event.
///
/// This corresponds to `IObserver<T>.OnNext` in Rx.
- (RACDisposable *)subscribeNext:(void (^)(ValueType _Nullable x))nextBlock;

/// Convenience method to subscribe to the `next` and `completed` events.
- (RACDisposable *)subscribeNext:(void (^)(ValueType _Nullable x))nextBlock completed:(void (^)(void))completedBlock;

/// Convenience method to subscribe to the `next`, `completed`, and `error` events.
- (RACDisposable *)subscribeNext:(void (^)(ValueType _Nullable x))nextBlock error:(void (^)(NSError * _Nullable error))errorBlock completed:(void (^)(void))completedBlock;

/// Convenience method to subscribe to `error` events.
///
/// This corresponds to the `IObserver<T>.OnError` in Rx.
- (RACDisposable *)subscribeError:(void (^)(NSError * _Nullable error))errorBlock;

/// Convenience method to subscribe to `completed` events.
///
/// This corresponds to the `IObserver<T>.OnCompleted` in Rx.
- (RACDisposable *)subscribeCompleted:(void (^)(void))completedBlock;

/// Convenience method to subscribe to `next` and `error` events.
- (RACDisposable *)subscribeNext:(void (^)(ValueType _Nullable x))nextBlock error:(void (^)(NSError * _Nullable error))errorBlock;

/// Convenience method to subscribe to `error` and `completed` events.
- (RACDisposable *)subscribeError:(void (^)(NSError * _Nullable error))errorBlock completed:(void (^)(void))completedBlock;

@end

/// Additional methods to assist with debugging.
@interface RACSignal<__covariant ValueType> (Debugging)

/// Logs all events that the receiver sends.
- (RACSignal<ValueType> *)logAll RAC_WARN_UNUSED_RESULT;

/// Logs each `next` that the receiver sends.
- (RACSignal<ValueType> *)logNext RAC_WARN_UNUSED_RESULT;

/// Logs any error that the receiver sends.
- (RACSignal<ValueType> *)logError RAC_WARN_UNUSED_RESULT;

/// Logs any `completed` event that the receiver sends.
- (RACSignal<ValueType> *)logCompleted RAC_WARN_UNUSED_RESULT;

@end

/// Additional methods to assist with unit testing.
///
/// **These methods should never ship in production code.**
@interface RACSignal<__covariant ValueType> (Testing)

/// Spins the main run loop for a short while, waiting for the receiver to send a `next`
/// or the provided timeout to elapse.
///
/// **Because this method executes the run loop recursively, it should only be used
/// on the main thread, and only from a unit test.**
///
/// defaultValue - Returned if the receiver completes or errors before sending
///                a `next`, or if the method times out. This argument may be
///                nil.
/// success      - If not NULL, set to whether the receiver completed
///                successfully.
/// error        - If not NULL, set to any error that occurred.
///
/// Returns the first value received, or `defaultValue` if no value is received
/// before the signal finishes or the method times out.
- (nullable ValueType)asynchronousFirstOrDefault:(nullable ValueType)defaultValue success:(nullable BOOL *)success error:(NSError * _Nullable * _Nullable)error timeout:(NSTimeInterval)timeout;

/// Spins the main run loop for a short while, waiting for the receiver to send a `next`.
///
/// **Because this method executes the run loop recursively, it should only be used
/// on the main thread, and only from a unit test.**
///
/// defaultValue - Returned if the receiver completes or errors before sending
///                a `next`, or if the method times out. This argument may be
///                nil.
/// success      - If not NULL, set to whether the receiver completed
///                successfully.
/// error        - If not NULL, set to any error that occurred.
///
/// Returns the first value received, or `defaultValue` if no value is received
/// before the signal finishes or the method times out.
- (nullable ValueType)asynchronousFirstOrDefault:(nullable ValueType)defaultValue success:(nullable BOOL *)success error:(NSError * _Nullable * _Nullable)error;

/// Spins the main run loop for a short while, waiting for the receiver to complete.
/// or the provided timeout to elapse.
///
/// **Because this method executes the run loop recursively, it should only be used
/// on the main thread, and only from a unit test.**
///
/// error - If not NULL, set to any error that occurs.
///
/// Returns whether the signal completed successfully before timing out. If NO,
/// `error` will be set to any error that occurred.
- (BOOL)asynchronouslyWaitUntilCompleted:(NSError * _Nullable * _Nullable)error timeout:(NSTimeInterval)timeout;

/// Spins the main run loop for a short while, waiting for the receiver to complete
///
/// **Because this method executes the run loop recursively, it should only be used
/// on the main thread, and only from a unit test.**
///
/// error - If not NULL, set to any error that occurs.
///
/// Returns whether the signal completed successfully before timing out. If NO,
/// `error` will be set to any error that occurred.
- (BOOL)asynchronouslyWaitUntilCompleted:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
