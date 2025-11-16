//
//  EZSelectTextEvent.m
//  Easydict
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZEventMonitor.h"
#import "EZWindowManager.h"
#import "EZCoordinateUtils.h"
#import "EZToast.h"
#import "EZLocalStorage.h"
#import "Easydict-Swift.h"

static CGFloat const kDismissPopButtonDelayTime = 0.1;
static NSTimeInterval const kDelayGetSelectedTextTime = 0.1;

static NSInteger const kRecordEventCount = 3;

static NSInteger const kCommandKeyEventCount = 4;
static CGFloat const kDoublCommandInterval = 0.5;

static CGFloat const kExpandedRadiusValue = 120;

static NSString *const kHasUsedAutoSelectTextKey = @"kHasUsedAutoSelectTextKey";

typedef NS_ENUM(NSUInteger, EZEventMonitorType) {
    EZEventMonitorTypeLocal,
    EZEventMonitorTypeGlobal,
    EZEventMonitorTypeBoth,
};

@interface EZEventMonitor ()

@property (nonatomic, assign) EZEventMonitorType type;
@property (nonatomic, strong) id localMonitor;
@property (nonatomic, strong) id globalMonitor;

@property (nonatomic, assign) NSEventMask mask;
@property (nonatomic, copy) void (^handler)(NSEvent *event);

// recored last 3 events
@property (nonatomic, strong) NSMutableArray<NSEvent *> *recordEvents;

@property (nonatomic, strong) NSMutableArray<NSEvent *> *commandKeyEvents;

@property (nonatomic, assign) CGFloat movedY;

// We need to store the alert volume, because the volume will be set to 0 when using Cmd+C to get selected text.
@property (nonatomic, assign) NSInteger currentAlertVolume;

@property (nonatomic, assign) CFMachPortRef eventTap;
@property (nonatomic, assign) CFRunLoopSourceRef eventTapRunLoopSource;

@property (nonatomic, assign) EZTriggerType frontmostAppTriggerType;
@property (nonatomic, assign) BOOL isPopButtonVisible;

@property (nonatomic, strong) NSEvent *event;

@end


@implementation EZEventMonitor

static EZEventMonitor *_instance = nil;

+ (instancetype)shared {
    @synchronized(self) {
        if (!_instance) {
            _instance = [[super allocWithZone:NULL] init];
            [_instance setup];
        }
    }
    return _instance;
}

- (void)setup {
    _recordEvents = [NSMutableArray array];
    _commandKeyEvents = [NSMutableArray array];

    self.actionType = EZActionTypeAutoSelectQuery;
    self.selectTextType = EZSelectTextTypeAccessibility;
    self.frontmostApplication = [self getFrontmostApp];
    self.triggerType = EZTriggerTypeNone;
}

- (EZTriggerType)frontmostAppTriggerType {
    NSArray<EZAppModel *> *defaultAppModelList = [self defaultAppModelList];
    NSArray<EZAppModel *> *userAppModelList = [EZLocalStorage.shared selectTextTypeAppModelList];

    self.frontmostApplication = [self getFrontmostApp];
    NSString *appBundleID = self.frontmostApplication.bundleIdentifier;

    EZTriggerType defaultType = EZTriggerTypeDoubleClick | EZTriggerTypeTripleClick | EZTriggerTypeDragged | EZTriggerTypeShift;

    EZTriggerType type = [self getAppSelectTextActionType:appBundleID
                                             appModelList:defaultAppModelList
                                              defaultType:defaultType];

    type = [self getAppSelectTextActionType:appBundleID appModelList:userAppModelList defaultType:type];

    return type;
}

- (EZTriggerType)getAppSelectTextActionType:(NSString *)appBundleID
                               appModelList:(NSArray<EZAppModel *> *)appModelList
                                defaultType:(EZTriggerType)defaultType {
    EZTriggerType triggerType = defaultType;
    for (EZAppModel *appModel in appModelList) {
        if ([appModel.appBundleID isEqualToString:appBundleID]) {
            triggerType = appModel.triggerType;
            MMLogInfo(@"Hit app bundleID: %@, triggerType: %@", appBundleID, @(triggerType));
        }
    }
    return triggerType;
}

- (NSArray<EZAppModel *> *)defaultAppModelList {
    NSMutableArray *defaultAppModels = [NSMutableArray array];

    // When use simulated key to get selected text, add wechat to default app list.
    if (Configuration.shared.forceGetSelectedTextType == ForceGetSelectedTextTypeSimulatedShortcutCopy) {
        /**
         FIX https://github.com/tisfeng/Easydict/issues/123

         And WeChat does not support Shift select text, so please use shortcut key to instead.
         */
        EZAppModel *wechat = [[EZAppModel alloc] init];
        wechat.appBundleID = @"com.tencent.xinWeChat";
        wechat.triggerType = EZTriggerTypeDoubleClick | EZTriggerTypeTripleClick;

        [defaultAppModels addObject:wechat];
    }

    return defaultAppModels;
}

