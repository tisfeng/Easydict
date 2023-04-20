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
#import "EZCoordinateUtils.h"
#import "EZPreferencesWindowController.h"
#import "EZConfiguration.h"
#import "EZLog.h"

@interface EZWindowManager ()

@property (nonatomic, strong) NSRunningApplication *lastFrontmostApplication;

@property (nonatomic, strong) EZEventMonitor *eventMonitor;
@property ( nonatomic, copy, nullable) NSString *selectedText;

@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGPoint endPoint;

@property (nonatomic, copy) EZQueryType queryType;

@property (nonatomic, strong) NSMutableArray *floatingWindowTypeArray;

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
    self.offsetPoint = CGPointMake(15, -12);
    self.eventMonitor = [[EZEventMonitor alloc] init];
    [self setupEventMonitor];
    self.floatingWindowTypeArray = [NSMutableArray arrayWithArray:@[@(EZWindowTypeNone)]];
    
    NSLog(@"%@", self.floatingWindowTypeArray);
}

- (void)setupEventMonitor {
    [self.eventMonitor startMonitor];
    
    mm_weakify(self);
    [self.eventMonitor setSelectedTextBlock:^(NSString *_Nonnull selectedText) {
        mm_strongify(self);
        
        //        if ([self hasEasydictRunningInDebugMode]) {
        //            return;
        //        }
        
        self.selectedText = selectedText ?: @"";
        
        // !!!: Record current selected start and end point, eventMonitor's startPoint will change every valid event.
        self.startPoint = self.eventMonitor.startPoint;
        self.endPoint = self.eventMonitor.endPoint;
        
        CGPoint point = [self getPopButtonWindowLocation]; // This is top-left point
        CGPoint bottomLeftPoint = CGPointMake(point.x, point.y - self.popButtonWindow.height);
        CGPoint safePoint = [EZCoordinateUtils getFrameSafePoint:self.popButtonWindow.frame moveToPoint:bottomLeftPoint];
        [self.popButtonWindow setFrameOrigin:safePoint];
        
        [self.popButtonWindow orderFrontRegardless];
        // Set a high level to make sure it's always on top of other windows, such as PopClip.
        self.popButtonWindow.level = kCGScreenSaverWindowLevel;
                
        if (!EZConfiguration.shared.hideMainWindow) {
            [self->_mainWindow orderBack:nil];
        }
    }];
    
    [self updatePopButtonQueryAction];

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
        
        // TODO: Let users customize double-click shortcuts later on
#if DEBUG
        mm_strongify(self);
        [self showMiniFloatingWindow];
#endif
    }];
}

- (void)updatePopButtonQueryAction {
    mm_weakify(self);
    
    EZButton *popButton = self.popButtonWindow.popButton;
    EZConfiguration *config = [EZConfiguration shared];
    
    if (config.clickQuery && config.hideMainWindow) {
        // Disable hover
        popButton.mouseEnterBlock = nil;
        
        // FIXME: Click pop button will also show preferences window.
        [popButton setClickBlock:^(EZButton *button) {
            mm_strongify(self);
            [self popButtonWindowClicked];
        }];
    } else {
        [popButton setMouseEnterBlock:^(EZButton *button) {
            mm_strongify(self);
            [self popButtonWindowClicked];
        }];
    }
}

- (void)popButtonWindowClicked {
    [self->_popButtonWindow close];
    self.queryType = EZQueryTypeAutoSelect;
    [self showFloatingWindowType:EZWindowTypeMini queryText:self.selectedText];
}

#pragma mark - Getter

- (EZMainQueryWindow *)mainWindow {
    if (!_mainWindow) {
        _mainWindow = [EZMainQueryWindow shared];
        _mainWindow.releasedWhenClosed = NO;
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
    }
    return _popButtonWindow;
}

- (EZBaseQueryWindow *)floatingWindow {
    return [self windowWithType:self.floatingWindowType];
}

- (EZWindowType)floatingWindowType {
    return [self.floatingWindowTypeArray.firstObject integerValue];
}

