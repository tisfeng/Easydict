//
//  EZWindowManager.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZWindowManager.h"
#import "EZBaseQueryViewController.h"
#import "EZFixedQueryWindow.h"
#import "EZEventMonitor.h"
#import "Snip.h"
#import "Configuration.h"

@interface EZWindowManager ()

@property (nonatomic, strong) NSRunningApplication *lastFrontmostApplication;

@property (nonatomic, strong) EZEventMonitor *eventMonitor;
@property (nonatomic, copy) NSString *selectedText;

@property (nonatomic, assign) CGPoint offsetPoint;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGPoint endPoint;

@end


@implementation EZWindowManager

static EZWindowManager *_instance;

+ (instancetype)shared {
    if (!_instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[self alloc] init];
        });
    }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.offsetPoint = CGPointMake(15, -15);
    self.eventMonitor = [[EZEventMonitor alloc] init];
    [self setupEventMonitor];
}

- (void)setupEventMonitor {
    [self.eventMonitor startMonitor];
    
    mm_weakify(self);
    [self.eventMonitor setSelectedTextBlock:^(NSString *_Nonnull selectedText) {
        mm_strongify(self);
        self.selectedText = selectedText;
        
        // ⚠️ Record current selected start and end point, eventMonitor's startPoint will change every valid event.
        self.startPoint = self.eventMonitor.startPoint;
        self.endPoint = self.eventMonitor.endPoint;
        
        CGPoint point = [self getPopButtonWindowLocation];
        [self.popWindow setFrameTopLeftPoint:point];
        [self.popWindow orderFront:nil];
        [self.popWindow orderFrontRegardless];
        
        //        self.popWindow.level = kCGMaximumWindowLevel;
        
        //        [NSApp activateIgnoringOtherApps:YES];
        
        [self.mainWindow orderBack:nil];
    }];
    
    [self.eventMonitor setDismissPopButtonBlock:^{
        //        NSLog(@"dismiss pop button");
        mm_strongify(self);
        [self.popWindow close];
    }];
    
    [self.eventMonitor setDismissMiniWindowBlock:^{
        mm_strongify(self);
        if (!self.miniWindow.pin) {
            [self.miniWindow close];
        }
    }];
    
    [self.eventMonitor setDismissFixedWindowBlock:^{
        mm_strongify(self);
        if (!self.fixedWindow.pin) {
            [self.fixedWindow close];
        }
    }];
}

#pragma mark - Getter

- (EZMainQueryWindow *)mainWindow {
    if (!_mainWindow) {
        _mainWindow = [EZMainQueryWindow shared];
    }
    return _mainWindow;
}

- (EZFixedQueryWindow *)fixedWindow {
    if (!_fixedWindow) {
        _fixedWindow = [EZFixedQueryWindow shared];
    }
    return _fixedWindow;
}

- (EZMiniQueryWindow *)miniWindow {
    if (!_miniWindow) {
        _miniWindow = [[EZMiniQueryWindow alloc] init];
        _miniWindow.releasedWhenClosed = NO;
    }
    return _miniWindow;
}

- (EZPopButtonWindow *)popWindow {
    if (!_popWindow) {
        _popWindow = [EZPopButtonWindow shared];
        
        mm_weakify(self);
        [_popWindow.popButton setMouseEnterBlock:^(EZButton *button) {
            mm_strongify(self);
            [self.popWindow close];
            
            [self showFloatingWindowWithQueryText:self.selectedText];
        }];
    }
    return _popWindow;
}

#pragma mark - Others

- (EZBaseQueryWindow *)windowWithType:(EZWindowType)type {
    EZBaseQueryWindow *window;
    switch (type) {
        case EZWindowTypeMain: {
            window = self.mainWindow;
            break;
        }
        case EZWindowTypeFixed: {
            window = self.fixedWindow;
            break;
        }
        default: {
            window = self.miniWindow;
            break;
        }
    }
    return window;
}

- (CGPoint)windowLocationWithType:(EZWindowType)type {
    CGPoint location;
    switch (type) {
        case EZWindowTypeMain: {
            location = CGPointZero;
            break;
        }
        case EZWindowTypeFixed: {
            location = [self getFixedWindowLocation];
            break;
        }
        default: {
            location = [self getMiniWindowLocation];
            break;
        }
    }
    return location;
}


- (void)showFloatingWindowType:(EZWindowType)type queryText:(NSString *)text {
    self.showingWindowType = type;
    CGPoint location = [self windowLocationWithType:type];
    EZBaseQueryWindow *window = [self windowWithType:type];
    [self showFloatingWindow:window atPoint:location];
    [window.viewController startQueryText:text];
}

