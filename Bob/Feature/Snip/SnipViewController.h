//
//  SnipViewController.h
//  Bob
//
//  Created by ripper on 2019/11/27.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SnipViewController : NSViewController

@property (nonatomic, weak) NSScreen *screen;
@property (nonatomic, weak) NSWindow *window;
@property (nonatomic, strong) NSImage *image;

@property (nonatomic, copy) void(^startBlock)(void);
@property (nonatomic, copy) void(^endBlock)(NSImage * _Nullable image);

@property (nonatomic, assign, readonly) BOOL isStart;

- (void)showAndUpdateFocusView;
- (void)hiddenFocusView;

@end

NS_ASSUME_NONNULL_END