- (void)addLocalMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler {
    [self monitorWithType:EZEventMonitorTypeLocal event:mask handler:handler];
}

- (void)addGlobalMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler {
    [self monitorWithType:EZEventMonitorTypeGlobal event:mask handler:handler];
}

- (void)bothMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler {
    return [self monitorWithType:EZEventMonitorTypeBoth event:mask handler:handler];
}

- (void)monitorWithType:(EZEventMonitorType)type event:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler {
    self.type = type;
    self.mask = mask;
    self.handler = handler;

    [self start];
}

- (void)start {
    [self stop];
    mm_weakify(self);

    if (self.type == EZEventMonitorTypeLocal) {
        self.localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:self.mask handler:^NSEvent *_Nullable(NSEvent *_Nonnull event) {
            mm_strongify(self);
            self.handler(event);
            return event;
        }];
    } else if (self.type == EZEventMonitorTypeGlobal) {
        self.globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:self.mask handler:self.handler];
    } else {
        self.localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:self.mask handler:^NSEvent *_Nullable(NSEvent *_Nonnull event) {
            mm_strongify(self);
            self.handler(event);
            return event;
        }];
        self.globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:self.mask handler:self.handler];
    }
}

// Monitor global events, Ref: https://blog.csdn.net/ch_soft/article/details/7371136
- (void)startMonitor {
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *_Nullable(NSEvent *_Nonnull event) {
        if (event.keyCode == kVK_Escape) { // escape
            MMLogInfo(@"escape");
        }
        return event;
    }];
    [self addGlobalMonitor:Configuration.shared.autoSelectText];
}

- (void)addGlobalMonitor:(BOOL)isAutoSelectTextEnabled {
    mm_weakify(self);
    NSEventMask eventMask = NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp | NSEventMaskRightMouseDown | NSEventMaskKeyDown | NSEventMaskKeyUp | NSEventMaskFlagsChanged | NSEventMaskLeftMouseDragged | NSEventMaskCursorUpdate;
    NSEventMask maskWhenAutoSelectTextEnabled = NSEventMaskScrollWheel | NSEventMaskMouseMoved;
    if (isAutoSelectTextEnabled) {
        eventMask |= maskWhenAutoSelectTextEnabled;
    }
    [self addGlobalMonitorWithEvent:eventMask handler:^(NSEvent *_Nonnull event) {
        mm_strongify(self);
        [self handleMonitorEvent:event];
    }];
}

- (void)stop {
    [self stopCGEventTap];

    if (self.localMonitor) {
        [NSEvent removeMonitor:self.localMonitor];
        self.localMonitor = nil;
    }
    if (self.globalMonitor) {
        [NSEvent removeMonitor:self.globalMonitor];
        self.globalMonitor = nil;
    }
}

#pragma mark - Monitor CGEventTap

/// Use CGEventTap to monitor key event, Ref: https://blog.csdn.net/ch_soft/article/details/7371136
- (void)monitorCGEventTap {
    // Stop and release the previously created event tap
    [self stopCGEventTap];

    // Since NSEvent cannot monitor shortcut event, like Cmd + E, we need to use CGEventTap.
    CGEventMask eventMask = CGEventMaskBit(kCGEventKeyDown);

    /**
     !!!: CGEventTapCreate will return NULL if not root or has no accessibility permission.

     FIX: https://github.com/tisfeng/Easydict/issues/124#issuecomment-1587696395
     */
    CFMachPortRef eventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, eventMask, eventCallback, NULL);
    self.eventTap = eventTap;

    if (eventTap) {
        // eventTap must not be NULL, otherwise it will crash.
        CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
        self.eventTapRunLoopSource = runLoopSource;
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CGEventTapEnable(eventTap, true);
    }
}

CGEventRef eventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if (type == kCGEventKeyDown) {
        //        NSEvent *nsEvent = [NSEvent eventWithCGEvent:event];
        //        MMLogInfo(@"nsEvent: %@", nsEvent);

        // Delay to dismiss, maybe the user wants to use a shortcut key to take a screenshot.
        [_instance delayDismissPopButton];
    }
    return event;
}

- (void)stopCGEventTap {
    // Stop and release the previously created event tap
    if (self.eventTap) {
        CGEventTapEnable(self.eventTap, false); // Disable the event tap
        
        if (self.eventTapRunLoopSource) {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), self.eventTapRunLoopSource, kCFRunLoopCommonModes);
            CFRelease(self.eventTapRunLoopSource);
            self.eventTapRunLoopSource = NULL;
        }
        
        CFRelease(self.eventTap);
        self.eventTap = NULL;
    }
}