- (void)showFloatingWindow:(NSWindow *)window atPoint:(CGPoint)point {
    NSLog(@"show floating window: %@", window);
    
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    [window setFrameTopLeftPoint:point];
    [window makeKeyAndOrderFront:nil];
    
    window.level = kCGFloatingWindowLevel;
    //    [NSApp activateIgnoringOtherApps:YES];
    
    [_mainWindow orderBack:nil];
}


/// Show floating window type according to text length, show fixed window if text too long.
- (void)showFloatingWindowWithQueryText:(NSString *)text {
    EZWindowType type = EZWindowTypeMini;
    if (text.length > 15) {
        type = EZWindowTypeFixed;
    }
    [self showFloatingWindowType:type queryText:text];
}

- (void)showAtMouseLocation {
    NSPoint mouseLocation = [NSEvent mouseLocation];
    // 找到鼠标所在屏幕
    NSScreen *screen = [NSScreen.screens mm_find:^id(NSScreen *_Nonnull obj, NSUInteger idx) {
        return NSPointInRect(mouseLocation, obj.frame) ? obj : nil;
    }];
    // 找不到屏幕；可能在边缘，放宽条件
    if (!screen) {
        screen = [NSScreen.screens mm_find:^id _Nullable(NSScreen *_Nonnull obj, NSUInteger idx) {
            return MMPointInRect(mouseLocation, obj.frame) ? obj : nil;
        }];
    }
    if (!screen) return;
    
    // 修正显示位置，用于保证window显示在鼠标所在的screen
    // 如果直接使用mouseLocation，可能会显示到其他screen（应该是由当前window在哪个屏幕的区域更多决定的）
    NSRect windowFrame = self.fixedWindow.frame;
    NSRect visibleFrame = screen.visibleFrame;
    
    if (mouseLocation.x < visibleFrame.origin.x + 10) {
        mouseLocation.x = visibleFrame.origin.x + 10;
    }
    if (mouseLocation.y < visibleFrame.origin.y + windowFrame.size.height + 10) {
        mouseLocation.y = visibleFrame.origin.y + windowFrame.size.height + 10;
    }
    if (mouseLocation.x > visibleFrame.origin.x + visibleFrame.size.width - windowFrame.size.width - 10) {
        mouseLocation.x = visibleFrame.origin.x + visibleFrame.size.width - windowFrame.size.width - 10;
    }
    if (mouseLocation.y > visibleFrame.origin.y + visibleFrame.size.height - 10) {
        mouseLocation.y = visibleFrame.origin.y + visibleFrame.size.height - 10;
    }
    
    // https://stackoverflow.com/questions/7460092/nswindow-makekeyandorderfront-makes-window-appear-but-not-key-or-front
    [self.fixedWindow makeKeyAndOrderFront:nil];
    if (!self.fixedWindow.isKeyWindow) {
        // fail to make key window, then force activate application for key window
        [NSApp activateIgnoringOtherApps:YES];
    }
    [self.fixedWindow setFrameTopLeftPoint:mouseLocation];
}

- (NSScreen *)getMouseLocatedScreen {
    NSPoint mouseLocation = [NSEvent mouseLocation];
    
    // 找到鼠标所在屏幕
    NSScreen *screen = [NSScreen.screens mm_find:^id(NSScreen *_Nonnull obj, NSUInteger idx) {
        return NSPointInRect(mouseLocation, obj.frame) ? obj : nil;
    }];
    // 找不到屏幕；可能在边缘，放宽条件
    if (!screen) {
        screen = [NSScreen.screens mm_find:^id _Nullable(NSScreen *_Nonnull obj, NSUInteger idx) {
            return MMPointInRect(mouseLocation, obj.frame) ? obj : nil;
        }];
    }
    
    return screen;
}

// Get the right-bottom point of start point and end point.
- (NSPoint)correctedMouseLocation {
    NSScreen *screen = [self getMouseLocatedScreen];
#if DEBUG
    NSAssert(screen != nil, @"no screen");
#endif
    if (!screen) {
        NSLog(@"no get MouseLocation");
        return CGPointZero;
    }
    
    NSPoint startLocation = self.startPoint;
    NSPoint endLocation = self.endPoint;
    NSPoint correctedLocation = endLocation;
    
    if (endLocation.x < startLocation.x) {
        correctedLocation = startLocation;
    }
    
    if (endLocation.y >= startLocation.y + self.eventMonitor.selectedTextFrame.size.height) {
        correctedLocation = startLocation;
    }
    
    return correctedLocation;
}

- (CGPoint)getPopButtonWindowLocation {
    NSPoint location = [self correctedMouseLocation];
    if (CGPointEqualToPoint(location, CGPointZero)) {
        return CGPointZero;
    }
    
    NSPoint popLocation = CGPointMake(location.x + self.offsetPoint.x, location.y + self.offsetPoint.y);
    
    return popLocation;
}

