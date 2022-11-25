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
        
        // ⚠️ must set backgroundColor
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
    
    if (self.windowType == EZWindowTypeMain) {
        pinButton.hidden = YES;
    } else {
        [self standardWindowButton:NSWindowZoomButton].hidden = YES;
        [self standardWindowButton:NSWindowCloseButton].hidden = YES;
        [self standardWindowButton:NSWindowMiniaturizeButton].hidden = YES;
    }

    
    NSImage *normalImage = [[NSImage imageNamed:@"new_pin_normal"] resizeToSize:CGSizeMake(16, 16)];
    NSImage *selectedImage = [[NSImage imageNamed:@"new_pin_selected"] resizeToSize:CGSizeMake(16, 16)];
    pinButton.image = normalImage;

    mm_weakify(self);
    [pinButton setClickBlock:^(EZButton * _Nonnull button) {
        NSLog(@"pin");
        mm_strongify(self);
        
        self.pin = !self.pin;
        NSImage *image = self.pin ? selectedImage : normalImage;
        button.image = image;

        NSWindowLevel level = self.pin ? kCGFloatingWindowLevel : kCGNormalWindowLevel;
        self.level = level;
    }];
    
    [pinButton setMouseDownBlock:^(EZButton * _Nonnull button) {
        NSImage *highlightImage = self.pin ? normalImage : selectedImage;
        button.image = highlightImage;
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
    
    if (self.resizeWindowBlock) {
        self.resizeWindowBlock();
    }
    
    if (self.viewController.resizeWindowBlock) {
        self.viewController.resizeWindowBlock();
    }
    
    EZLayoutManager *frameManager = [EZLayoutManager shared];
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
