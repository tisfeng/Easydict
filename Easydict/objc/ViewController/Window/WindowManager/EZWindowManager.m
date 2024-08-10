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
#import "EZLog.h"

@interface EZWindowManager ()

@property (nonatomic, strong) NSRunningApplication *lastFrontmostApplication;

@property (nonatomic, strong) EZEventMonitor *eventMonitor;
@property (nonatomic, copy, nullable) NSString *selectedText;

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
    self.floatingWindowTypeArray = [NSMutableArray arrayWithArray:@[ @(EZWindowTypeNone) ]];
    self.actionType = EZActionTypeInvokeQuery;
    
    self.eventMonitor = [EZEventMonitor shared];
    [self setupEventMonitor];
}

- (void)setupEventMonitor {
    [self.eventMonitor startMonitor];
    
    mm_weakify(self);
    [self.eventMonitor setSelectedTextBlock:^(NSString *_Nonnull selectedText) {
        mm_strongify(self);
        
//        MMLogInfo(@"auto get selected text successfully: %@", selectedText.truncated);
        
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
    }];
    
    [self updatePopButtonQueryAction];
    
    [self.eventMonitor setLeftMouseDownBlock:^(CGPoint clickPoint) {
        mm_strongify(self);
        self.startPoint = clickPoint;
        self.screen = [EZCoordinateUtils screenForPoint:clickPoint];
        EZLayoutManager.shared.screen = self.screen;
    }];
    
    [self.eventMonitor setRightMouseDownBlock:^(CGPoint clickPoint) {
        mm_strongify(self);
        self.screen = [EZCoordinateUtils screenForPoint:clickPoint];
        EZLayoutManager.shared.screen = self.screen;
    }];
    
    [self.eventMonitor setDismissPopButtonBlock:^{
        mm_strongify(self);
        [self.popButtonWindow close];
    }];
    
    [self.eventMonitor setDismissAllNotPinndFloatingWindowBlock:^{
        mm_strongify(self);
        if (self->_miniWindow) {
            [self closeFloatingWindowIfNotPinnedOrMain:EZWindowTypeMini];
        }
        if (self->_fixedWindow) {
            [self closeFloatingWindowIfNotPinnedOrMain:EZWindowTypeFixed];
        }
    }];
    
    [self.eventMonitor setDoubleCommandBlock:^{
        NSLog(@"double command block");
    }];
}