- (CGPoint)getMiniWindowLocation {
    NSPoint popButtonLocation = [self getPopButtonWindowLocation];
    if (CGPointEqualToPoint(popButtonLocation, CGPointZero)) {
        return CGPointZero;
    }
    
    CGFloat x = popButtonLocation.x + self.popWindow.width + self.offsetPoint.x;
    CGFloat y = popButtonLocation.y - 2 * self.offsetPoint.y;
    
    // left-bottom coordinate system
    // if x + miniWindow.width > screen.width, then x = screen.width - miniWindow.width
    NSScreen *screen = NSScreen.mainScreen;
    if (x + self.miniWindow.width > screen.frame.size.width) {
        x = screen.frame.size.width - self.miniWindow.width;
    }
    
    // if y - miniWindow.height < 0, then y = miniWindow.height
    if (y - self.miniWindow.height < 0) {
        y = self.miniWindow.height;
    }
    
    return CGPointMake(x, y);
}

// Get fixed window location, located at the right-top of screen.
- (CGPoint)getFixedWindowLocation {
    CGSize mainScreenSize = NSScreen.mainScreen.frame.size;
    CGFloat x = mainScreenSize.width - self.fixedWindow.width;
    CGFloat y = mainScreenSize.height;
    
    return CGPointMake(x, y);
}


- (void)ensureShowAtMouseLocation {
    [self showAtMouseLocation];
}

- (void)saveFrontmostApplication {
    NSString *identifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSRunningApplication *frontmostApplication = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if ([frontmostApplication.bundleIdentifier isEqualToString:identifier]) {
        return;
    }
    
    self.lastFrontmostApplication = frontmostApplication;
}

#pragma mark - Menu Actions

- (void)selectionTranslate {
    if (![self.eventMonitor checkAppIsTrusted]) {
        NSLog(@"App is not trusted");
        return;
    }
    
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    //    [self.viewController resetWithState:@"正在取词..."];
    [self.eventMonitor getSelectedTextByKey:^(NSString *_Nullable text) {
        [self ensureShowAtMouseLocation];
        if (text.length) {
            //            [self.viewController startQueryText:text];
        } else {
            //            [self.viewController resetWithState:@"划词翻译没有获取到文本" actionTitle:@"可能的原因 →" action:^{
            //                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/ripperhe/Bob#%E5%88%92%E8%AF%8D%E7%BF%BB%E8%AF%91%E8%8E%B7%E5%8F%96%E4%B8%8D%E5%88%B0%E6%96%87%E6%9C%AC"]];
            //            }];
            //            [self.viewController resetQueryViewHeightConstraint];
        }
    }];
}

- (void)snipTranslate {
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    if (!Configuration.shared.isPin && self.fixedWindow.visible) {
        [self.fixedWindow close];
        [CATransaction flush];
    }
    //    [self.viewController resetWithState:@"正在截图..."];
    [Snip.shared startWithCompletion:^(NSImage *_Nullable image) {
        NSLog(@"获取到图片 %@", image);
        // 缓存最后一张图片，统一放到 MMLogs 文件夹，方便管理
        static NSString *_imagePath = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _imagePath = [[MMManagerForLog logDirectoryWithName:@"Image"] stringByAppendingPathComponent:@"snip_image.png"];
        });
        [[NSFileManager defaultManager] removeItemAtPath:_imagePath error:nil];
        if (image) {
            [image mm_writeToFileAsPNG:_imagePath];
            NSLog(@"已保存图片\n%@", _imagePath);
            [self ensureShowAtMouseLocation];
            [self.fixedWindow.viewController startQueryImage:image];
        }
    }];
}

- (void)inputTranslate {
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    Configuration.shared.isFold = NO;
    //    [self.viewController updateFoldState:NO];
    //    [self.viewController resetWithState:@"↩︎ 翻译\n⇧ + ↩︎ 换行\n⌘ + R 重试\n⌘ + W 关闭"];
    [self ensureShowAtMouseLocation];
    [self.fixedWindow makeKeyAndOrderFront:nil];
    if (!self.fixedWindow.isKeyWindow) {
        // fail to make key window, then force activate application for key window
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (void)showMiniWindow {
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    [self.fixedWindow makeKeyAndOrderFront:nil];
    if (!self.fixedWindow.isKeyWindow) {
        // fail to make key window, then force activate application for key window
        [NSApp activateIgnoringOtherApps:YES];
    }
}

#pragma mark - Others

- (void)rerty {
    if (Snip.shared.isSnapshotting) {
        return;
    }
    if ([[NSApplication sharedApplication] keyWindow] == EZFixedQueryWindow.shared) {
        // 执行重试
        //        [self.viewController retry];
    }
}

- (void)activeLastFrontmostApplication {
    if (!self.lastFrontmostApplication.terminated) {
        [self.lastFrontmostApplication activateWithOptions:NSApplicationActivateAllWindows];
    }
    self.lastFrontmostApplication = nil;
}

@end
