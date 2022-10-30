//
//  NSObject+RACAppKitBindings.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 4/17/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RACChannelTerminal;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (RACAppKitBindings)

/// Invokes -rac_channelToBinding:options: without any options.
- (RACChannelTerminal *)rac_channelToBinding:(NSString *)binding;

/// Applies a Cocoa binding to the receiver, then exposes a RACChannel-based
/// interface for manipulating it.
///
/// Creating two of the same bindings on the same object will result in undefined
/// behavior.
///
/// binding - The name of the binding. This must not be nil.
/// options - Any options to pass to Cocoa Bindings. This may be nil.
///
/// Returns a RACChannelTerminal which will send future values from the receiver,
/// and update the receiver when values are sent to the terminal.
- (RACChannelTerminal *)rac_channelToBinding:(NSString *)binding options:(nullable NSDictionary *)options;

@end

NS_ASSUME_NONNULL_END
