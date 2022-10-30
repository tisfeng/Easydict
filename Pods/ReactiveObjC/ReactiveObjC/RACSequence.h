//
//  RACSequence.h
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2012-10-29.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RACStream.h"

@class RACTuple;
@class RACScheduler;
@class RACSignal<__covariant ValueType>;

NS_ASSUME_NONNULL_BEGIN

/// Represents an immutable sequence of values. Unless otherwise specified, the
/// sequences' values are evaluated lazily on demand. Like Cocoa collections,
/// sequences cannot contain nil.
///
/// Most inherited RACStream methods that accept a block will execute the block
/// _at most_ once for each value that is evaluated in the returned sequence.
/// Side effects are subject to the behavior described in
/// +sequenceWithHeadBlock:tailBlock:.
///
/// Implemented as a class cluster. A minimal implementation for a subclass
/// consists simply of -head and -tail.
@interface RACSequence<__covariant ValueType> : RACStream <NSCoding, NSCopying, NSFastEnumeration>

/// The first object in the sequence, or nil if the sequence is empty.
///
/// Subclasses must provide an implementation of this method.
@property (nonatomic, strong, readonly, nullable) ValueType head;

/// All but the first object in the sequence, or nil if there are no other
/// objects.
///
/// Subclasses must provide an implementation of this method.
@property (nonatomic, strong, readonly, nullable) RACSequence<ValueType> *tail;

/// Evaluates the full sequence to produce an equivalently-sized array.
@property (nonatomic, copy, readonly) NSArray<ValueType> *array;

/// Returns an enumerator of all objects in the sequence.
@property (nonatomic, copy, readonly) NSEnumerator<ValueType> *objectEnumerator;

/// Converts a sequence into an eager sequence.
///
/// An eager sequence fully evaluates all of its values immediately. Sequences
/// derived from an eager sequence will also be eager.
///
/// Returns a new eager sequence, or the receiver if the sequence is already
/// eager.
@property (nonatomic, copy, readonly) RACSequence<ValueType> *eagerSequence;

/// Converts a sequence into a lazy sequence.
///
/// A lazy sequence evaluates its values on demand, as they are accessed.
/// Sequences derived from a lazy sequence will also be lazy.
///
/// Returns a new lazy sequence, or the receiver if the sequence is already lazy.
@property (nonatomic, copy, readonly) RACSequence<ValueType> *lazySequence;

/// Invokes -signalWithScheduler: with a new RACScheduler.
- (RACSignal<ValueType> *)signal;

/// Evaluates the full sequence on the given scheduler.
///
/// Each item is evaluated in its own scheduled block, such that control of the
/// scheduler is yielded between each value.
///
/// Returns a signal which sends the receiver's values on the given scheduler as
/// they're evaluated.
- (RACSignal<ValueType> *)signalWithScheduler:(RACScheduler *)scheduler;

/// Applies a left fold to the sequence.
///
/// This is the same as iterating the sequence along with a provided start value.
/// This uses a constant amount of memory. A left fold is left-associative so in
/// the sequence [1,2,3] the block would applied in the following order:
///  reduce(reduce(reduce(start, 1), 2), 3)
///
/// start  - The starting value for the fold. Used as `accumulator` for the
///          first fold.
/// reduce - The block used to combine the accumulated value and the next value.
///          Cannot be nil.
///
/// Returns a reduced value.
- (id)foldLeftWithStart:(nullable id)start reduce:(id _Nullable (^)(id _Nullable accumulator, ValueType _Nullable value))reduce;

/// Applies a right fold to the sequence.
///
/// A right fold is equivalent to recursion on the list. The block is evaluated
/// from the right to the left in list. It is right associative so it's applied
/// to the rightmost elements first. For example, in the sequence [1,2,3] the
/// block is applied in the order:
///   reduce(1, reduce(2, reduce(3, start)))
///
/// start  - The starting value for the fold.
/// reduce - The block used to combine the accumulated value and the next head.
///          The block is given the accumulated value and the value of the rest
///          of the computation (result of the recursion). This is computed when
///          you retrieve its value using `rest.head`. This allows you to
///          prevent unnecessary computation by not accessing `rest.head` if you
///          don't need to.
///
/// Returns a reduced value.
- (id)foldRightWithStart:(nullable id)start reduce:(id _Nullable (^)(id _Nullable first, RACSequence *rest))reduce;

