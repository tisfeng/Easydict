//
//  EZBaseQueryWindow.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZBaseQueryWindow.h"

@interface EZBaseQueryWindow () <NSWindowDelegate, NSToolbarDelegate>

@property (strong, nonatomic) NSToolbar *myToolbar;

@end

@implementation EZBaseQueryWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag {
    if (self = [super initWithContentRect:contentRect styleMask:style backing:NSBackingStoreBuffered defer:flag]) {
        self.movableByWindowBackground = YES;
        self.level = NSNormalWindowLevel; // NSModalPanelWindowLevel;
        self.titlebarAppearsTransparent = YES;
        self.titleVisibility = NSWindowTitleHidden;
        self.delegate = self;
        
        [self excuteLight:^(NSWindow *window) {
            window.backgroundColor = NSColor.mainViewBgLightColor;
        } drak:^(NSWindow *window) {
            window.backgroundColor = NSColor.mainViewBgDarkColor;
        }];
        
        [self setupUI];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowDidResize:)
                                                     name:NSWindowDidResizeNotification
                                                   object:self];
    }
    return self;
}

- (void)setupUI {
    NSView *themeView = self.contentView.superview;
    NSView *titleView = themeView.subviews[1];
    
    self.titleBar = [[EZTitlebar alloc] init];
    [titleView addSubview:self.titleBar];
    [self.titleBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(titleView);
    }];
}

- (void)setViewController:(EZBaseQueryViewController *)viewController {
    _viewController = viewController;
    
    self.contentViewController = viewController;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}


#pragma makr - NSWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)notification {
//    NSLog(@"windowDidBecomeKey: %@", self);
}

#pragma mark - NSNotification

- (void)windowDidResize:(NSNotification *)aNotification {
//   NSLog(@"MainWindow 窗口拉伸, (%.2f, %.2f)", self.width, self.height);

    if (self.viewController.resizeWindowBlock) {
        self.viewController.resizeWindowBlock();
    }
}

@end