#pragma mark - Get selected text.

/// Get selected text with different strategies.
///
/// - Important: This completion is `NOT` called on main thread.
/// - TODO: Refactor this method, too many nested callbacks.
- (void)getSelectedTextWithCompletion:(void (^)(NSString *_Nullable))completion {
    [self recordSelectTextInfo];
    MMLogInfo(@"getSelectedText in App: %@", self.frontmostApplication);

    self.selectedTextEditable = NO;

    NSString *bundleID = self.frontmostApplication.bundleIdentifier;

    // Use Accessibility first
    [EZSystemUtility.shared getSelectedTextWithStrategy:EZTextStrategyAccessibility
                                      completionHandler:^(NSString *text, NSError *error) {
        AXError axError = (AXError)error.code;
        
        self.selectTextType = EZSelectTextTypeAccessibility;
        self.selectedTextEditable = [EZSystemUtility.shared isFocusedTextField];

        BOOL isBrowser = [AppleScriptTask isBrowserSupportingAppleScript:bundleID];
        
        // Check if user prefer AppleScript API to get selected text.
        // Since some browsers pages may use custom controls, Accessibility may not get selected text correctly.
        // Fix https://github.com/tisfeng/Easydict/issues/944
        BOOL preferAppleScript = Configuration.shared.preferAppleScriptAPI;
        
        // 1. If successfully use Accessibility to get selected text.
        if (text.length > 0) {
            // Monitor CGEventTap after successfully using Accessibility.
            if (Configuration.shared.autoSelectText) {
                [self monitorCGEventTap];
            }
            
            // If user prefer AppleScript, and the frontmost app is a browser, use AppleScript to get selected text first.
            if (!isBrowser || !preferAppleScript) {
                completion(text);
                return;
            }
        }

        // If this is the first time using Accessibility, request Accessibility permission.
        BOOL needRequestAccessibility = [self useAccessibilityForFirstTime] && axError == kAXErrorAPIDisabled;
        if (needRequestAccessibility) {
            [self isAccessibilityEnabled];
            completion(nil);
            return;
        }

        // 2. Use AppleScript to get selected text from the browser.
        if (isBrowser) {
            self.selectTextType = EZSelectTextTypeAppleScript;
            [AppleScriptTask getSelectedTextFromBrowser:bundleID completionHandler:^(NSString *_Nullable selectedText, NSError *_Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        MMLogError(@"Failed to get selected text from browser: %@", error);

                        // If AppleScript get selected text failed, fall back to use Accessibility result.
                        if (text.length > 0) {
                            MMLogInfo(@"Fallback to use Accessibility selected text: %@", text);
                            completion(text);
                            return;
                        }
                        
                        // If Accessibility also failed, try to use force get selected text if enabled.
                        // AppleScript may return timeout error if the selected text is in browser pop-up window, like Permanently remove my account in https://betterstack.com/settings/account
                        [self tryForceGetSelectedText:completion];
                        return;
                    }

                    NSString *trimmedText = selectedText.trim;
                    if (trimmedText.length > 0) {
                        completion(trimmedText);
                        return;
                    }

                    MMLogInfo(@"AppleScript get selected text is empty, try to use force get selected text for browser");

                    [self tryForceGetSelectedText:completion];
                });
            }];
            return;
        }

        if (axError == kAXErrorAPIDisabled) {
            MMLogError(@"Failed to get text, kAXErrorAPIDisabled");
        }

        // 3. Try to use force get selected text.
        [self handleForceGetSelectedTextOnAXError:axError completion:completion];
    }];
}

/// Check error type to use menu action copy or simulated key to get selected text.
- (void)handleForceGetSelectedTextOnAXError:(AXError)axError completion:(void (^)(NSString *_Nullable))completion {
    if ([self shouldForceGetSelectedTextWithAXError:axError]) {
        [self tryForceGetSelectedText:completion];
    } else {
        completion(nil);
    }
}

/// Try to force get selected text when Accessibility failed.
- (void)tryForceGetSelectedText:(void (^)(NSString *_Nullable))completion {
    BOOL enableForceGetSelectedText = Configuration.shared.enableForceGetSelectedText;
    MMLogInfo(@"Enable force get selected text: %@", enableForceGetSelectedText ? @"YES" : @"NO");

    if (!enableForceGetSelectedText) {
        completion(nil);
        return;
    }

    MMLogInfo(@"Use force get selected text");

    // Menu bar action copy is better than simulated key in most cases, such as WeChat, Telegram, etc, but it may be not stable, some apps do not have copy menu item, like Billfish.

    if (Configuration.shared.forceGetSelectedTextType == ForceGetSelectedTextTypeMenuBarActionCopy) {
        [self getSelectedTextByMenuBarActionCopyFirst:completion];
    } else {
        [self getSelectedTextBySimulatedKeyFirst:completion];
    }
}

