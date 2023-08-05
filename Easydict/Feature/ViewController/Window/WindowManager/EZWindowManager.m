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

/// the screen where the mouse is located
@property (nonatomic, strong) NSScreen *screen;

@property (nonatomic, copy) EZActionType actionType;

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
    self.offsetPoint = CGPointMake(18, -12);
    self.screen = NSScreen.mainScreen;
    self.floatingWindowTypeArray = [NSMutableArray arrayWithArray:@[@(EZWindowTypeNone)]];
    self.actionType = EZActionTypeAutoSelectQuery;
    
    self.eventMonitor = [[EZEventMonitor alloc] init];
    [self setupEventMonitor];
    
    //    NSLog(@"%@", self.floatingWindowTypeArray);
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
        self.actionType = self.eventMonitor.actionType;
        
        // !!!: Record current selected start and end point, eventMonitor's startPoint will change every valid event.
        self.startPoint = self.eventMonitor.startPoint;
        self.endPoint = self.eventMonitor.endPoint;
        
        CGPoint point = [self getPopButtonWindowLocation]; // This is top-left point
        CGPoint bottomLeftPoint = CGPointMake(point.x, point.y - self.popButtonWindow.height);
        CGPoint safePoint = [EZCoordinateUtils getFrameSafePoint:self.popButtonWindow.frame moveToPoint:bottomLeftPoint inScreen:self.screen];
        [self.popButtonWindow setFrameOrigin:safePoint];
        
        [self.popButtonWindow orderFrontRegardless];
        // Set a high level to make sure it's always on top of other windows, such as PopClip.
        self.popButtonWindow.level = kCGScreenSaverWindowLevel;
        
        if ([EZMainQueryWindow isAlive]) {
            [self.mainWindow orderBack:nil];
        }
    }];
    
    [self updatePopButtonQueryAction];
    
    [self.eventMonitor setMouseClickBlock:^(CGPoint clickPoint) {
        mm_strongify(self);
        self.startPoint = clickPoint;
        self.screen = [EZCoordinateUtils screenForPoint:clickPoint];
        EZLayoutManager.shared.screen = self.screen;
    }];
    
    [self.eventMonitor setDismissPopButtonBlock:^{
        mm_strongify(self);
//        NSLog(@"dismiss pop button");
        [self.popButtonWindow close];
    }];
    
    [self.eventMonitor setDismissMiniWindowBlock:^{
        mm_strongify(self);
        if (!self.floatingWindow.pin && self.floatingWindow.visible) {
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


/// Update pop button query action.
- (void)updatePopButtonQueryAction {
    mm_weakify(self);
    
    EZButton *popButton = self.popButtonWindow.popButton;
    EZConfiguration *config = [EZConfiguration shared];
    
    if (config.hideMainWindow) {
        // FIXME: Click pop button will also show preferences window.
        [popButton setClickBlock:^(EZButton *button) {
            mm_strongify(self);
            [self popButtonWindowClicked];
        }];
        
        if (config.clickQuery) {
            popButton.mouseEnterBlock = nil;
        } else {
            [popButton setMouseEnterBlock:^(EZButton *button) {
                mm_strongify(self);
                [self popButtonWindowClicked];
            }];
        }
    } else {
        popButton.clickBlock = nil;
        
        [popButton setMouseEnterBlock:^(EZButton *button) {
            mm_strongify(self);
            [self popButtonWindowClicked];
        }];
    }
}

- (void)popButtonWindowClicked {
    self.actionType = EZActionTypeAutoSelectQuery;
    [self showFloatingWindowType:EZWindowTypeMini queryText:self.selectedText];
    [self->_popButtonWindow close];
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
    }
    return _popButtonWindow;
}

- (EZBaseQueryWindow *)floatingWindow {
    return [self windowWithType:self.floatingWindowType];
}

- (EZWindowType)floatingWindowType {
    return [self.floatingWindowTypeArray.firstObject integerValue];
}

- (EZBaseQueryViewController *)backgroundQueryViewController {
    if (!_backgroundQueryViewController) {
        _backgroundQueryViewController = [[EZBaseQueryViewController alloc] init];
    }
    return _backgroundQueryViewController;
}


#pragma mark - Others

- (nullable EZBaseQueryWindow *)windowWithType:(EZWindowType)type {
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
    [self logSelectedTextEvent];
    
    // Reset tableView and window height first, avoid being affected by previous window height.
    
    EZBaseQueryViewController *queryViewController = window.queryViewController;
    [queryViewController resetTableView:^{
        [queryViewController updateQueryTextAndParagraphStyle:text actionType:self.actionType];
        [queryViewController detectQueryText:nil];
        
        // !!!: window height has changed, so we need to update location again.
        location = CGPointMake(location.x, location.y - window.height);
        [self showFloatingWindow:window atPoint:location];
        
        if ([EZConfiguration.shared autoQuerySelectedText]) {
            [queryViewController startQueryText:text actionType:self.actionType];
        }
        
        if ([EZConfiguration.shared autoCopySelectedText]) {
            [text copyToPasteboard];
        }
    }];
}

- (void)detectQueryText:(NSString *)text completion:(nullable void (^)(NSString *language))completion {
    EZBaseQueryViewController *viewController = [EZWindowManager.shared backgroundQueryViewController];
    viewController.inputText = text;
    [viewController detectQueryText:completion];
}

- (void)showFloatingWindow:(EZBaseQueryWindow *)window atPoint:(CGPoint)point {
    //    NSLog(@"show floating window: %@, %@", window, @(point));
    
    [self saveFrontmostApplication];
    
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    EZPreferencesWindowController *preferencesWindowController = [EZPreferencesWindowController shared];
    if (preferencesWindowController.isShowing) {
        [preferencesWindowController.window close];
    }
    
    // get safe window position
    CGPoint safeLocation = [EZCoordinateUtils getFrameSafePoint:window.frame moveToPoint:point inScreen:self.screen];
    [window setFrameOrigin:safeLocation];
    window.level = EZFloatingWindowLevel;
    
    // FIXME: need to optimize. we have to remove it temporary, and orderBack: when close floating window.
    if ([EZMainQueryWindow isAlive]) {
        [self.mainWindow orderOut:nil];
    }
            
//    NSLog(@"window frame: %@", @(window.frame));

    // ???: This code will cause warning: [Window] Warning: Window EZFixedQueryWindow 0x107f04db0 ordered front from a non-active application and may order beneath the active application's windows.
    [window makeKeyAndOrderFront:nil];
    
    /// ???: orderFrontRegardless will cause OCR show blank window when window has shown.
    //    [window orderFrontRegardless];
    
    // !!!: Focus input textView should behind makeKeyAndOrderFront:, otherwise it will not work in the first time.
    [window.queryViewController focusInputTextView];
    
    [self updateFloatingWindowType:window.windowType];
    
    // mainWindow has been ordered out before, so we need to order back.
    if ([EZMainQueryWindow isAlive]) {
        [self.mainWindow orderBack:nil];
    }
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


/// TODO: need to optimize.
- (CGPoint)getPopButtonWindowLocation {
    NSPoint location = [NSEvent mouseLocation];
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
    BOOL offsetFlag = self.popButtonWindow.isVisible;
    return [self getMouseLocation:offsetFlag];;
}

- (CGPoint)getMouseLocation:(BOOL)offsetFlag {
    NSPoint popButtonLocation = [self getPopButtonWindowLocation];
    if (CGPointEqualToPoint(popButtonLocation, CGPointZero)) {
        return CGPointZero;
    }
    
    CGPoint mouseLocation = NSEvent.mouseLocation;
    CGPoint showingPosition = mouseLocation;
    
    if (offsetFlag) {
        CGFloat x = popButtonLocation.x + 5; // Move slightly to the right to avoid covering the cursor.
        
        
        // if pop button is left to selected text, we need to move showing mouse location to a bit right, to show query window properly.
        if (mouseLocation.x > popButtonLocation.x) {
            x = NSEvent.mouseLocation.x + 5;
        }
        
        CGFloat y = popButtonLocation.y + 0;
        
        showingPosition = CGPointMake(x, y);
    }
    
    return showingPosition;
}

/// Get fixed window location.
/// !!!: This return value is top-left point.
- (CGPoint)getFixedWindowLocation {
    CGPoint position = CGPointZero;
    EZShowWindowPosition windowPosition = EZConfiguration.shared.fixedWindowPosition;
    switch (windowPosition) {
        case EZShowWindowPositionRight: {
            position = [self getFloatingWindowInRightSideOfScreenPoint:self.fixedWindow];
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
        case EZShowWindowPositionCenter: {
            position = [self getFloatingWindowInCenterOfScreenPoint:self.fixedWindow];
            break;
        }
    }
    return position;
}

- (CGPoint)getFloatingWindowInRightSideOfScreenPoint:(NSWindow *)floatingWindow {
    CGPoint position = CGPointZero;
    
    NSScreen *targetScreen = self.screen;
    NSRect screenRect = [targetScreen visibleFrame];
    
    CGFloat x = screenRect.origin.x + screenRect.size.width - floatingWindow.width;
    CGFloat y = screenRect.origin.y + screenRect.size.height;
    position = CGPointMake(x, y);
    
    return position;
}

/// Get the position of floatingWindow that make sure floatingWindow show in the center of self.screen.
- (CGPoint)getFloatingWindowInCenterOfScreenPoint:(NSWindow *)floatingWindow {
    CGPoint position = CGPointZero;
    
    NSScreen *targetScreen = self.screen;
    NSRect screenRect = [targetScreen visibleFrame];
    
    // top-left point
    CGFloat x = screenRect.origin.x + (screenRect.size.width - floatingWindow.width) / 2;
    CGFloat y = screenRect.origin.y + (screenRect.size.height - floatingWindow.height) / 2 + floatingWindow.height;
    position = CGPointMake(x, y);
    
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

- (void)showMainWindowIfNedded {
    BOOL showFlag = !EZConfiguration.shared.hideMainWindow;
    NSApplicationActivationPolicy activationPolicy = showFlag ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyAccessory;
    [NSApp setActivationPolicy:activationPolicy];
    
    if (showFlag) {
        [self.floatingWindowTypeArray insertObject:@(EZWindowTypeMain) atIndex:0];

        EZMainQueryWindow *mainWindow = [EZWindowManager shared].mainWindow;
        [mainWindow center];
        [mainWindow makeKeyAndOrderFront:nil];
    }
}

- (void)closeMainWindowIfNeeded {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    
    [self.floatingWindowTypeArray removeObject:@(EZWindowTypeMain)];

    if ([EZMainQueryWindow isAlive]) {
        [EZMainQueryWindow destroySharedInstance];
    }
}

#pragma mark - Menu Actions, Global Shortcut

- (void)selectTextTranslate {
    MMLogInfo(@"selectTextTranslate");

    if (![self.eventMonitor isAccessibilityEnabled]) {
        NSLog(@"App is not trusted");
        return;
    }
    
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    self.eventMonitor.actionType = EZActionTypeShortcutQuery;
    [self.eventMonitor getSelectedText:^(NSString *_Nullable text) {
        // If text is nil, currently, we choose to clear input.
        self.selectedText = [text trim] ?: @"";
        self.actionType = self.eventMonitor.actionType;
        [self showFloatingWindowType:EZWindowTypeFixed queryText:self.selectedText];
    }];
}

- (void)snipTranslate {
    MMLogInfo(@"snipTranslate");

    //    if ([self hasEasydictRunningInDebugMode]) {
    //        return;
    //    }
    
    [self saveFrontmostApplication];
    
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    // Since ocr detect may be inaccurate, sometimes need to set sourceLanguage manually, so show Fixed window.
    EZWindowType windowType = EZWindowTypeFixed;
    EZBaseQueryWindow *window = [self windowWithType:windowType];
    
    // FIX https://github.com/tisfeng/Easydict/issues/126
    if (!self.floatingWindow.pin) {
        [self closeFloatingWindow];
    }
    
    // Wait to close floating window if need.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
            
            // Reset window height first, avoid being affected by previous window height.
            [window.queryViewController resetTableView:^{
                [self showFloatingWindowType:windowType queryText:nil];
                [window.queryViewController startOCRImage:image actionType:EZActionTypeOCRQuery];
            }];
        }];
    });
}

- (void)inputTranslate {
    MMLogInfo(@"inputTranslate");
    
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    EZWindowType windowType = EZWindowTypeFixed;
    if (self.floatingWindowType == windowType) {
        [self closeFloatingWindow];
        return;
    }
    
    NSString *queryText = nil;
    if ([EZConfiguration.shared clearInput]) {
        queryText = @"";
    }
    
    self.actionType = EZActionTypeInputQuery;
    [self showFloatingWindowType:windowType queryText:queryText];
}

/// Show mini window at last positon.
- (void)showMiniFloatingWindow {
    MMLogInfo(@"showMiniFloatingWindow");

    EZWindowType windowType = EZWindowTypeMini;
    if (self.floatingWindowType == windowType) {
        [self closeFloatingWindow];
        return;
    }
    
    self.actionType = EZActionTypeInputQuery;
    [self showFloatingWindowType:windowType queryText:nil];
}

- (void)screenshotOCR {
    MMLogInfo(@"screenshotOCR");

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
        
        [self.backgroundQueryViewController startOCRImage:image actionType:EZActionTypeScreenshotOCR];
    }];
}

