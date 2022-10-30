//
//  NSString+RACSequenceAdditions.h
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2012-10-29.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSequence<__covariant ValueType>;

NS_ASSUME_NONNULL_BEGIN

@interface NSString (RACSequenceAdditions)

/// Creates and returns a sequence containing strings corresponding to each
/// composed character sequence in the receiver.
///
/// Mutating the receiver will not affect the sequence after it's been created.
@property (nonatomic, copy, readonly) RACSequence<NSString *> *rac_sequence;

@end

NS_ASSUME_NONNULL_END
