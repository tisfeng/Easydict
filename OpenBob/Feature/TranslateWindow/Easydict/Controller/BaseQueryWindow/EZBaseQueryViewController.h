//
//  MainTabViewController.h
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZBaseQueryViewController : NSViewController

@property (nonatomic, weak) NSWindow *window;
@property (nonatomic, copy) void (^resizeWindowBlock)(void);

- (void)startQueryText:(NSString *)text;
- (void)startQueryImage:(NSImage *)image;

@end

NS_ASSUME_NONNULL_END