/// Get selected text by simulated key Cmd+C, and mute alert volume temporarily to avoid alert sound.
- (void)getSelectedTextBySimulatedKey:(void (^)(NSString *_Nullable))completion {
    MMLogInfo(@"Get selected text by simulated key.");

    self.selectTextType = EZSelectTextTypeSimulatedKey;

    // After muting alert volume, get selected text by simulated key.
    [EZSystemUtility.shared getSelectedTextWithStrategy:EZTextStrategyShortcut
                                      completionHandler:^(NSString *selectedText, NSError *error) {
        MMLogInfo(@"Get selected text by simulated key success: %@", selectedText);
        completion(selectedText);
    }];
}

/// Get selected text by menu bar action copy.
- (void)getSelectedTextByMenuBarActionCopy:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    MMLogInfo(@"Get selected text by menu bar action copy");

    self.selectTextType = EZSelectTextTypeMenuBarActionCopy;

    [EZSystemUtility.shared getSelectedTextWithStrategy:EZTextStrategyMenuAction
                                      completionHandler:completion];
}

/// Get selected text by simulated key first, if failed, use menu bar action copy.
- (void)getSelectedTextBySimulatedKeyFirst:(void (^)(NSString *_Nullable))completion {
    MMLogInfo(@"Get selected text by simulated key first");

    [self getSelectedTextBySimulatedKey:^(NSString *_Nullable text) {
        if (text.length > 0) {
            completion(text);
            return;
        }

        MMLogError(@"Get selected text by simulated key is empty, try to use menu bar action copy");

        [self getSelectedTextByMenuBarActionCopy:^(NSString *_Nullable text, NSError *_Nullable error) {
            completion(text);
        }];
    }];
}

/// Get selected text by menu bar action copy first, if failed, use simulated key if app has no copy menu item.
- (void)getSelectedTextByMenuBarActionCopyFirst:(void (^)(NSString *_Nullable))completion {
    MMLogInfo(@"Get selected text by menu bar action copy first");

    [self getSelectedTextByMenuBarActionCopy:^(NSString *_Nullable text, NSError *_Nullable error) {
        NSString *trimText = [text trim];

        if (trimText.length > 0) {
            MMLogInfo(@"Get selected text by menu bar action copy success: %@", trimText);
            completion(trimText);
            return;
        }

        if (error) {
            MMLogError(@"Failed to get selected text by menu bar action copy: %@", error);
        }

        // If the frontmost app has no copy menu item, try to use simulated key to get selected text.
        if (![EZSystemUtility.shared hasCopyMenuItem]) {
            MMLogError(@"Get selected text by menu bar action copy is empty, try to use simulated key");
            [self getSelectedTextBySimulatedKey:completion];
        } else {
            MMLogError(@"Get selected text by menu bar action copy is empty, and app has copy menu item, return empty text");
            completion(nil);
        }
    }];
}

- (void)updateSelectedTextEditableState {
    self.selectedTextEditable = [EZSystemUtility.shared isFocusedTextField];
}

- (BOOL)useAccessibilityForFirstTime {
    // When user first use auto select text, show request Accessibility permission alert.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL hasUsedAutoSelectText = [userDefaults boolForKey:kHasUsedAutoSelectTextKey];
    if (!hasUsedAutoSelectText) {
        [userDefaults setBool:YES forKey:kHasUsedAutoSelectTextKey];
        return YES;
    }
    return NO;
}

- (void)recordSelectTextInfo {
    self.endPoint = [NSEvent mouseLocation];
    self.frontmostApplication = [self getFrontmostApp];

    NSString *bundleID = self.frontmostApplication.bundleIdentifier;
    [AppleScriptTask getCurrentTabURLFromBrowser:bundleID completionHandler:^(NSString *_Nullable URLString, NSError *_Nullable error) {
        if (!error) {
            MMLogInfo(@"Get browser tab url: %@", URLString);
            // Create a new copy of URLString and set it on main thread
            // FIX: Detected over-release of a CFTypeRef 0x60000158c4e0 (7 / CFString)
            dispatch_async(dispatch_get_main_queue(), ^{
                self.browserTabURLString = [URLString copy];
            });
        } else {
            MMLogError(@"Failed to get browser tabl url: %@", error);
        }
    }];
}

/// Auto get selected text.
- (void)autoGetSelectedText {
    if ([self enabledAutoSelectText]) {
        MMLogInfo(@"auto get selected text");

        self.movedY = 0;
        self.actionType = EZActionTypeAutoSelectQuery;

        [self getSelectedTextWithCompletion:^(NSString *_Nullable text) {
            self.isPopButtonVisible = YES;

            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleSelectedText:text];
            });
        }];
    }
}