#pragma mark - Application Shorcut

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

- (void)copyQueryText {
    [self.floatingWindow.queryViewController copyQueryText];
}

- (void)copyFirstTranslatedText {
    [self.floatingWindow.queryViewController copyFirstTranslatedText];
}

- (void)pin {
    NSLog(@"Pin");
    
    EZBaseQueryWindow *queryWindow = EZWindowManager.shared.floatingWindow;
    queryWindow.titleBar.pin = !queryWindow.titleBar.pin;
}

- (void)closeWindowOrExitSreenshot {
    NSLog(@"Close window, or exit screenshot");
    
    if (Snip.shared.isSnapshotting) {
        [Snip.shared stop];
    } else {
        if (self.floatingWindow) {
            [EZWindowManager.shared closeFloatingWindow];
        }
        [EZPreferencesWindowController.shared close];
    }
}

- (void)toggleTranslationLanguages {
    [self.floatingWindow.queryViewController toggleTranslationLanguages];
}

- (void)focusInputTextView {
    [self.floatingWindow.queryViewController focusInputTextView];
}

- (void)playOrStopQueryTextAudio {
    [self.floatingWindow.queryViewController playOrStopQueryTextAudio];
}


#pragma mark -

/// Close floating window, and record last floating window type.
- (void)closeFloatingWindow {
    NSLog(@"close floating window: %@", self.floatingWindow);
    
    if (!self.floatingWindow) {
        return;
    }
    
    // stop playing audio
    [self.floatingWindow.queryViewController stopPlayingAudio];
    
    self.floatingWindow.titleBar.pin = NO;
    [self.floatingWindow close];
    
    if (![EZPreferencesWindowController.shared isShowing]) {
        // recover last app.
        [self activeLastFrontmostApplication];
    }
    
    if ([EZMainQueryWindow isAlive]) {
        [self.mainWindow orderBack:nil];
    }
    
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

- (void)logSelectedTextEvent {
    NSString *text = self.selectedText;
    
    if (!text) {
        return;
    }
    
    NSRunningApplication *application = self.eventMonitor.frontmostApplication;
    NSString *appName = application.localizedName;
    NSString *bundleID = application.bundleIdentifier;
    NSString *textLength = [EZLog textLengthRange:text];
    NSString *triggerType = [EZEnumTypes stringValueOfTriggerType:self.eventMonitor.triggerType];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
        @"actionType" : self.actionType,
        @"selectTextType" : self.eventMonitor.selectTextType,
        @"triggerType" : triggerType,
        @"textLength" : textLength,
        @"appName" : appName,
        @"bundleID" : bundleID,
    }];
    
    NSString *browserTabURLString = self.eventMonitor.browserTabURLString;
    if (browserTabURLString.length) {
        NSURL *tabURL = [NSURL URLWithString:browserTabURLString];
        NSString *host = tabURL.host ?: browserTabURLString;
        dict[@"host"] = host;
    }
    
    [EZLog logEventWithName:@"getSelectedText" parameters:dict];
}

@end
