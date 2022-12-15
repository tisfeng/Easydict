//
//  EZWindowManager.m
//  Easydict
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
#import "EZCoordinateTool.h"

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
        
        // !!!: Record current selected start and end point, eventMonitor's startPoint will change every valid event.
        self.startPoint = self.eventMonitor.startPoint;
        self.endPoint = self.eventMonitor.endPoint;
        
        CGPoint point = [self getPopButtonWindowLocation]; // This is top-left point
        CGPoint bottomLeftPoint = CGPointMake(point.x, point.y - self.popButtonWindow.height);
        CGPoint safePoint = [EZCoordinateTool getFrameSafePoint:self.popButtonWindow.frame moveToPoint:bottomLeftPoint];
        [self.popButtonWindow setFrameOrigin:safePoint];
        
        [self.popButtonWindow orderFrontRegardless];
        
        [self->_mainWindow orderBack:nil];
    }];
    
    [self.eventMonitor setDismissPopButtonBlock:^{
        //        NSLog(@"dismiss pop button");
        mm_strongify(self);
        [self.popButtonWindow close];
    }];
    
    [self.eventMonitor setDismissMiniWindowBlock:^{
        mm_strongify(self);
        if (!self.floatingWindow.pin) {
            [self closeFloatingWindow];
        }
    }];
    
    [self.eventMonitor setDismissFixedWindowBlock:^{
        mm_strongify(self);
        if (!self.floatingWindow.pin) {
            [self closeFloatingWindow];
        }
    }];
    
    [self.eventMonitor setDoubleCommandBlock:^{
        NSLog(@"double command");
        
        mm_strongify(self);
        [self showMiniFloatingWindow];
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
        _fixedWindow.releasedWhenClosed = NO;
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

- (EZPopButtonWindow *)popButtonWindow {
    if (!_popButtonWindow) {
        _popButtonWindow = [EZPopButtonWindow shared];
        
        mm_weakify(self);
        [_popButtonWindow.popButton setMouseEnterBlock:^(EZButton *button) {
            mm_strongify(self);
            [self.popButtonWindow close];
            
            [self showFloatingWindowType:EZWindowTypeMini atLastPoint:NO queryText:self.selectedText];
        }];
    }
    return _popButtonWindow;
}

- (EZBaseQueryWindow *)floatingWindow {
    return [self windowWithType:self.floatingWindowType];
}

#pragma mark - Others

- (EZBaseQueryWindow *)windowWithType:(EZWindowType)type {
    EZBaseQueryWindow *window;
    switch (type) {
        case EZWindowTypeMain: {
            window = _mainWindow;
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

- (CGPoint)floatingWindowLocationWithType:(EZWindowType)type {
    CGPoint location;
    switch (type) {
        case EZWindowTypeMain: {
            location = CGPointMake(100, 500);
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

/// Show floating window in fixed(new) position.
- (void)showFloatingWindowType:(EZWindowType)type queryText:(NSString *)text {
    CGPoint location = [self floatingWindowLocationWithType:type];
    EZBaseQueryWindow *window = [self windowWithType:type];
    [self showFloatingWindow:window atPoint:location];
    [window.queryViewController startQueryText:text];
}

- (void)showFloatingWindowType:(EZWindowType)type atLastPoint:(BOOL)atLastPoint queryText:(NSString *)text {
    CGPoint location = CGPointZero;
    if (atLastPoint) {
        location = [[EZLayoutManager shared] windowFrameWithType:type].origin;
    } else {
        location = [self floatingWindowLocationWithType:type];
    }
    
    EZBaseQueryWindow *window = [self windowWithType:type];
    
    if (text.length == 0) {
        [self showFloatingWindow:window atPoint:location];
    } else {
        // Reset window height first, avoid being affected by previous window height.
        [window.queryViewController resetTableView:^{
            // !!!: location is bottom-left point, we need to convert it to top-left point,
            CGPoint correctedPosition = CGPointMake(location.x, location.y - window.height);
            [self showFloatingWindow:window atPoint:correctedPosition];
            [window.queryViewController startQueryText:text];
        }];
    }
}

- (void)showFloatingWindow:(EZBaseQueryWindow *)window atPoint:(CGPoint)point {
    NSLog(@"show floating window: %@, %@", window, @(point));
    
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    // get safe window position
    CGPoint safeLocation = [EZCoordinateTool getFrameSafePoint:window.frame moveToPoint:point];
    [window setFrameOrigin:safeLocation];
    
    [window makeKeyAndOrderFront:nil];
        
    // TODO: need to optimize. we have to remove it temporary, and orderBack: when close floating window.
    [_mainWindow orderOut:nil];

    window.level = kCGUtilityWindowLevel;
    [window.queryViewController focusInputTextView];
    
    // Avoid floating windows being closed immediately.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.floatingWindowType = window.windowType;
    });
}

- (NSScreen *)getMouseLocatedScreen {
    NSPoint mouseLocation = [NSEvent mouseLocation]; // ???: self.endPoint
    
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

- (NSPoint)mouseLocation {
    NSScreen *screen = [self getMouseLocatedScreen];
#if DEBUG
    NSAssert(screen != nil, @"no screen");
#endif
    if (!screen) {
        NSLog(@"no get MouseLocation");
        return CGPointZero;
    }
    
    return [NSEvent mouseLocation];
}

// Top left position
- (CGPoint)getPopButtonWindowLocation {
    NSPoint location = [self mouseLocation];
    if (CGPointEqualToPoint(location, CGPointZero)) {
        return CGPointZero;
    }
    
    NSPoint startLocation = self.startPoint;
    NSPoint endLocation = self.endPoint;
    
    CGFloat deltaY = endLocation.y - startLocation.y;
    CGFloat x = location.x + self.offsetPoint.x;
    CGFloat y = location.y + self.offsetPoint.y;
    
    // Direction up
    if (deltaY > 10) {
        y = location.y - self.offsetPoint.y + self.popButtonWindow.height + 10;
    }
    
    NSPoint popLocation = CGPointMake(x, y);
    
    return popLocation;
}

- (CGPoint)getMiniWindowLocation {
    NSPoint popButtonLocation = [self getPopButtonWindowLocation];
    if (CGPointEqualToPoint(popButtonLocation, CGPointZero)) {
        return CGPointZero;
    }
    
    CGFloat x = popButtonLocation.x + 5; // Move slightly to the right to avoid covering the cursor.
    CGFloat y = popButtonLocation.y + 5;
    CGPoint showingPosition = CGPointMake(x, y);
    
    return showingPosition;
}

// Get fixed window location.
- (CGPoint)getFixedWindowLocation {
    CGSize mainScreenSize = NSScreen.mainScreen.frame.size;
    CGFloat x = mainScreenSize.width - self.fixedWindow.width;
    CGFloat y = NSScreen.mainScreen.visibleFrame.size.height;
    
    return CGPointMake(x, y);
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

- (void)selectTextTranslate {
    if (![self.eventMonitor checkAppIsTrusted]) {
        NSLog(@"App is not trusted");
        return;
    }
    
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    [self.eventMonitor getSelectedTextByKey:^(NSString *_Nullable text) {
        self.selectedText = text;
        [self showFloatingWindowType:EZWindowTypeFixed atLastPoint:NO queryText:text];
    }];
}

- (void)snipTranslate {
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }

    [Snip.shared startWithCompletion:^(NSImage *_Nullable image) {
        if (!image) {
            NSLog(@"not get screenshot");
            return;
        }
        
        NSLog(@"get screenshot: %@", image);

        // 缓存最后一张图片，统一放到 MMLogs 文件夹，方便管理
        static NSString *_imagePath = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _imagePath = [[MMManagerForLog logDirectoryWithName:@"Image"] stringByAppendingPathComponent:@"snip_image.png"];
        });
        [[NSFileManager defaultManager] removeItemAtPath:_imagePath error:nil];
        [image mm_writeToFileAsPNG:_imagePath];
        NSLog(@"已保存图片: %@", _imagePath);
        
        // Since ocr detect may be inaccurate, sometimes need to set sourceLanguage manually, so show Fixed window.
        EZWindowType windowType = EZWindowTypeFixed;
        EZBaseQueryWindow *window = [self windowWithType:windowType];
                    
        // Reset window height first, avoid being affected by previous window height.
        [window.queryViewController resetTableView:^{
            [self showFloatingWindowType:windowType queryText:nil];
            [window.queryViewController startQueryWithImage:image];
        }];
    }];
}

- (void)inputTranslate {
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }

    [self showFloatingWindowType:EZWindowTypeFixed atLastPoint:NO queryText:nil];
}

/// Show mini window at last positon.
- (void)showMiniFloatingWindow {
    [self showFloatingWindowType:EZWindowTypeMini atLastPoint:YES queryText:nil];
}


/// Close floating window, and record last floating window type.
- (void)closeFloatingWindow {
    NSLog(@"close floating window: %@", self.floatingWindow);
    
    self.floatingWindow.titleBar.pin = NO;
    [self.floatingWindow close];
    
    // recover last app.
    [self activeLastFrontmostApplication];
    [_mainWindow orderBack:nil];
    
    self.lastFloatingWindowType = self.floatingWindowType;
    self.floatingWindowType = EZWindowTypeMain;
}

#pragma mark - Others

- (void)rerty {
    if (Snip.shared.isSnapshotting) {
        return;
    }
    if ([[NSApplication sharedApplication] keyWindow] == EZFixedQueryWindow.shared) {
        // 执行重试
        [self.floatingWindow.queryViewController retry];
    }
}

- (void)activeLastFrontmostApplication {
    if (!self.lastFrontmostApplication.terminated) {
        [self.lastFrontmostApplication activateWithOptions:NSApplicationActivateAllWindows];
    }
    self.lastFrontmostApplication = nil;
}

@end