- (BOOL)enabledAutoSelectText {
    Configuration *config = [Configuration shared];
    BOOL enabled = config.autoSelectText && !config.disabledAutoSelect;
    if (!enabled) {
        MMLog(@"disabled autoSelectText");
        return enabled;
    }
    return enabled;
}

- (void)handleSelectedText:(NSString *)text {
    NSString *trimText = text.removeInvisibleChar.trim;
    if (trimText.length > 0 && self.selectedTextBlock) {
        [self cancelDismissPopButton];
        self.selectedTextBlock(trimText);
    }
}

/// Check if should force get selected text when Accessibility failed.
- (BOOL)shouldForceGetSelectedTextWithAXError:(AXError)axError {
    /**
     Cmd + C may cause clipboard issues, so only enable when user turn on forceAutoGetSelectedText.

     Fix https://github.com/tisfeng/Easydict/issues/608#issuecomment-2262951479
     */

    BOOL enableForceGetSelectedText = Configuration.shared.enableForceGetSelectedText;
    MMLogInfo(@"Enable force get selected text: %@", enableForceGetSelectedText ? @"YES" : @"NO");
    if (!enableForceGetSelectedText) {
        return NO;
    }

    NSString *easydictBundleID = [[NSBundle mainBundle] bundleIdentifier];

    NSRunningApplication *application = [self getFrontmostApp];
    NSString *bundleID = application.bundleIdentifier;

    BOOL isInEasydict = [bundleID isEqualToString:easydictBundleID];

    /**
     When front most app is Easydict and user is recording select text shortcut key, should not use simulation key `Cmd + C`.

     FIX: https://github.com/tisfeng/Easydict/issues/192#issuecomment-1797878909
     */
    if (isInEasydict && Configuration.shared.isRecordingSelectTextShortcutKey) {
        return NO;
    }

    /**
     If Accessibility get text failed but actually has selected text, error may be kAXErrorNoValue -25212
     ???: Typora support Auxiliary, But [small probability] may return kAXErrorAPIDisabled when get selected text failed.

     kAXErrorNoValue: Safari, Mail, Telegram, Reeder
     kAXErrorAPIDisabled: Typora?
     */
    if (axError == kAXErrorNoValue) {
        MMLogInfo(@"error: kAXErrorNoValue, unsupported Accessibility App: %@", application);
        MMLogError(@"This error type allow force get selected text");
        return YES;
    }

    NSDictionary *allowedAppErrorDict = @{
        /**
         Some Apps return kAXErrorSuccess(0), but get selected text is empty, so we need to check bundleID.

         VSCode: Only Terminal textView return kAXErrorSuccess but text is empty 😑
         IDEA: Javadoc rendered view will return empty text
         */
        @(kAXErrorSuccess) : @[
            @"com.microsoft.VSCode",                // VSCode
            @"com.jetbrains.intellij.ce",           // IDEA
            @"com.foxitsoftware.FoxitReaderLite",   // Foxit PDF Reader
            @"com.foxit-software.Foxit.PDF.Reader", // 福昕PDF阅读器 https://www.foxitsoftware.cn/pdf-reader/
            @"com.foxit-software.Foxit.PDF.Editor", // 福昕高级PDF编辑器 Fix https://github.com/tisfeng/Easydict/issues/796
            @"com.apple.iBooksX", // Apple Books Fix https://github.com/tisfeng/Easydict/issues/964
        ],

        // Some Apps return kAXErrorAttributeUnsupported -25205, but actually has selected text.
        @(kAXErrorAttributeUnsupported) : @[
            @"com.sublimetext.4",  // Sublime Text
            @"com.microsoft.Word", // Word
            @"com.microsoft.Powerpoint", // Powerpoint, Fix https://github.com/tisfeng/Easydict/issues/868#issuecomment-2832027942

            @"com.tencent.xinWeChat",     // WeChat
            @"com.readdle.PDFExpert-Mac", // PDF Expert
            @"org.zotero.zotero",         // Zotero
            /**
             These are some special Apps, that work fine in my Mac, but cannot work in some users' Mac.

             FIX: https://github.com/tisfeng/Easydict/issues/84#issuecomment-1535885832
             */
            @"com.apple.iWork.Pages",   // Pages
            @"com.apple.iWork.Keynote", // Keynote
            @"com.apple.iWork.Numbers", // Numbers
            @"com.apple.freeform",      // Freeform 无边记 // Fix https://github.com/tisfeng/Easydict/issues/166
            @"org.mozilla.firefox",     // Firefox
            @"com.openai.chat",         // ChatGPT code block return AttributeUnsupported
        ],

        // kAXErrorFailure -25200
        @(kAXErrorFailure) : @[
            @"com.apple.dt.Xcode", // Xcode, error when All messages page
        ],
    };

    // If allowedDict keys contains error, and values contain bundleID, then allow to use shortcut.
    for (NSNumber *errorCode in allowedAppErrorDict.allKeys) {
        if ([errorCode integerValue] == axError) {
            NSArray *bundleIDs = allowedAppErrorDict[errorCode];
            if ([bundleIDs containsObject:bundleID]) {
                MMLogError(@"Allow force get selected text: %@, %@", errorCode, application);
                return YES;
            }
        }
    }

    // Fallback, If using shortcut, we should use force get selected text.
    if (self.actionType == EZActionTypeShortcutQuery) {
        MMLogInfo(@"Fallback to use force get selected text for shortcut query");
        MMLogError(@"Maybe need to add it to allowed app error list dict: %d, %@", axError, application);
        return YES;
    }

    MMLogInfo(@"After check axError: %d, not use force get selected text: %@", axError, application);

    return NO;
}

