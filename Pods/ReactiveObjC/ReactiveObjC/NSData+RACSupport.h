//
//  NSData+RACSupport.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 5/11/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACScheduler;
@class RACSignal<__covariant ValueType>;

NS_ASSUME_NONNULL_BEGIN

@interface NSData (RACSupport)

// Read the data at the URL using -[NSData initWithContentsOfURL:options:error:].
// Sends the data or the error.
//
// scheduler - cannot be nil.
+ (RACSignal<NSData *> *)rac_readContentsOfURL:(nullable NSURL *)URL options:(NSDataReadingOptions)options scheduler:(RACScheduler *)scheduler;

@end

NS_ASSUME_NONNULL_END
