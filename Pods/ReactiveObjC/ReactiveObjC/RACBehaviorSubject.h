//
//  RACBehaviorSubject.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 3/16/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACSubject.h"

NS_ASSUME_NONNULL_BEGIN

/// A behavior subject sends the last value it received when it is subscribed to.
@interface RACBehaviorSubject<ValueType> : RACSubject<ValueType>

/// Creates a new behavior subject with a default value. If it hasn't received
/// any values when it gets subscribed to, it sends the default value.
+ (instancetype)behaviorSubjectWithDefaultValue:(nullable ValueType)value;

@end

NS_ASSUME_NONNULL_END