- (AXUIElementRef)focusedElement {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focusedElement = NULL;
    AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement);
    CFRelease(systemWideElement);

    return focusedElement;
}

/// Get selected text frame
- (CGRect)getSelectedTextFrame {
    // Ref: https://macdevelopers.wordpress.com/2014/02/05/how-to-get-selected-text-and-its-coordinates-from-any-system-wide-application-using-accessibility-api/
    AXUIElementRef focusedElement = [self focusedElement];
    CGRect selectionFrame = CGRectZero;
    AXValueRef selectionRangeValue;

    // 1. get selected text range value
    AXError selectionRangeError = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute, (CFTypeRef *)&selectionRangeValue);

    if (selectionRangeError == kAXErrorSuccess) {
        //  AXValueRef range --> CFRange
        //        CFRange selectionRange;
        //        AXValueGetValue(selectionRangeValue, kAXValueCFRangeType, &selectionRange);
        //        MMLogInfo(@"Range: %lu, %lu", selectionRange.length, selectionRange.location); // {4, 7290}

        // 2. get bounds from range
        AXValueRef selectionBoundsValue;
        AXError selectionBoundsError = AXUIElementCopyParameterizedAttributeValue(focusedElement, kAXBoundsForRangeParameterizedAttribute, selectionRangeValue, (CFTypeRef *)&selectionBoundsValue);

        if (selectionBoundsError == kAXErrorSuccess) {
            // 3. AXValueRef bounds --> frame
            // ???: Sometimes, the text frame is incorrect { value = x:591 y:-16071 w:24 h:17 }
            AXValueGetValue(selectionBoundsValue, kAXValueCGRectType, &selectionFrame);

            CFRelease(selectionRangeValue);
            CFRelease(selectionBoundsValue);
        }
    }

    if (focusedElement != NULL) {
        CFRelease(focusedElement);
    }

    return selectionFrame;
}

/// Check App is trusted, if no, it will prompt user to add it to trusted list.
- (BOOL)isAccessibilityEnabled {
    NSDictionary *options = @{(__bridge NSString *)kAXTrustedCheckOptionPrompt : @(YES)};
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    MMLogInfo(@"accessibilityEnabled: %d", accessibilityEnabled);
    return accessibilityEnabled == YES;
}


#pragma mark - Handle Event

