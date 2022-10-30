//
//  NSText+RACSignalSupport.h
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2013-03-08.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RACSignal<__covariant ValueType>;

NS_ASSUME_NONNULL_BEGIN

@interface NSText (RACSignalSupport)

/// Returns a signal which sends the current `string` of the receiver, then the
/// new value any time it changes.
- (RACSignal<NSString *> *)rac_textSignal;

@end

NS_ASSUME_NONNULL_END