/// Update pop button query action.
- (void)updatePopButtonQueryAction {
    mm_weakify(self);
    
    EZButton *popButton = self.popButtonWindow.popButton;
    Configuration *config = [Configuration shared];
    
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
    EZWindowType windowType = Configuration.shared.mouseSelectTranslateWindowType;
    self.actionType = EZActionTypeAutoSelectQuery;
    [self showFloatingWindowType:windowType queryText:self.selectedText];
    [self->_popButtonWindow close];
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

- (nullable EZBaseQueryWindow *)floatingWindow {
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
- (void)showFloatingWindowType:(EZWindowType)windowType queryText:(nullable NSString *)queryText {
    [self showFloatingWindowType:windowType queryText:queryText actionType:self.actionType];
}

- (void)showFloatingWindowType:(EZWindowType)windowType
                     queryText:(nullable NSString *)queryText
                    actionType:(EZActionType)actionType {
    BOOL autoQuery = [Configuration.shared autoQuerySelectedText];
    [self showFloatingWindowType:windowType queryText:queryText autoQuery:autoQuery actionType:actionType];
}

- (void)showFloatingWindowType:(EZWindowType)windowType
                     queryText:(nullable NSString *)queryText
                     autoQuery:(BOOL)autoQuery
                    actionType:(EZActionType)actionType {
    CGPoint point = [self floatingWindowLocationWithType:windowType];
    [self showFloatingWindowType:windowType queryText:queryText autoQuery:autoQuery actionType:actionType atPoint:point completionHandler:nil];
}

- (void)showFloatingWindowType:(EZWindowType)windowType
                     queryText:(nullable NSString *)queryText
                    actionType:(EZActionType)actionType
                       atPoint:(CGPoint)point
             completionHandler:(nullable void (^)(void))completionHandler {
    BOOL autoQuery = [Configuration.shared autoQuerySelectedText];
    [self showFloatingWindowType:windowType queryText:queryText autoQuery:autoQuery actionType:actionType atPoint:point completionHandler:completionHandler];
}

- (void)showFloatingWindowType:(EZWindowType)windowType
                     queryText:(nullable NSString *)queryText
                     autoQuery:(BOOL)autoQuery
                    actionType:(EZActionType)actionType
                       atPoint:(CGPoint)point
             completionHandler:(nullable void (^)(void))completionHandler {
    self.selectedText = queryText;
    self.actionType = actionType;
    
    MMLogInfo(@"show floating windowType: %ld, queryText: %@, autoQuery: %d, actionType: %@, atPoint: %@", windowType, queryText, autoQuery, actionType, @(point));
    
    // Update isTextEditable value when using invoke query, such as open URL Scheme by PopClip.
    if (actionType == EZActionTypeInvokeQuery) {
        [self.eventMonitor updateSelectedTextEditableState];
    }
    
    EZBaseQueryWindow *window = [self windowWithType:windowType];

    // If window is pinned now, we don't need to change it
    if (!window.pin) {
        window.pin = Configuration.shared.pinWindowWhenDisplayed;
    }

    EZBaseQueryViewController *queryViewController = window.queryViewController;

    // If text is nil, means we don't need to query anything, just show the window.
    if (!queryText) {
        /**
         In some applications, in extreme cases, using shortcut to get the text fails causing text is nil, in which case we display a tips view.
         
         https://github.com/tisfeng/Easydict/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E4%B8%BA%E4%BB%80%E4%B9%88%E5%9C%A8%E6%9F%90%E4%BA%9B%E5%BA%94%E7%94%A8%E4%B8%AD%E5%8F%96%E8%AF%8D%E6%96%87%E6%9C%AC%E4%B8%BA%E7%A9%BA
         */
        if (!Configuration.shared.disableTipsView && actionType == EZActionTypeShortcutQuery) {
            [queryViewController showTipsView:YES];
        }
        
        // !!!: location is top-left point, so we need to change it to bottom-left point.
        CGPoint newPoint = CGPointMake(point.x, point.y - window.height);
        [queryViewController updateActionType:self.actionType];
        [self showFloatingWindow:window atPoint:newPoint];
        
        if (completionHandler) {
            completionHandler();
        }
        
        return;
    }
    
    // Log selected text when querying.
    [self logSelectedTextEvent];
    
    void (^updateQueryTextAndStartQueryBlock)(BOOL) = ^(BOOL needFocus) {
        // Update input text and detect.
        [queryViewController updateQueryTextAndParagraphStyle:queryText actionType:self.actionType];
        [queryViewController detectQueryText:nil];
        
        if (needFocus) {
            // Order front and focus floating window.
            [self orderFrontWindowAndFocusInputTextView:window];
        }
        
        if (autoQuery) {
            [queryViewController startQueryText:queryText actionType:self.actionType];
        }
        
        // TODO: Maybe we should remove this option, it seems useless.
        if ([Configuration.shared autoCopySelectedText]) {
            [queryText copyToPasteboard];
        }
        
        if (completionHandler) {
            completionHandler();
        }
    };
    
    if (!window.isPin) {
        // Reset tableView and window height first, avoid being affected by previous window height.
        [queryViewController resetTableView:^{
            // !!!: window height has changed, so we need to update location again.
            CGPoint newPoint = CGPointMake(point.x, point.y - window.height);
            [queryViewController updateActionType:self.actionType];
            [self showFloatingWindow:window atPoint:newPoint];
            updateQueryTextAndStartQueryBlock(NO);
        }];
    } else {
        // If window is pinned, we don't need to reset tableView.
        updateQueryTextAndStartQueryBlock(YES);
    }
}

- (void)orderFrontWindowAndFocusInputTextView:(EZBaseQueryWindow *)window {
    [self saveFrontmostApplication];
    
    // Focus floating window.
    [window makeKeyAndOrderFront:nil];
    [window.queryViewController focusInputTextView];
}

- (void)detectQueryText:(NSString *)text completion:(nullable void (^)(NSString *language))completion {
    EZBaseQueryViewController *viewController = [self backgroundQueryViewController];
    viewController.inputText = text;
    [viewController detectQueryText:completion];
}

- (void)showFloatingWindow:(EZBaseQueryWindow *)window atPoint:(CGPoint)point {
    //    MMLogInfo(@"show floating window: %@, %@", window, @(point));
    
    [self saveFrontmostApplication];
    
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    [[self currentShowingSettingsWindow] close];
    
    // get safe window position
    CGPoint safeLocation = [EZCoordinateUtils getFrameSafePoint:window.frame moveToPoint:point inScreen:self.screen];
    [window setFrameOrigin:safeLocation];
    window.level = EZFloatingWindowLevel;
    
    // FIXME: need to optimize. We have to remove main window temporarily, and `orderBack:` when closed floating window.
    // But `orderBack:` will cause the query window to fail to display in stage manager mode (#385)

    if ([EZMainQueryWindow isAlive]) {
        [_mainWindow orderOut:nil];
    }
    
    //    MMLogInfo(@"window frame: %@", @(window.frame));
    
    // ???: This code will cause warning: [Window] Warning: Window EZFixedQueryWindow 0x107f04db0 ordered front from a non-active application and may order beneath the active application's windows.
    [window makeKeyAndOrderFront:nil];
    
    /// ???: orderFrontRegardless will cause OCR show blank window when window has shown.
    //    [window orderFrontRegardless];
    
    // !!!: Focus input textView should behind makeKeyAndOrderFront:, otherwise it will not work in the first time.
    [window.queryViewController focusInputTextView];
    
    [self updateFloatingWindowType:window.windowType isShowing:YES];
}

- (nullable NSWindow *)currentShowingSettingsWindow {
    // Workaround for SwiftUI Settings window, fix https://github.com/tisfeng/Easydict/issues/362
    for (NSWindow *window in [NSApp windows]) {
        if ([window.identifier isEqualToString:@"com_apple_SwiftUI_Settings_window"] && window.visible) {
            return window;
        }
    }
    
    return nil;
}

- (void)updateFloatingWindowType:(EZWindowType)floatingWindowType isShowing:(BOOL)isShowing {
    NSNumber *windowType = @(floatingWindowType);
//    MMLogInfo(@"update windowType: %@, isShowing: %d", windowType, isShowing);
//    MMLogInfo(@"before floatingWindowTypeArray: %@", self.floatingWindowTypeArray);

    [self.floatingWindowTypeArray removeObject:windowType];
    [self.floatingWindowTypeArray insertObject:windowType atIndex:isShowing ? 0 : 1];
    
//    MMLogInfo(@"after floatingWindowTypeArray: %@", self.floatingWindowTypeArray);
}

- (void)updateWindowsTitlebarButtonsToolTip {
    [_mainWindow.titleBar updateShortcutButtonsToolTip];
    [_miniWindow.titleBar updateShortcutButtonsToolTip];
    [_fixedWindow.titleBar updateShortcutButtonsToolTip];
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
//    MMLogInfo(@"mouseLocation: (%.1f, %.1f)", location.x, location.y);
    
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
    //    MMLogInfo(@"selected text frame: %@", NSStringFromRect(selectedTextFrame));
    //    MMLogInfo(@"start point: %@", NSStringFromPoint(startLocation));
    //    MMLogInfo(@"end   point: %@", NSStringFromPoint(endLocation));
    
    if (Configuration.shared.adjustPopButtomOrigin) {
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
//    MMLogInfo(@"popLocation: %@", NSStringFromPoint(popLocation));
    
    return popLocation;
}

- (CGPoint)getMiniWindowLocation {
    CGPoint position = [self getShowingMouseLocation];
    if (Configuration.shared.adjustPopButtomOrigin) {
        position.y = position.y - 8;
    }
    
    // If input query, just show mini window, then show window at last position.
    if (self.actionType == EZActionTypeInputQuery) {
        CGRect formerFrame = [EZLayoutManager.shared windowFrameWithType:EZWindowTypeMini];
        position = [EZCoordinateUtils getFrameTopLeftPoint:formerFrame];
    }
    
    return position;
}

- (CGPoint)getShowingMouseLocation {
    BOOL offsetFlag = self.popButtonWindow.isVisible;
    return [self getMouseLocation:offsetFlag];
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
    EZShowWindowPosition windowPosition = Configuration.shared.fixedWindowPosition;
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

- (void)showMainWindowIfNeeded {
    BOOL showFlag = !Configuration.shared.hideMainWindow;
    NSApplicationActivationPolicy activationPolicy = showFlag ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyAccessory;
    [NSApp setActivationPolicy:activationPolicy];
    
    if (showFlag) {
        // If the main window does not exist, create it first, and show it center.
        if (!_mainWindow) {
            [self.mainWindow center];
        }
        [self.mainWindow makeKeyAndOrderFront:nil];
        [self.floatingWindowTypeArray insertObject:@(EZWindowTypeMain) atIndex:0];
        
        // TODO: We should record main window showing position, like mini window.
//        [self showFloatingWindowType:EZWindowTypeMain queryText:nil];
    }
}

- (void)destroyMainWindow {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    
    [self.floatingWindowTypeArray removeObject:@(EZWindowTypeMain)];
    
    if ([EZMainQueryWindow isAlive]) {
        [EZMainQueryWindow destroySharedInstance];
        _mainWindow = nil;
    }
}

#pragma mark - Menu Actions, Global Shortcut

- (void)selectTextTranslate {
    MMLogInfo(@"selectTextTranslate");
    
    if (![self.eventMonitor isAccessibilityEnabled]) {
        MMLogWarn(@"App is not trusted");
        return;
    }
    
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    EZWindowType windowType = Configuration.shared.shortcutSelectTranslateWindowType;
    MMLogInfo(@"selectTextTranslate windowType: %@", @(windowType));
    self.eventMonitor.actionType = EZActionTypeShortcutQuery;
    [self.eventMonitor getSelectedText:^(NSString *_Nullable text) {
        self.actionType = self.eventMonitor.actionType;
        
        /**
         Clear query if text is nil and user don't want to keep the last result.
         
         !!!: text may be @"" when no selected text in Chrome, so we need to handle it.
         */
        if (text.length == 0) {
            text = Configuration.shared.keepPrevResultWhenEmpty ? nil : @"";
        }
        self.selectedText = [text trim];
        
        [self showFloatingWindowType:windowType queryText:self.selectedText];
    }];
}

- (void)snipTranslate {
    MMLogInfo(@"snipTranslate");
    
    [self saveFrontmostApplication];
    
    if (Snip.shared.isSnapshotting) {
        return;
    }
    
    // Close non-main floating window if not pinned. Fix https://github.com/tisfeng/Easydict/issues/126
    [self closeFloatingWindowIfNotPinnedOrMain];
    
    // Since ocr detect may be inaccurate, sometimes need to set sourceLanguage manually, so show Fixed window.
    EZWindowType windowType = Configuration.shared.shortcutSelectTranslateWindowType;
    EZBaseQueryWindow *window = [self windowWithType:windowType];
    
    // Wait to close floating window if need.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [Snip.shared startWithCompletion:^(NSImage *_Nullable image) {
            if (!image) {
                MMLogWarn(@"not get screenshot");
                return;
            }
            
            MMLogInfo(@"get screenshot: %@", image);
            
            // 缓存最后一张图片，统一放到 MMLogs 文件夹，方便管理
            static NSString *_imagePath = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                _imagePath = [[MMManagerForLog logDirectoryWithName:@"Image"] stringByAppendingPathComponent:@"snip_image.png"];
            });
            [[NSFileManager defaultManager] removeItemAtPath:_imagePath error:nil];
            [image mm_writeToFileAsPNG:_imagePath];
            MMLogInfo(@"已保存图片：%@", _imagePath);
            
            // Reset window height first, avoid being affected by previous window height.
            [window.queryViewController resetTableView:^{
                self.actionType = EZActionTypeOCRQuery;
                [self showFloatingWindowType:windowType queryText:nil];
                [window.queryViewController startOCRImage:image actionType:self.actionType];
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
    
    EZWindowType windowType = Configuration.shared.shortcutSelectTranslateWindowType;
    
    if (self.floatingWindowType == windowType && self.floatingWindow.isVisible) {
        [self closeFloatingWindow];
        return;
    }
    
    NSString *queryText = nil;
    if ([Configuration.shared clearInput]) {
        queryText = @"";
    }
    
    self.actionType = EZActionTypeInputQuery;
    [self showFloatingWindowType:windowType queryText:queryText];
}

/// Show mini window at last positon.
- (void)showMiniFloatingWindow {
    MMLogInfo(@"showMiniFloatingWindow");
    
    EZWindowType windowType = Configuration.shared.mouseSelectTranslateWindowType;
    
    if (self.floatingWindowType == windowType && self.floatingWindow.isVisible) {
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
            MMLogWarn(@"not get screenshot");
            return;
        }
        
        MMLogInfo(@"get screenshot: %@", image);
        
        // 缓存最后一张图片，统一放到 MMLogs 文件夹，方便管理
        static NSString *_imagePath = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _imagePath = [[MMManagerForLog logDirectoryWithName:@"Image"] stringByAppendingPathComponent:@"snip_image.png"];
        });
        [[NSFileManager defaultManager] removeItemAtPath:_imagePath error:nil];
        [image mm_writeToFileAsPNG:_imagePath];
        MMLogInfo(@"已保存图片：%@", _imagePath);
        
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
    MMLogInfo(@"Clear input");
    
    [self.floatingWindow.queryViewController clearInput];
}

- (void)clearAll {
    MMLogInfo(@"Clear All");
    
    [self.floatingWindow.queryViewController clearAll];
}

- (void)copyQueryText {
    [self.floatingWindow.queryViewController copyQueryText];
}

- (void)copyFirstTranslatedText {
    [self.floatingWindow.queryViewController copyFirstTranslatedText];
}

- (void)pin {
    MMLogInfo(@"Pin");
    
    EZBaseQueryWindow *queryWindow = EZWindowManager.shared.floatingWindow;
    queryWindow.pin = !queryWindow.pin;
}

- (void)closeWindowOrExitSreenshot {
    MMLogInfo(@"Close window, or exit screenshot");
    
    if (Snip.shared.isSnapshotting) {
        [Snip.shared stop];
    } else {
        [self closeFloatingWindow];
    }
}

- (void)toggleTranslationLanguages {
    [self.floatingWindow.queryViewController toggleTranslationLanguages];
}

- (void)focusInputTextView {
    [self.floatingWindow.queryViewController focusInputTextView];
}

- (void)playOrStopQueryTextAudio {
    [self.floatingWindow.queryViewController togglePlayQueryText];
}


#pragma mark - Close floating window

/// Close floating window, and record last floating window type.
- (void)closeFloatingWindow {
    [self closeFloatingWindow:self.floatingWindowType];
}

/**
 Close floating window if not pinned or main window.
 Main window is basically equivalent to a pinned floating window.
 */
- (void)closeFloatingWindowIfNotPinnedOrMain {
    [self closeFloatingWindowIfNotPinned:self.floatingWindowType exceptWindowType:EZWindowTypeMain];
}

- (void)closeFloatingWindowIfNotPinned {
    [self closeFloatingWindowIfNotPinned:self.floatingWindowType exceptWindowType:EZWindowTypeNone];
}

- (void)closeFloatingWindowIfNotPinnedOrMain:(EZWindowType)windowType {
    [self closeFloatingWindowIfNotPinned:windowType exceptWindowType:EZWindowTypeMain];
}

- (void)closeFloatingWindowIfNotPinned:(EZWindowType)windowType exceptWindowType:(EZWindowType)exceptWindowType {
    EZBaseQueryWindow *window = [self windowWithType:windowType];
    if (!window.isPin && windowType != exceptWindowType) {
        [self closeFloatingWindow:windowType];
    }
}

- (void)closeFloatingWindow:(EZWindowType)windowType {
    EZBaseQueryWindow *floatingWindow = [self windowWithType:windowType];
    if (!floatingWindow || !floatingWindow.isVisible) {
        return;
    }
    
    MMLogInfo(@"close window type: %ld", windowType);
    
    floatingWindow.pin = NO;
        
    /// !!!: Close window may call window delegate method `windowDidResignKey:`
    /// And `windowDidResignKey:` will call `closeFloatingWindowIfNotPinned:`
    [floatingWindow close];
    
    if (![self currentShowingSettingsWindow]) {
       // Recover last app.
        [self activeLastFrontmostApplication];
    }
    
    [self updateFloatingWindowType:windowType isShowing:NO];
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
        MMLogInfo(@"Easydict is running in debug mode, so do not show release App.");
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
    NSString *appName = application.localizedName ?: @"";
    NSString *bundleID = application.bundleIdentifier ?: @"";
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