- (void)handleMonitorEvent:(NSEvent *)event {
    self.event = event;
    //    MMLogInfo(@"type: %ld", event.type);

    switch (event.type) {
        case NSEventTypeLeftMouseUp: {
//            MMLogInfo(@"mouse up");

            EZWindowManager.shared.lastPoint = NSEvent.mouseLocation;

            if ([self checkIfLeftMouseDragged]) {
                self.triggerType = EZTriggerTypeDragged;
                if (self.frontmostAppTriggerType & self.triggerType) {
                    [self autoGetSelectedText];
                }
            }
            break;
        }
        case NSEventTypeLeftMouseDown: {
//            MMLogInfo(@"mouse down");

            // Record some mouse event except dragged event.
            [self updateRecordedEvents:event];

            [self handleLeftMouseDownEvent:event];
            break;
        }
        case NSEventTypeLeftMouseDragged: {
//            NSLog(@"mouse dragged");

            // Record dragged event.
            [self updateRecordedEvents:event];
            break;
        }
        case NSEventTypeRightMouseDown: {
            if (self.rightMouseDownBlock) {
                self.rightMouseDownBlock(NSEvent.mouseLocation);
            }
            break;
        }
        case NSEventTypeKeyDown: {
            // ???: The debugging environment sometimes does not work and it seems that you have to move the application to the application directory to get it to work properly.
            //            MMLogInfo(@"key down: %@, modifierFlags: %ld", event.characters, event.modifierFlags);

            EZWindowManager.shared.lastPoint = NSEvent.mouseLocation;

            if (self.isPopButtonVisible) {
                [self dismissPopButton];
            }

            break;
        }
        case NSEventTypeScrollWheel: {
            if (self.isPopButtonVisible) {
                CGFloat deltaY = event.scrollingDeltaY;
                self.movedY += deltaY;
                //                MMLogInfo(@"movedY: %.1f", self.movedY);

                CGFloat maxDeltaY = 80;
                if (fabs(self.movedY) > maxDeltaY) {
                    [self dismissPopButton];
                }
            }
            break;
        }
        case NSEventTypeMouseMoved: {
            if (self.isPopButtonVisible) {
                // Hide the button after exceeding a certain range of selected text frame.
                if (![self isMouseInPopButtonExpandedFrame]) {
                    [self dismissPopButton];
                }
            }
            break;
        }
        case NSEventTypeFlagsChanged: {
            //            MMLogInfo(@"NSEventTypeFlagsChanged: %ld, %ld", event.type, event.modifierFlags);

            EZWindowManager.shared.lastPoint = NSEvent.mouseLocation;

            if (event.modifierFlags & NSEventModifierFlagShift) {
                // Shift key is released.
                //                MMLogInfo(@"Shift key is typed.");
            }

            //            MMLogInfo(@"keyCode: %d", event.keyCode); // one command key event contains key down and key up

            if (event.keyCode == kVK_Command || event.keyCode == kVK_RightCommand) {
                [self updateCommandKeyEvents:event];
                if ([self checkIfDoubleCommandEvents]) {
                    [self dismissPopButton];

                    if (self.doubleCommandBlock) {
                        self.doubleCommandBlock();
                    }
                }
            }
            break;
        }

        default:
            //            MMLogInfo(@"default type: %ld", event.type);

            if (self.isPopButtonVisible) {
                [self dismissPopButton];
            }
            break;
    }
}


- (void)dismissWindowsIfMouseLocationOutsideFloatingWindow {
    if (![self checkIfMouseLocationInWindow:EZWindowManager.shared.floatingWindow]) {
        self.dismissAllNotPinndFloatingWindowBlock();
    }
}

- (BOOL)checkIfMouseLocationInWindow:(NSWindow *)window {
    if (CGRectContainsPoint(window.frame, NSEvent.mouseLocation)) {
        return YES;
    }
    return NO;
}

// If recoredEevents count > kRecoredEeventCount, remove the first one
- (void)updateRecordedEvents:(NSEvent *)event {
    if (self.recordEvents.count >= kRecordEventCount) {
        [self.recordEvents removeObjectAtIndex:0];
    }
    [self.recordEvents addObject:event];
}

// Check if RecoredEvents are all dragged event
- (BOOL)checkIfLeftMouseDragged {
    if (self.recordEvents.count < kRecordEventCount) {
        return NO;
    }

    for (NSEvent *event in self.recordEvents) {
        if (event.type != NSEventTypeLeftMouseDragged) {
            return NO;
        }
    }
    return YES;
}

- (void)handleLeftMouseDownEvent:(NSEvent *)event {
    self.startPoint = NSEvent.mouseLocation;

    if (self.leftMouseDownBlock) {
        self.leftMouseDownBlock(self.startPoint);
    }

    [self dismissWindowsIfMouseLocationOutsideFloatingWindow];

    // FIXME: Since use Accessibility to get selected text in Chrome immediately by double click may fail, so we delay a little.

    // Check if it is a double or triple click.
    if (event.clickCount == 2) {
        self.triggerType = EZTriggerTypeDoubleClick;
        if (self.frontmostAppTriggerType & self.triggerType) {
            // Delay more time, in case it is a triple click, we don't want to get selected text twice.
            [self delayGetSelectedText:0.2];
        }
    } else if (event.clickCount == 3) {
        self.triggerType = EZTriggerTypeTripleClick;
        if (self.frontmostAppTriggerType & self.triggerType) {
            // Cancel former double click selected text.
            [self cancelDelayGetSelectedText];
            [self delayGetSelectedText];
        }
    } else if (event.modifierFlags & NSEventModifierFlagShift) {
        self.triggerType = EZTriggerTypeShift;
        if (self.frontmostAppTriggerType & self.triggerType) {
            // Shift + Left mouse button pressed.
            [self delayGetSelectedText];
        }
    } else {
        [self dismissPopButton];
    }
}

- (void)updateCommandKeyEvents:(NSEvent *)event {
    if (self.commandKeyEvents.count >= kCommandKeyEventCount) {
        [self.commandKeyEvents removeObjectAtIndex:0];
    }
    [self.commandKeyEvents addObject:event];
}