/// Check if any value in sequence passes the block.
///
/// block - The block predicate used to check each item. Cannot be nil.
///
/// Returns a boolean indiciating if any value in the sequence passed.
- (BOOL)any:(BOOL (^)(ValueType _Nullable value))block;

/// Check if all values in the sequence pass the block.
///
/// block - The block predicate used to check each item. Cannot be nil.
///
/// Returns a boolean indicating if all values in the sequence passed.
- (BOOL)all:(BOOL (^)(ValueType _Nullable value))block;

/// Returns the first object that passes the block.
///
/// block - The block predicate used to check each item. Cannot be nil.
///
/// Returns an object that passes the block or nil if no objects passed.
- (nullable ValueType)objectPassingTest:(BOOL (^)(ValueType _Nullable value))block;

/// Creates a sequence that dynamically generates its values.
///
/// headBlock - Invoked the first time -head is accessed.
/// tailBlock - Invoked the first time -tail is accessed.
///
/// The results from each block are memoized, so each block will be invoked at
/// most once, no matter how many times the head and tail properties of the
/// sequence are accessed.
///
/// Any side effects in `headBlock` or `tailBlock` should be thread-safe, since
/// the sequence may be evaluated at any time from any thread. Not only that, but
/// -tail may be accessed before -head, or both may be accessed simultaneously.
/// As noted above, side effects will only be triggered the _first_ time -head or
/// -tail is invoked.
///
/// Returns a sequence that lazily invokes the given blocks to provide head and
/// tail. `headBlock` must not be nil.
+ (RACSequence<ValueType> *)sequenceWithHeadBlock:(ValueType _Nullable (^)(void))headBlock tailBlock:(nullable RACSequence<ValueType> *(^)(void))tailBlock;

@end

@interface RACSequence<__covariant ValueType> (RACStream)

/// Returns a sequence that immediately sends the given value and then completes.
+ (RACSequence<ValueType> *)return:(nullable ValueType)value;

/// Returns a sequence that immediately completes.
+ (RACSequence<ValueType> *)empty;

/// A block which accepts a value from a RACSequence and returns a new sequence.
///
/// Setting `stop` to `YES` will cause the bind to terminate after the returned
/// value. Returning `nil` will result in immediate termination.
typedef RACSequence * _Nullable (^RACSequenceBindBlock)(ValueType _Nullable value, BOOL *stop);

/// Lazily binds a block to the values in the receiver.
///
/// This should only be used if you need to terminate the bind early, or close
/// over some state. -flattenMap: is more appropriate for all other cases.
///
/// block - A block returning a RACSequenceBindBlock. This block will be invoked
///         each time the bound sequence is re-evaluated. This block must not be
///         nil or return nil.
///
/// Returns a new sequence which represents the combined result of all lazy
/// applications of `block`.
- (RACSequence *)bind:(RACSequenceBindBlock (^)(void))block;

/// Subscribes to `sequence` when the source sequence completes.
- (RACSequence *)concat:(RACSequence *)sequence;

/// Zips the values in the receiver with those of the given sequence to create
/// RACTuples.
///
/// The first `next` of each sequence will be combined, then the second `next`,
/// and so forth, until either sequence completes or errors.
///
/// sequence - The sequence to zip with. This must not be `nil`.
///
/// Returns a new sequence of RACTuples, representing the combined values of the
/// two sequences. Any error from one of the original sequence will be forwarded
/// on the returned sequence.
- (RACSequence<RACTuple *> *)zipWith:(RACSequence *)sequence;

@end

/// Redeclarations of operations built on the RACStream primitives with more
/// precise type information.
@interface RACSequence<__covariant ValueType> (RACStreamOperations)

