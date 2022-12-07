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
#import "NSImage+EZResize.h"

@interface EZBaseQueryWindow () <NSWindowDelegate, NSToolbarDelegate>

@end

@implementation EZBaseQueryWindow

- (instancetype)initWithWindowType:(EZWindowType)type {
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable;
    if (self = [super initWithContentRect:CGRectZero styleMask:style backing:NSBackingStoreBuffered defer:YES]) {
        self.windowType = type;
        
        self.movableByWindowBackground = YES;
        self.level = NSNormalWindowLevel;
        self.titlebarAppearsTransparent = YES;
        self.titleVisibility = NSWindowTitleHidden;
        self.delegate = self;
        
        // !!!: must set backgroundColor
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
    
    self.titleBar = [[EZTitlebar alloc] initWithFrame:CGRectMake(0, 0, self.width, 30)];
    [titleView addSubview:self.titleBar];
    [self.titleBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(titleView);
    }];
    
    
    EZButton *pinButton = self.titleBar.pinButton;
    [self updatePinButtonImage];
    
    mm_weakify(self);
    [pinButton setMouseDownBlock:^(EZButton *_Nonnull button) {
        //        NSLog(@"pin mouse down, state: %ld", button.buttonState);
        mm_strongify(self);
        
        self.pin = !self.pin;
        
        [self updatePinButtonImage];
    }];
    
    [pinButton setMouseUpBlock:^(EZButton *_Nonnull button) {
        //        NSLog(@"pin mouse up, state: %ld", button.buttonState);
        mm_strongify(self);
        
        BOOL oldPin = !self.pin;
        
        // This means clicked pin button.
        if (button.state == EZButtonHoverState) {
            self.pin = !oldPin;
        } else if (button.buttonState == EZButtonNormalState) {
            self.pin = oldPin;
        }
        [self updatePinButtonImage];
    }];
}

- (void)updatePinButtonImage {
    CGFloat imageWidth = 18;
    CGSize imageSize = CGSizeMake(imageWidth, imageWidth);
    
    // Since the system's dark picture mode cannot dynamically follow the mode switch changes, we manually implement dark mode picture coloring.
    NSColor *pinNormalLightTintColor = [NSColor mm_colorWithHexString:@"#797A7F"];
    NSColor *pinNormalDarkTintColor = [NSColor mm_colorWithHexString:@"#C0C1C4"];
    
    NSImage *normalLightImage = [[NSImage imageNamed:@"new_pin_normal"] resizeToSize:imageSize];
    normalLightImage = [normalLightImage imageWithTintColor:pinNormalLightTintColor];
    NSImage *normalDarkImage = [normalLightImage imageWithTintColor:pinNormalDarkTintColor];
    
    NSImage *selectedImage = [[NSImage imageNamed:@"new_pin_selected"] resizeToSize:imageSize];
    
    [self.titleBar.pinButton excuteLight:^(EZHoverButton *button) {
        NSImage *image = self.pin ? selectedImage : normalLightImage;
        button.image = image;
    } drak:^(EZHoverButton *button) {
        NSImage *image = self.pin ? selectedImage : normalDarkImage;
        button.image = image;
    }];
}


#pragma mark - Setter

- (void)setWindowType:(EZWindowType)windowType {
    _windowType = windowType;
    
    EZBaseQueryViewController *viewController = [[EZBaseQueryViewController alloc] initWithWindowType:windowType];
    self.queryViewController = viewController;
}

- (void)setQueryViewController:(EZBaseQueryViewController *)viewController {
    _queryViewController = viewController;
    
    viewController.window = self;
    self.contentViewController = viewController;
}

- (void)setPin:(BOOL)pin {
    _pin = pin;
    
    [self updatePinButtonImage];
    
    NSWindowLevel level = self.pin ? kCGMaximumWindowLevel : kCGNormalWindowLevel;
    self.level = level;
}

#pragma mark - Rewrite

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (void)dealloc {
    NSLog(@"dealloc: %@", self);
}

#pragma makr - NSWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)notification {
    //    NSLog(@"windowDidBecomeKey: %@", self);
}

#pragma mark - NSNotification

- (void)windowDidResize:(NSNotification *)aNotification {
    //   NSLog(@"MainWindow 窗口拉伸, (%.2f, %.2f)", self.width, self.height);
    
    [[EZLayoutManager shared] updateWindowFrame:self];
    
    if (self.resizeWindowBlock) {
        self.resizeWindowBlock();
    }
    
    if (self.queryViewController.resizeWindowBlock) {
        self.queryViewController.resizeWindowBlock();
    }
}

- (void)windowDidMove:(NSNotification *)notification {
    [[EZLayoutManager shared] updateWindowFrame:self];
}

- (void)windowDidResignKey:(NSNotification *)notification {
    //    NSLog(@"window Did ResignKey: %@", self);
    
    EZBaseQueryWindow *floatingWindow = [[EZWindowManager shared] floatingWindow];
    // Do not close main window
    if (!floatingWindow.pin && floatingWindow.windowType != EZWindowTypeMain) {
        [[EZWindowManager shared] closeFloatingWindow];
    }
}

// Window is hidden or showing.
- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
    //    NSLog(@"window Did Change Occlusion State");
    
    // Window is obscured
    if (self.occlusionState != NSWindowOcclusionStateVisible) {
        
    }
}

@end