- (BOOL)checkIfDoubleCommandEvents {
    if (self.commandKeyEvents.count < kCommandKeyEventCount) {
        return NO;
    }

    NSEvent *firstEvent = self.commandKeyEvents.firstObject;
    NSEvent *lastEvent = self.commandKeyEvents.lastObject;

    NSTimeInterval interval = lastEvent.timestamp - firstEvent.timestamp;
    if (interval < kDoublCommandInterval) {
        return YES;
    }

    return NO;
}


- (void)delayDismissPopButton {
    [self delayDismissPopButton:kDismissPopButtonDelayTime];
}

- (void)delayDismissPopButton:(NSTimeInterval)delayTime {
    [self performSelector:@selector(dismissPopButton) withObject:nil afterDelay:delayTime];
}

- (void)cancelDismissPopButton {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissPopButton) object:nil];
}

- (void)dismissPopButton {
    // If isMutingAlertVolume is YES, in this case, Cmd + C may be used to get selected text, so don't dismiss pop button.
    if ([self isCmdCEvent:self.event]) {
        return;
    }

    if (self.dismissPopButtonBlock) {
        self.dismissPopButtonBlock();
    }

    self.isPopButtonVisible = NO;

    [self stopCGEventTap];
}


#pragma mark - Delay get selected text

- (void)delayGetSelectedText {
    [self performSelector:@selector(autoGetSelectedText) withObject:@(NO) afterDelay:kDelayGetSelectedTextTime];
}

- (void)delayGetSelectedText:(NSTimeInterval)delayTime {
    [self performSelector:@selector(autoGetSelectedText) withObject:@(NO) afterDelay:delayTime];
}

/// Cancel delay get selected text.
- (void)cancelDelayGetSelectedText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoGetSelectedText) object:@(NO)];
}


#pragma mark -

// Get the frontmost app
- (NSRunningApplication *)getFrontmostApp {
    NSRunningApplication *app = NSWorkspace.sharedWorkspace.frontmostApplication ?: NSRunningApplication.currentApplication;
    return app;
}

- (void)authorize {
    MMLogInfo(@"AuthorizeButton clicked");

    /// Open privacy prefpane

    NSString *urlString = @"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility";
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:urlString]];
}

- (BOOL)isMouseInPopButtonExpandedFrame {
    EZPopButtonWindow *popButtonWindow = EZWindowManager.shared.popButtonWindow;
    CGRect popButtonFrame = popButtonWindow.frame;

    // popButtonFrame center point
    CGPoint centerPoint = CGPointMake(popButtonFrame.origin.x + popButtonFrame.size.width / 2,
                                      popButtonFrame.origin.y + popButtonFrame.size.height / 2);

    CGPoint mouseLocation = NSEvent.mouseLocation;
    BOOL insideCircle = [self isPoint:mouseLocation insideCircleWithCenter:centerPoint radius:kExpandedRadiusValue];
    if (insideCircle) {
        return YES;
    }

    return NO;
}


- (BOOL)isPoint:(CGPoint)point insideCircleWithCenter:(CGPoint)center radius:(CGFloat)radius {
    CGFloat distanceSqr = pow(point.x - center.x, 2) + pow(point.y - center.y, 2);
    CGFloat radiusSqr = pow(radius, 2);
    return distanceSqr <= radiusSqr;
}

/// Get frame from two points.
- (CGRect)frameFromStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    CGFloat x = MIN(startPoint.x, endPoint.x);
    // if endPoint.x == startPoint.x, x = endPoint.x - expandValue
    if (x == endPoint.x) {
        x = endPoint.x - kExpandedRadiusValue;
    }

    CGFloat y = MIN(startPoint.y, endPoint.y);
    // if endPoint.y == startPoint.y, y = endPoint.y - expandValue
    if (y == endPoint.y) {
        y = endPoint.y - kExpandedRadiusValue;
    }

    CGFloat width = fabs(startPoint.x - endPoint.x);
    // if endPoint.x == startPoint.x, width = expandValue * 2
    if (width == 0) {
        width = kExpandedRadiusValue * 2;
    }
    CGFloat height = fabs(startPoint.y - endPoint.y);
    // if endPoint.y == startPoint.y, height = expandValue * 2
    if (height == 0) {
        height = kExpandedRadiusValue * 2;
    }

    CGRect frame = CGRectMake(x, y, width, height);
    return frame;
}

- (BOOL)isCmdCEvent:(NSEvent *)event {
    if (event.type != NSEventTypeKeyDown && event.type != NSEventTypeKeyUp) {
        return NO;
    }

    BOOL isCmdKeyPressed = (event.modifierFlags & NSEventModifierFlagCommand) != 0;
    BOOL isCKeyPressed = event.keyCode == kVK_ANSI_C;
    return isCmdKeyPressed && isCKeyPressed;
}

@end
