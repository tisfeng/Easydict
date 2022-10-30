//
//  NSEnumerator+RACSequenceAdditions.h
//  ReactiveObjC
//
//  Created by Uri Baghin on 07/01/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSequence<__covariant ValueType>;

NS_ASSUME_NONNULL_BEGIN

@interface NSEnumerator<ObjectType> (RACSequenceAdditions)

/// Creates and returns a sequence corresponding to the receiver.
///
/// The receiver is exhausted lazily as the sequence is enumerated.
@property (nonatomic, copy, readonly) RACSequence<ObjectType> *rac_sequence;

@end

NS_ASSUME_NONNULL_END
