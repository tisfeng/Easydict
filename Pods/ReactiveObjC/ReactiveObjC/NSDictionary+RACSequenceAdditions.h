//
//  NSDictionary+RACSequenceAdditions.h
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2012-10-29.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSequence<__covariant ValueType>;
@class RACTwoTuple<__covariant First, __covariant Second>;

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (RACSequenceAdditions)

/// Creates and returns a sequence of key/value tuples.
///
/// Mutating the receiver will not affect the sequence after it's been created.
@property (nonatomic, copy, readonly) RACSequence<RACTwoTuple<KeyType, ObjectType> *> *rac_sequence;

/// Creates and returns a sequence corresponding to the keys in the receiver.
///
/// Mutating the receiver will not affect the sequence after it's been created.
@property (nonatomic, copy, readonly) RACSequence<KeyType> *rac_keySequence;

/// Creates and returns a sequence corresponding to the values in the receiver.
///
/// Mutating the receiver will not affect the sequence after it's been created.
@property (nonatomic, copy, readonly) RACSequence<ObjectType> *rac_valueSequence;

@end

NS_ASSUME_NONNULL_END
