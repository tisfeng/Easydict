//
//  SnipWindowController.h
//  Bob
//
//  Created by ripper on 2019/11/27.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SnipWindow.h"
#import "SnipViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SnipWindowController : NSWindowController

@property (nonatomic, copy) void(^startBlock)(SnipWindowController *windowController);
@property (nonatomic, copy) void(^endBlock)(SnipWindowController *windowController, NSImage * _Nullable image);
@property (nonatomic, readonly) SnipViewController *snipViewController;

- (void)captureWithScreen:(NSScreen *)screen;

@end

NS_ASSUME_NONNULL_END