#pragma mark - Others

- (EZBaseQueryWindow *)windowWithType:(EZWindowType)type {
    EZBaseQueryWindow *window = nil;
    switch (type) {
        case EZWindowTypeMain: {
            window = _mainWindow;
            break;
        }
        case EZWindowTypeFixed: {
            window = self.fixedWindow;
            break;
        }
        case EZWindowTypeMini: {
            window = self.miniWindow;
            break;
        }
        case EZWindowTypeNone: {
            break;
        }
    }
    return window;
}

/// Return top-left point.
- (CGPoint)floatingWindowLocationWithType:(EZWindowType)type {
    CGPoint location = CGPointZero;
    switch (type) {
        case EZWindowTypeMain: {
            location = CGPointMake(100, 500);
            break;
        }
        case EZWindowTypeFixed: {
            location = [self getFixedWindowLocation];
            break;
        }
        case EZWindowTypeMini: {
            location = [self getMiniWindowLocation];
            break;
        }
        case EZWindowTypeNone: {
            break;
        }
    }
    return location;
}

/// Show floating window.
- (void)showFloatingWindowType:(EZWindowType)type queryText:(nullable NSString *)text {
    //    if ([self hasEasydictRunningInDebugMode]) {
    //        return;
    //    }
    
    self.selectedText = text;
    
    EZBaseQueryWindow *window = [self windowWithType:type];
    __block CGPoint location = location = [self floatingWindowLocationWithType:type];
    
    // If text is nil, means we don't need to query anything, just show the window.
    if (!text) {
        // !!!: location is top-left point, so we need to change it to bottom-left point.
        location = CGPointMake(location.x, location.y - window.height);
        [self showFloatingWindow:window atPoint:location];
        return;
    }
    
    // Log selected text when querying.
    [self logSelectedText:text accessibility:self.eventMonitor.isSelectedTextByAuxiliary];
    
    // Reset tableView and window height first, avoid being affected by previous window height.
    
    EZBaseQueryViewController *queryViewController = window.queryViewController;
    [queryViewController resetTableView:^{
        [queryViewController updateQueryTextAndParagraphStyle:text];
        [queryViewController detectQueryText:nil];
        
        // !!!: window height has changed, so we need to update location again.
        location = CGPointMake(location.x, location.y - window.height);
        [self showFloatingWindow:window atPoint:location];
        
        if ([EZConfiguration.shared autoQuerySelectedText]) {
            [queryViewController startQueryText:text queyType:self.queryType];
        }
        
        if ([EZConfiguration.shared autoCopySelectedText]) {
            [text copyToPasteboard];
        }
    }];
}

- (void)showFloatingWindow:(EZBaseQueryWindow *)window atPoint:(CGPoint)point {
    //    NSLog(@"show floating window: %@, %@", window, @(point));
    
    [self saveFrontmostApplication];
    
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    [EZPreferencesWindowController.shared.window close];
    
    // get safe window position
    CGPoint safeLocation = [EZCoordinateUtils getFrameSafePoint:window.frame moveToPoint:point];
    [window setFrameOrigin:safeLocation];
    
    [window makeKeyAndOrderFront:nil];
    
    // FIXME: need to optimize. we have to remove it temporary, and orderBack: when close floating window.
    if (!EZConfiguration.shared.hideMainWindow) {
        [_mainWindow orderOut:nil];
    }
    
    window.level = EZFloatingWindowLevel;
    [window.queryViewController focusInputTextView];
    
    // Avoid floating windows being closed immediately.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateFloatingWindowType:window.windowType];
    
        // mainWindow has been ordered out before, so we need to order back.
        if (!EZConfiguration.shared.hideMainWindow) {
            [self->_mainWindow orderBack:nil];
        }
    });
}