/// Maps `block` across the values in the receiver and flattens the result.
///
/// Note that operators applied _after_ -flattenMap: behave differently from
/// operators _within_ -flattenMap:. See the Examples section below.
///
/// This corresponds to the `SelectMany` method in Rx.
///
/// block - A block which accepts the values in the receiver and returns a new
///         instance of the receiver's class. Returning `nil` from this block is
///         equivalent to returning an empty sequence.
///
/// Returns a new sequence which represents the combined sequences resulting
/// from mapping `block`.
- (RACSequence *)flattenMap:(__kindof RACSequence * _Nullable (^)(ValueType _Nullable value))block;

/// Flattens a sequence of sequences.
///
/// This corresponds to the `Merge` method in Rx.
///
/// Returns a sequence consisting of the combined sequences obtained from the
/// receiver.
- (RACSequence *)flatten;

/// Maps `block` across the values in the receiver.
///
/// This corresponds to the `Select` method in Rx.
///
/// Returns a new sequence with the mapped values.
- (RACSequence *)map:(id _Nullable (^)(ValueType _Nullable value))block;

/// Replaces each value in the receiver with the given object.
///
/// Returns a new sequence which includes the given object once for each value in
/// the receiver.
- (RACSequence *)mapReplace:(nullable id)object;

/// Filters out values in the receiver that don't pass the given test.
///
/// This corresponds to the `Where` method in Rx.
///
/// Returns a new sequence with only those values that passed.
- (RACSequence<ValueType> *)filter:(BOOL (^)(id _Nullable value))block;

/// Filters out values in the receiver that equal (via -isEqual:) the provided
/// value.
///
/// value - The value can be `nil`, in which case it ignores `nil` values.
///
/// Returns a new sequence containing only the values which did not compare
/// equal to `value`.
- (RACSequence *)ignore:(nullable ValueType)value;

/// Unpacks each RACTuple in the receiver and maps the values to a new value.
///
/// reduceBlock - The block which reduces each RACTuple's values into one value.
///               It must take as many arguments as the number of tuple elements
///               to process. Each argument will be an object argument. The
///               return value must be an object. This argument cannot be nil.
///
/// Returns a new sequence of reduced tuple values.
- (RACSequence *)reduceEach:(RACReduceBlock)reduceBlock;

/// Returns a sequence consisting of `value`, followed by the values in the
/// receiver.
- (RACSequence<ValueType> *)startWith:(nullable ValueType)value;

/// Skips the first `skipCount` values in the receiver.
///
/// Returns the receiver after skipping the first `skipCount` values. If
/// `skipCount` is greater than the number of values in the sequence, an empty
/// sequence is returned.
- (RACSequence<ValueType> *)skip:(NSUInteger)skipCount;

/// Returns a sequence of the first `count` values in the receiver. If `count` is
/// greater than or equal to the number of values in the sequence, a sequence
/// equivalent to the receiver is returned.
- (RACSequence<ValueType> *)take:(NSUInteger)count;

/// Zips the values in the given sequences to create RACTuples.
///
/// The first value of each sequence will be combined, then the second value,
/// and so forth, until at least one of the sequences is exhausted.
///
/// sequences - The sequence to combine. If this collection is empty, the
///             returned sequence will be empty.
///
/// Returns a new sequence containing RACTuples of the zipped values from the
/// sequences.
+ (RACSequence<RACTuple *> *)zip:(id<NSFastEnumeration>)sequence;

/// Zips sequences using +zip:, then reduces the resulting tuples into a single
/// value using -reduceEach:
///
/// sequences   - The sequences to combine. If this collection is empty, the
///               returned sequence will be empty.
/// reduceBlock - The block which reduces the values from all the sequences
///               into one value. It must take as many arguments as the
///               number of sequences given. Each argument will be an object
///               argument. The return value must be an object. This argument
///               must not be nil.
///
/// Example:
///
///   [RACSequence zip:@[ stringSequence, intSequence ]
///       reduce:^(NSString *string, NSNumber *number) {
///           return [NSString stringWithFormat:@"%@: %@", string, number];
///       }];
///
/// Returns a new sequence containing the results from each invocation of
/// `reduceBlock`.
+ (RACSequence<ValueType> *)zip:(id<NSFastEnumeration>)sequences reduce:(RACReduceBlock)reduceBlock;

