//
//  EZBaseQueryWindow.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZBaseQueryWindow.h"
#import "EZTitlebar.h"
#import "EZWindowManager.h"

@interface EZBaseQueryWindow () <NSWindowDelegate, NSToolbarDelegate>

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

    self.titleBar = [[EZTitlebar alloc] initWithFrame:CGRectMake(0, 0, self.width, 50)];
    [titleView addSubview:self.titleBar];
    [self.titleBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(titleView);
    }];
    
    mm_weakify(self);
    [self.titleBar.pinButton setClickBlock:^(EZButton * _Nonnull button) {
        NSLog(@"pin");
        mm_strongify(self);
        
        self.pin = !self.pin;
        
        NSWindowLevel level = self.pin ? kCGFloatingWindowLevel : kCGNormalWindowLevel;
        self.level = level;
    }];
}

- (void)setWindowType:(EZWindowType)windowType {
    _windowType = windowType;
    
    EZBaseQueryViewController *viewController = [[EZBaseQueryViewController alloc] initWithWindowType:windowType];
    viewController.view.frame = [EZWindowFrameManager.shared windowFrameWithType:windowType];
    self.viewController = viewController;
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
    
    if (self.resizeWindowBlock) {
        self.resizeWindowBlock();
    }
    
    if (self.viewController.resizeWindowBlock) {
        self.viewController.resizeWindowBlock();
    }
    
    EZWindowFrameManager *frameManager = [EZWindowFrameManager shared];
    switch (self.windowType) {
        case EZWindowTypeMain:
            frameManager.mainWindowFrame = self.frame;
            break;
        case EZWindowTypeFixed:
            frameManager.fixedWindowFrame = self.frame;
            break;
        case EZWindowTypeMini:
            frameManager.miniWindowFrame = self.frame;
            break;
        default:
            break;
    }
}

@end
