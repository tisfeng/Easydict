//
//  NSFileHandle+RACSupport.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 5/10/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSignal<__covariant ValueType>;

NS_ASSUME_NONNULL_BEGIN

@interface NSFileHandle (RACSupport)

// Read any available data in the background and send it. Completes when data
// length is <= 0.
- (RACSignal<NSData *> *)rac_readInBackground;

@end

NS_ASSUME_NONNULL_END
