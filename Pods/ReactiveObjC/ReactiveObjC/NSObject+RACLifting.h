//
//  NSObject+RACLifting.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 10/13/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSignal<__covariant ValueType>;
@class RACTuple;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (RACLifting)

/// Lifts the selector on the receiver into the reactive world. The selector will
/// be invoked whenever any signal argument sends a value, but only after each
/// signal has sent an initial value.
///
/// It will replay the most recently sent value to new subscribers.
///
/// This does not support C arrays or unions.
///
/// selector    - The selector on self to invoke.
/// firstSignal - The signal corresponding to the first method argument. This
///               must not be nil.
/// ...         - A list of RACSignals corresponding to the remaining arguments.
///               There must be a non-nil signal for each method argument.
///
/// Examples
///
///   [button rac_liftSelector:@selector(setTitleColor:forState:) withSignals:textColorSignal, [RACSignal return:@(UIControlStateNormal)], nil];
///
/// Returns a signal which sends the return value from each invocation of the
/// selector. If the selector returns void, it instead sends RACUnit.defaultUnit.
/// It completes only after all the signal arguments complete.
- (RACSignal *)rac_liftSelector:(SEL)selector withSignals:(RACSignal *)firstSignal, ... NS_REQUIRES_NIL_TERMINATION;

/// Like -rac_liftSelector:withSignals:, but accepts an array instead of
/// a variadic list of arguments.
- (RACSignal *)rac_liftSelector:(SEL)selector withSignalsFromArray:(NSArray<RACSignal *> *)signals;

/// Like -rac_liftSelector:withSignals:, but accepts a signal sending tuples of
/// arguments instead of a variadic list of arguments.
- (RACSignal *)rac_liftSelector:(SEL)selector withSignalOfArguments:(RACSignal<RACTuple *> *)arguments;

@end

NS_ASSUME_NONNULL_END