/// Returns a sequence obtained by concatenating `sequences` in order.
+ (RACSequence<ValueType> *)concat:(id<NSFastEnumeration>)sequences;

/// Combines values in the receiver from left to right using the given block.
///
/// The algorithm proceeds as follows:
///
///  1. `startingValue` is passed into the block as the `running` value, and the
///  first element of the receiver is passed into the block as the `next` value.
///  2. The result of the invocation is added to the returned sequence.
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
/// Returns a new sequence that consists of each application of `reduceBlock`. If
/// the receiver is empty, an empty sequence is returned.
- (RACSequence *)scanWithStart:(nullable id)startingValue reduce:(id _Nullable (^)(id _Nullable running, ValueType _Nullable next))reduceBlock;

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
/// Returns a new sequence that consists of each application of `reduceBlock`.
/// If the receiver is empty, an empty sequence is returned.
- (RACSequence *)scanWithStart:(nullable id)startingValue reduceWithIndex:(id _Nullable (^)(id _Nullable running, ValueType _Nullable next, NSUInteger index))reduceBlock;

/// Combines each previous and current value into one object.
///
/// This method is similar to -scanWithStart:reduce:, but only ever operates on
/// the previous and current values (instead of the whole sequence), and does
/// not pass the return value of `reduceBlock` into the next invocation of it.
///
/// start       - The value passed into `reduceBlock` as `previous` for the
///               first value.
/// reduceBlock - The block that combines the previous value and the current
///               value to create the reduced value. Cannot be nil.
///
/// Examples
///
///      RACSequence *numbers = [@[ @1, @2, @3, @4 ].rac_sequence;
///
///      // Contains 1, 3, 5, 7
///      RACSequence *sums = [numbers combinePreviousWithStart:@0 reduce:^(NSNumber *previous, NSNumber *next) {
///          return @(previous.integerValue + next.integerValue);
///      }];
///
/// Returns a new sequence consisting of the return values from each application of
/// `reduceBlock`.
- (RACSequence *)combinePreviousWithStart:(nullable ValueType)start reduce:(id _Nullable (^)(ValueType _Nullable previous, ValueType _Nullable current))reduceBlock;

/// Takes values until the given block returns `YES`.
///
/// Returns a RACSequence of the initial values in the receiver that fail
/// `predicate`. If `predicate` never returns `YES`, a sequence equivalent to
/// the receiver is returned.
- (RACSequence<ValueType> *)takeUntilBlock:(BOOL (^)(ValueType _Nullable x))predicate;

/// Takes values until the given block returns `NO`.
///
/// Returns a sequence of the initial values in the receiver that pass
/// `predicate`. If `predicate` never returns `NO`, a sequence equivalent to the
/// receiver is returned.
- (RACSequence<ValueType> *)takeWhileBlock:(BOOL (^)(ValueType _Nullable x))predicate;

/// Skips values until the given block returns `YES`.
///
/// Returns a sequence containing the values of the receiver that follow any
/// initial values failing `predicate`. If `predicate` never returns `YES`,
/// an empty sequence is returned.
- (RACSequence<ValueType> *)skipUntilBlock:(BOOL (^)(ValueType _Nullable x))predicate;

/// Skips values until the given block returns `NO`.
///
/// Returns a sequence containing the values of the receiver that follow any
/// initial values passing `predicate`. If `predicate` never returns `NO`, an
/// empty sequence is returned.
- (RACSequence<ValueType> *)skipWhileBlock:(BOOL (^)(ValueType _Nullable x))predicate;

/// Returns a sequence of values for which -isEqual: returns NO when compared to
/// the previous value.
- (RACSequence<ValueType> *)distinctUntilChanged;

@end

NS_ASSUME_NONNULL_END
