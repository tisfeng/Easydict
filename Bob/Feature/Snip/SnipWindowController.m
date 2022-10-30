//
//  SnipWindowController.m
//  Bob
//
//  Created by ripper on 2019/11/27.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "SnipWindowController.h"

@implementation SnipWindowController

- (NSImage *)screenshot:(NSScreen *)screen {
    CFArrayRef windowsRef = CGWindowListCreate(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);

    NSRect rect = [screen frame];
    NSRect mainRect = [NSScreen mainScreen].frame;
    for (NSScreen *subScreen in [NSScreen screens]) {
        if ((int) subScreen.frame.origin.x == 0 && (int) subScreen.frame.origin.y == 0) {
            mainRect = subScreen.frame;
        }
    }
    // https://isaacpg001.github.io/programming/2011/08/05/mac-multi-display-screen-crop/
    rect = NSMakeRect(rect.origin.x, (mainRect.size.height) - (rect.origin.y + rect.size.height), rect.size.width, rect.size.height);
    NSLog(@"screenshot: %@", NSStringFromRect(rect));
    
    CGImageRef imageRef = CGWindowListCreateImageFromArray(rect, windowsRef, kCGWindowImageDefault);
    CFRelease(windowsRef);
    // 获取屏幕实际像素
    NSRect screenPixelRect = [screen convertRectToBacking:screen.frame];
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:screenPixelRect.size];
    CGImageRelease(imageRef);
    return image;
}

- (void)captureWithScreen:(NSScreen *)screen {
    NSImage *image = [self screenshot:screen];
    self.window = [[SnipWindow alloc] initWithContentRect:screen.frame styleMask:NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO screen:screen];
    self.window.contentViewController = [SnipViewController mm_make:^(SnipViewController*  _Nonnull obj) {
        obj.screen = screen;
        obj.window = self.window;
        obj.image = image;
        mm_weakify(self)
        [obj setStartBlock:^{
            mm_strongify(self);
            if (self.startBlock) {
                self.startBlock(self);
            }
        }];
        [obj setEndBlock:^(NSImage * _Nullable image) {
            if (self.endBlock) {
                self.endBlock(self, image);
            }
        }];
    }];
    [self.window setFrame:screen.frame display:YES animate:NO];
    [self showWindow:nil];
}

- (SnipViewController *)snipViewController {
    return (SnipViewController *)self.contentViewController;
}

@end
