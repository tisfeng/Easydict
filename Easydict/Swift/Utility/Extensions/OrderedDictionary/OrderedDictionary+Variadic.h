//
//  OrderedDictionary+Variadic.h
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMOrderedDictionary;

NS_ASSUME_NONNULL_BEGIN

@interface MMOrderedDictionary (Variadic)

/// Initialize with keys and objects using variadic arguments
/// @param firstKey The first key, followed by alternating value, key pairs, terminated by nil
- (instancetype)initWithKeysAndObjects:(nullable id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;

@end

NS_ASSUME_NONNULL_END