- (void)updateFloatingWindowType:(EZWindowType)floatingWindowType {
    NSNumber *windowType = @(floatingWindowType);
    [self.floatingWindowTypeArray removeObject:windowType];
    [self.floatingWindowTypeArray insertObject:windowType atIndex:0];
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

/// TODO: need to optimize.
- (CGPoint)getPopButtonWindowLocation {
    NSPoint location = [self mouseLocation];
//    NSLog(@"mouseLocation: (%.1f, %.1f)", location.x, location.y);

    if (CGPointEqualToPoint(location, CGPointZero)) {
        return CGPointZero;
    }
    
    NSPoint startLocation = self.startPoint;
    NSPoint endLocation = self.endPoint;
    
    // Direction from left to right.
    BOOL isDirectionRight = endLocation.x >= startLocation.x;
    // Direction from top to bottom.
    BOOL isDirectionDown = YES;
    
    CGFloat minLineHeight = 20;
    
    CGFloat deltaY = endLocation.y - startLocation.y;
    // Direction up.
    if (deltaY > minLineHeight / 2) {
        isDirectionDown = NO;
        isDirectionRight = NO;
    }
    
    CGFloat x = location.x;
    CGFloat y = location.y;
    
    // self.offsetPoint is (15, -15)
    
    x += self.offsetPoint.x;
    y += self.offsetPoint.y;
    
    // FIXME: If adjust y when Direction is Up, it will cause some UI bugs 😢
    // TODO: This codo is too ugly, need to optimize.
    
    
//    if (isDirectionDown) {
//        x += self.offsetPoint.x;
//        y += self.offsetPoint.y;
//    } else {
//        x += self.offsetPoint.x;
//        // Direction up, show pop button window above the selected text.
//        y = location.y - self.offsetPoint.y + self.popButtonWindow.height + 5;
//    }
    
    //    CGRect selectedTextFrame = self.eventMonitor.selectedTextFrame;
    //    NSLog(@"selected text frame: %@", NSStringFromRect(selectedTextFrame));
    //    NSLog(@"start point: %@", NSStringFromPoint(startLocation));
    //    NSLog(@"end   point: %@", NSStringFromPoint(endLocation));
    
    if (EZConfiguration.shared.adjustPopButtomOrigin) {
        // Since the pop button may cover selected text, we need to move it to the left.
        CGFloat horizontalOffset = 20;
        
        x = location.x;
        if (isDirectionRight) {
            x += horizontalOffset;
        } else {
            x -= (horizontalOffset + self.popButtonWindow.width);
        }
        
        y = location.y - self.offsetPoint.y;
    }
    
    NSPoint popLocation = CGPointMake(x, y);
    //    NSLog(@"popLocation: %@", NSStringFromPoint(popLocation));
    
    return popLocation;
}

- (CGPoint)getMiniWindowLocation {
    CGPoint position = [self getShowingMouseLocation];
    if (EZConfiguration.shared.adjustPopButtomOrigin) {
        position.y = position.y - 8;
    }
    

    // If not query text, just show mini window, then show window at last position.
    if (!self.selectedText) {
        CGRect formerFrame = [EZLayoutManager.shared windowFrameWithType:EZWindowTypeMini];
        position = [EZCoordinateUtils getFrameTopLeftPoint:formerFrame];
    }

    return position;
}

- (CGPoint)getShowingMouseLocation {
    NSPoint popButtonLocation = [self getPopButtonWindowLocation];
    if (CGPointEqualToPoint(popButtonLocation, CGPointZero)) {
        return CGPointZero;
    }
    
    CGFloat x = popButtonLocation.x + 5; // Move slightly to the right to avoid covering the cursor.
    
    CGPoint mouseLocation = NSEvent.mouseLocation;
    
    // if pop button is left to selected text, we need to move showing mouse location to a bit right, to show query window properly.
    if (mouseLocation.x > popButtonLocation.x) {
        x = NSEvent.mouseLocation.x + 5;
    }
    
    CGFloat y = popButtonLocation.y + 10;
    
    CGPoint showingPosition = CGPointMake(x, y);
    
    return showingPosition;
}

/// Get fixed window location.
/// !!!: This return value is top-left point.
- (CGPoint)getFixedWindowLocation {
    CGPoint position = CGPointZero;
    EZShowWindowPosition windowPosition = EZConfiguration.shared.fixedWindowPosition;
    switch (windowPosition) {
        case EZShowWindowPositionRight: {
            CGSize mainScreenSize = NSScreen.mainScreen.frame.size;
            CGFloat x = mainScreenSize.width - self.fixedWindow.width;
            CGFloat y = NSScreen.mainScreen.visibleFrame.size.height;
            position = CGPointMake(x, y);
            break;
        }
        case EZShowWindowPositionMouse: {
            position = [self getShowingMouseLocation];
            break;
        }
        case EZShowWindowPositionFormer: {
            // !!!: origin postion is bottom-left point, we need to convert it to top-left point.
            CGRect formerFrame = [EZLayoutManager.shared windowFrameWithType:EZWindowTypeFixed];
            position = [EZCoordinateUtils getFrameTopLeftPoint:formerFrame];
            
            break;
        }
    }
    return position;
}

- (void)saveFrontmostApplication {
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    NSRunningApplication *frontmostApplication = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if ([frontmostApplication.bundleIdentifier isEqualToString:identifier]) {
        return;
    }
    
    self.lastFrontmostApplication = frontmostApplication;
}

- (void)showOrHideDockAppAndMainWindow {
    BOOL showFlag = !EZConfiguration.shared.hideMainWindow;
    _mainWindow.releasedWhenClosed = !showFlag;
    [self showMainWindow:showFlag];
    
    NSApplicationActivationPolicy activationPolicy = showFlag ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyAccessory;
    [NSApp setActivationPolicy:activationPolicy];
}

- (void)showMainWindow:(BOOL)showFlag {
    NSNumber *windowType = @(EZWindowTypeMain);
    [self.floatingWindowTypeArray removeObject:windowType];
    
    if (showFlag) {
        [self.floatingWindowTypeArray insertObject:windowType atIndex:0];

        EZMainQueryWindow *mainWindow = [EZWindowManager shared].mainWindow;
        [mainWindow center];
        [mainWindow makeKeyAndOrderFront:nil];

    } else {
        // TODO: may be need to release main window to reduce memory, if user do need main window anymore.
        [_mainWindow close];
        [self.floatingWindowTypeArray insertObject:windowType atIndex:1];
    }
}

#pragma mark - Menu Actions

- (void)selectTextTranslate {
    if (![self.eventMonitor isAccessibilityTrusted]) {
        NSLog(@"App is not trusted");
        return;
    }
    
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    [self.eventMonitor getSelectedText:^(NSString *_Nullable text) {
        self.selectedText = [text trim];
        self.queryType = self.eventMonitor.isSelectedTextByAuxiliary ? EZQueryTypeAutoSelect : EZQueryTypeShortcut;
        [self showFloatingWindowType:EZWindowTypeFixed queryText:self.selectedText];
    }];
}

- (void)snipTranslate {
    //    if ([self hasEasydictRunningInDebugMode]) {
    //        return;
    //    }
    
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
    
    self.queryType = EZQueryTypeInput;
    [self showFloatingWindowType:EZWindowTypeFixed queryText:nil];
}

/// Show mini window at last positon.
- (void)showMiniFloatingWindow {
    self.queryType = EZQueryTypeInput;
    [self showFloatingWindowType:EZWindowTypeMini queryText:nil];
}


/// Close floating window, and record last floating window type.
- (void)closeFloatingWindow {
    //    NSLog(@"close floating window: %@", self.floatingWindow);
    
    self.floatingWindow.titleBar.pin = NO;
    [self.floatingWindow close];
    
    if (![EZPreferencesWindowController.shared isShowing]) {
        // recover last app.
        [self activeLastFrontmostApplication];
    }

    [_mainWindow orderBack:nil];
        
    // Move floating window type to second.
    
    NSNumber *windowType = @(self.floatingWindowType);
    [self.floatingWindowTypeArray removeObject:windowType];
    [self.floatingWindowTypeArray insertObject:windowType atIndex:1];
}

/// Close floating window, except main window.
- (void)closeFloatingWindowExceptMain {
    // Do not close main window
    if (!self.floatingWindow.pin && self.floatingWindow.windowType != EZWindowTypeMain) {
        [[EZWindowManager shared] closeFloatingWindow];
    }
}

#pragma mark - Shortcut

- (void)rerty {
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    if ([[NSApplication sharedApplication] keyWindow] == self.floatingWindow) {
        // 执行重试
        [self.floatingWindow.queryViewController retryQuery];
    }
}

- (void)clearInput {
    NSLog(@"Clear input");
    
    [self.floatingWindow.queryViewController clearInput];
}

- (void)clearAll {
    NSLog(@"Clear All");
    
    [self.floatingWindow.queryViewController clearAll];
}

- (void)pin {
    NSLog(@"Pin");
    
    EZBaseQueryWindow *queryWindow = EZWindowManager.shared.floatingWindow;
    queryWindow.titleBar.pin = !queryWindow.titleBar.pin;
}

- (void)hide {
    NSLog(@"Close window");
    if (Snip.shared.isSnapshotting) {
        [Snip.shared stop];
    } else {
        [EZWindowManager.shared closeFloatingWindow];
        [EZPreferencesWindowController.shared close];
    }
}

- (void)closeWindow {
    NSLog(@"Close window");
    if (Snip.shared.isSnapshotting) {
        [Snip.shared stop];
    } else {
        [EZWindowManager.shared closeFloatingWindow];
        [EZPreferencesWindowController.shared close];
    }
}

- (void)toggleTranslationLanguages {
    [self.floatingWindow.queryViewController toggleTranslationLanguages];
}

- (void)focusInputTextView {
    [self.floatingWindow.queryViewController focusInputTextView];
}

- (void)playQueryTextSound {
    [self.floatingWindow.queryViewController playQueryTextSound];
}

#pragma mark -

- (void)activeLastFrontmostApplication {
    if (!self.lastFrontmostApplication.terminated) {
        [self.lastFrontmostApplication activateWithOptions:NSApplicationActivateAllWindows];
    }
    self.lastFrontmostApplication = nil;
}

/// For easy debugging, when Easydict is running in debug mode, we don't show Easydict release App.
- (BOOL)hasEasydictRunningInDebugMode {
    BOOL isDebugRunning = [self isAppRunningWithBundleId:EZDebugBundleId];
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    BOOL isReleasedEasydict = [bundleId isEqualToString:EZBundleId];
    if (isDebugRunning && isReleasedEasydict) {
        NSLog(@"Easydict is running in debug mode, so do not show release App.");
        return YES;
    }
    return NO;
}

/// Check app is running with bundleID.
- (BOOL)isAppRunningWithBundleId:(NSString *)bundleID {
    NSArray *runningApps = [NSWorkspace sharedWorkspace].runningApplications;
    for (NSRunningApplication *app in runningApps) {
        if ([app.bundleIdentifier isEqualToString:bundleID]) {
            return YES;
        }
    }
    return NO;
}

- (void)logSelectedText:(nullable NSString *)text accessibility:(BOOL)accessibilityFlag {
    if (!text) {
        return;
    }
    
    NSRunningApplication *application = NSWorkspace.sharedWorkspace.frontmostApplication;
    NSString *appName = application.localizedName;
    NSString *bundleID = application.bundleIdentifier;
    NSString *textLength = [EZLog textLengthRange:text];
    NSString *type = accessibilityFlag ? @"auxiliary" : @"shortcut";
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
        @"text" : text,
        @"type" : type,
        @"textLength" : textLength,
        @"appName" : appName,
        @"bundleID" : bundleID,
    }];
    
    [EZLog logEventWithName:@"getSelectedText" parameters:dict];
}

@end
