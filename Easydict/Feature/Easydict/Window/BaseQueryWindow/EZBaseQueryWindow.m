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
    
    
    EZHoverButton *pinButton = self.titleBar.pinButton;
    
    CGSize imageSize = CGSizeMake(18, 18);
    
    // Since the system's dark picture mode cannot dynamically follow the mode switch changes, we manually implement dark mode picture coloring.
    NSColor *pinNormalLightTintColor = [NSColor mm_colorWithHexString:@"#797A7F"];
    NSColor *pinNormalDarkTintColor = [NSColor mm_colorWithHexString:@"#C0C1C4"];

    NSImage *normalLightImage = [[NSImage imageNamed:@"new_pin_normal"] resizeToSize:imageSize];
    normalLightImage = [normalLightImage imageWithTintColor:pinNormalLightTintColor];
    NSImage *normalDarkImage = [normalLightImage imageWithTintColor:pinNormalDarkTintColor];

    NSImage *selectedImage = [[NSImage imageNamed:@"new_pin_selected"] resizeToSize:imageSize];
    
    void (^changePinButtonImageBlock)(void) = ^{
        [pinButton excuteLight:^(EZHoverButton *button) {
            NSImage *image = self.pin ? selectedImage : normalLightImage;
            button.image = image;
        } drak:^(EZHoverButton *button) {
            NSImage *image = self.pin ? selectedImage : normalDarkImage;
            button.image = image;
        }];
    };
    
    changePinButtonImageBlock();

    mm_weakify(self);
    
    [pinButton setMouseDownBlock:^(EZButton * _Nonnull button) {
        NSLog(@"pin mouse down, state: %ld", button.buttonState);
        mm_strongify(self);

        self.pin = !self.pin;
        
        changePinButtonImageBlock();
    }];
    
    [pinButton setMouseUpBlock:^(EZButton * _Nonnull button) {
        NSLog(@"pin mouse up, state: %ld", button.buttonState);
        mm_strongify(self);
        
        BOOL oldPin = !self.pin;
        
        if (button.buttonState == EZButtonNormalState) {
            self.pin = oldPin;
        } else if (button.state == EZButtonHoverState) {
            // Means clicked pin button
            
            self.pin = !oldPin;
            NSWindowLevel level = self.pin ? kCGFloatingWindowLevel : kCGNormalWindowLevel;
            self.level = level;
        }
        
        changePinButtonImageBlock();
    }];
    
    [pinButton setMouseEnterBlock:^(EZButton * _Nonnull button) {
        NSColor *lightHighlightColor = [NSColor mm_colorWithHexString:@"#E6E6E6"];
        NSColor *darkHighlightColor = [NSColor mm_colorWithHexString:@"#484848"];
        [button excuteLight:^(EZButton *button) {
            button.backgroundHoverColor = lightHighlightColor;
            button.backgroundHighlightColor = lightHighlightColor;
        } drak:^(EZButton *button) {
            button.backgroundHoverColor = darkHighlightColor;
            button.backgroundHighlightColor = darkHighlightColor;
        }];
    }];
    [pinButton setMouseExitedBlock:^(EZButton * _Nonnull button) {
        button.backgroundColor = NSColor.clearColor;
    }];
}

- (void)setWindowType:(EZWindowType)windowType {
    _windowType = windowType;
    
    EZBaseQueryViewController *viewController = [[EZBaseQueryViewController alloc] initWithWindowType:windowType];
    self.viewController = viewController;
}

- (void)setViewController:(EZBaseQueryViewController *)viewController {
    _viewController = viewController;

    viewController.window = self;
    self.contentViewController = viewController;
}

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
    
    if (self.viewController.resizeWindowBlock) {
        self.viewController.resizeWindowBlock();
    }
}

- (void)windowDidMove:(NSNotification *)notification {
    [[EZLayoutManager shared] updateWindowFrame:self];
}

@end
