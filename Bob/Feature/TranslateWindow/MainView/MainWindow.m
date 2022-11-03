//
//  MainWindow.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "MainWindow.h"
#import "MainViewController.h"

@implementation MainWindow

- (instancetype)init {
//- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag {

    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable;

//    MainWindow *window = [[MainWindow alloc] initWithContentRect:CGRectMake(0, 0, 150, 200) styleMask:style backing:NSBackingStoreBuffered defer:YES];

    if (self = [super initWithContentRect:CGRectZero styleMask:style backing:NSBackingStoreBuffered defer:YES]) {
        self.movableByWindowBackground = YES;
        self.level = NSNormalWindowLevel; //NSModalPanelWindowLevel;
        self.backgroundColor = [NSColor clearColor];
        self.hasShadow = YES;
        self.opaque = NO;
        
        MainViewController *vc = [[MainViewController alloc] init];
        self.contentViewController = vc;
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowDidResize:)
                                                     name:NSWindowDidResizeNotification
                                                   object:self];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (void)windowDidResize:(NSNotification *)aNotification {
    NSLog(@"MainWindow 窗口拉伸, (%.2f, %.2f)", self.width, self.height);
    
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSLog(@"oldSize: %@", @(oldSize));
    // 根据需要调整NSView上面的别的控件和视图的frame
}

//- (NSSize)resizeIncrements {
//    return CGSizeMake(300, 300);
//}

@end
