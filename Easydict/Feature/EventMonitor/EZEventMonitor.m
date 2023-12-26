//
//  EZSelectTextEvent.m
//  Easydict
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZEventMonitor.h"
#import "EZWindowManager.h"
#import "EZConfiguration.h"
#import "EZPreferencesWindowController.h"
#import "EZScriptExecutor.h"
#import "EZAudioUtils.h"
#import "EZCoordinateUtils.h"
#import "EZToast.h"
#import "EZLocalStorage.h"
#import "EZAppleScriptManager.h"
#import "EZSystemUtility.h"

static CGFloat const kDismissPopButtonDelayTime = 0.1;
static NSTimeInterval const kDelayGetSelectedTextTime = 0.1;

// The longest system alert audio is Crystal, named Glass.aiff, its effective playback time is less than 0.8s
static NSTimeInterval const kDelayRecoverVolumeTime = 1.0;

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

// We need to store the current volume, because the volume will be set to 0 when empty copy.
@property (nonatomic, assign) float currentVolume;
// When isMuting, we should not read system volume.
@property (nonatomic, assign) BOOL isMuting;

@property (nonatomic, strong) EZScriptExecutor *exeCommand;

@property (nonatomic, assign) CFMachPortRef eventTap;

@property (nonatomic, assign) EZTriggerType frontmostAppTriggerType;
@property (nonatomic, assign) BOOL isPopButtonVisible;

@end


@implementation EZEventMonitor

static EZEventMonitor *_instance = nil;

+ (instancetype)shared {
    @synchronized (self) {
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

- (EZScriptExecutor *)exeCommand {
    if (!_exeCommand) {
        _exeCommand = [[EZScriptExecutor alloc] init];
    }
    return _exeCommand;
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
            NSLog(@"App bundleID: %@, %@", appBundleID, @(triggerType));
        }
    }
    return triggerType;
}

- (NSArray<EZAppModel *> *)defaultAppModelList {
    /**
     FIX https://github.com/tisfeng/Easydict/issues/123
     
     And WeChat does not support Shift select text, so please use shortcut key to instead.
     */
    EZAppModel *wechat = [[EZAppModel alloc] init];
    wechat.appBundleID = @"com.tencent.xinWeChat";
    wechat.triggerType = EZTriggerTypeDoubleClick | EZTriggerTypeTripleClick;
    
    NSArray *defaultAppModels = @[
        wechat,
    ];
    
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
            NSLog(@"escape");
        }
        return event;
    }];
    
    mm_weakify(self);
    NSEventMask eventMask = NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp | NSEventTypeRightMouseDown| NSEventMaskScrollWheel | NSEventMaskKeyDown | NSEventMaskKeyUp | NSEventMaskFlagsChanged | NSEventMaskLeftMouseDragged | NSEventMaskCursorUpdate | NSEventMaskMouseMoved | NSEventMaskAny | NSEventTypeSystemDefined;
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
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CGEventTapEnable(eventTap, true);
        CFRelease(runLoopSource);
    }
}

CGEventRef eventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if (type == kCGEventKeyDown) {
        //        NSEvent *nsEvent = [NSEvent eventWithCGEvent:event];
        //        NSLog(@"nsEvent: %@", nsEvent);
        
        // Delay to dismiss, maybe the user wants to use a shortcut key to take a screenshot.
        [_instance delayDismissPopButton];
    }
    return event;
}

- (void)stopCGEventTap {
    // Stop and release the previously created event tap
    if (self.eventTap) {
        CGEventTapEnable(self.eventTap, false); // Disable the event tap
        CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self.eventTap, 0);
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CFRelease(runLoopSource);
        CFRelease(self.eventTap);
        self.eventTap = NULL;
    }
}

#pragma mark - Get selected text.

- (void)getSelectedText:(void (^)(NSString *_Nullable))completion {
    [self getSelectedText:NO completion:completion];
}

/// Use Accessibility to get selected text first, if failed, use Cmd+C.
- (void)getSelectedText:(BOOL)checkTextFrame completion:(void (^)(NSString *_Nullable))completion {
    // Run this script early to avoid conflict with selected text scripts, otherwise the selected text may be empty in first time.
    [self recordSelectTextInfo];
    
    self.selectedTextEditable = NO;
        
    // Use Accessibility first
    [self getSelectedTextByAccessibility:^(NSString *_Nullable text, AXError error) {
        // If selected text frame is valid, maybe just dragging, then ignore it.
        if (checkTextFrame && ![self isValidSelectedFrame]) {
            self.selectTextType = EZSelectTextTypeAccessibility;
            completion(nil);
            return;
        }
        
        
        // 1. If use Accessibility to get selected text success.
        if (text.length > 0) {
            self.selectTextType = EZSelectTextTypeAccessibility;
            
            // Monitor CGEventTap must be required after using Accessibility successfully.
            if (EZConfiguration.shared.autoSelectText) {
                [self monitorCGEventTap];
            }
            
            self.selectedTextEditable = [EZSystemUtility isSelectedTextEditable];

            completion(text);
            return;
        }
        
        // If use Accessibility for the first time, we need to request Accessibility permission.
        BOOL needRequestAccessibility = [self useAccessibilityForFirstTime] && error == kAXErrorAPIDisabled;
        if (needRequestAccessibility) {
            [self isAccessibilityEnabled];
            self.selectTextType = EZSelectTextTypeAccessibility;
            completion(nil);
            return;
        }
        
        void (^getSelectedTextByKeyBlock)(void) = ^{
            [self getSelectedTextBySimulatedKey:^(NSString *_Nullable text) {
                self.selectTextType = EZSelectTextTypeSimulatedKey;
                completion(text);
            }];
        };
        
        NSString *bundleID = self.frontmostApplication.bundleIdentifier;
        
        EZAppleScriptManager *appleScriptManager = [EZAppleScriptManager shared];

        // 2. Use AppleScript to get Browser selected text.
        if ([appleScriptManager isKnownBrowser:bundleID]) {
            self.selectTextType = EZSelectTextTypeAppleScript;
            [appleScriptManager getBrowserSelectedText:bundleID completion:^(NSString *_Nonnull selectedText, NSError *_Nonnull error) {
                /**
                 ???: Why the first time to get text may be nil
                 
                 error: {
                 "NSAppleScriptErrorNumber" : -1751
                 }
                 */
                if (error) {
                    getSelectedTextByKeyBlock();
                } else {
                    completion(selectedText);
                }
            }];
            return;
        }
        
        // 3. Try to use simulate key to get selected text.
        if ([self shouldUseSimulatedKey:text error:error]) {
            getSelectedTextByKeyBlock();
            return;
        }
        
        if (error == kAXErrorAPIDisabled) {
            NSLog(@"Failed to get text, kAXErrorAPIDisabled");
        }
        
        self.selectTextType = EZSelectTextTypeAccessibility;
        
        completion(nil);
    }];
}

- (void)updateSelectedTextEditableState {
    self.selectedTextEditable = [EZSystemUtility isSelectedTextEditable];
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
    
    //    NSString *bundleID = self.frontmostApplication.bundleIdentifier;
    //    [self getBrowserCurrentTabURL:bundleID completion:^(NSString *URLString) {
    //        self.browserTabURLString = URLString;
    //    }];
}


/// Auto get selected text.
- (void)autoGetSelectedText:(BOOL)checkTextFrame {
    if ([self enabledAutoSelectText]) {
//        NSLog(@"auto get selected text");
        
        self.movedY = 0;
        self.actionType = EZActionTypeAutoSelectQuery;
        [self getSelectedText:checkTextFrame completion:^(NSString *_Nullable text) {
            [self handleSelectedText:text];
        }];
        self.isPopButtonVisible = YES;
    }
}

- (BOOL)enabledAutoSelectText {
    EZConfiguration *config = [EZConfiguration shared];
    BOOL enabled = config.autoSelectText && !config.disabledAutoSelect;
    if (!enabled) {
        NSLog(@"disabled autoSelectText");
        return enabled;
    }
    
    return enabled;
}

- (void)handleSelectedText:(NSString *)text {
    [self cancelDismissPop];
    
    NSString *trimText = [text trim];
    if (trimText.length > 0 && self.selectedTextBlock) {
        self.selectedTextBlock(trimText);
        [self cancelDismissPop];
    }
}


/// Get selected text by simulated key: Cmd + C
- (void)getSelectedTextBySimulatedKey:(void (^)(NSString *_Nullable))completion {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSInteger changeCount = [pasteboard changeCount];
    
    NSString *lastText = [EZSystemUtility getLastPasteboardText];
    
    // If playing audio, we do not silence system volume.
    [EZAudioUtils isPlayingAudio:^(BOOL isPlaying) {
        BOOL shouldTurnOffSoundTemporarily = EZConfiguration.shared.disableEmptyCopyBeep && !isPlaying;
        
        // Set volume to 0 to avoid system alert.
        if (shouldTurnOffSoundTemporarily) {
            if (!self.isMuting) {
                self.currentVolume = [EZAudioUtils getSystemVolume];
            }
            [EZAudioUtils setSystemVolume:0];
            self.isMuting = YES;
        }
        
        [EZSystemUtility postCopyEvent];
        
        if (shouldTurnOffSoundTemporarily) {
            [self cancelDelayRecoverVolume];
            [self delayRecoverVolume];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(EZGetClipboardTextDelayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSInteger newChangeCount = [pasteboard changeCount];
            // If changeCount is equal to newChangeCount, it means that the copy value is nil.
            if (changeCount == newChangeCount) {
                completion(nil);
                return;
            }
            
            NSString *selectedText = [[EZSystemUtility getLastPasteboardText] removeInvisibleChar];
            self.selectedText = selectedText;
            MMLogInfo(@"--> Key getText: %@", selectedText);
            
            [lastText copyToPasteboard];
            
            completion(selectedText);
        });
    }];
}

#pragma mark - Delay to recover volume

- (void)delayRecoverVolume {
    [self performSelector:@selector(recoverVolume) withObject:nil afterDelay:kDelayRecoverVolumeTime];
}

- (void)cancelDelayRecoverVolume {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(recoverVolume) object:nil];
}

- (void)recoverVolume {
    [EZAudioUtils setSystemVolume:self.currentVolume];
    self.isMuting = NO;
}


/**
 Get selected text, Ref: https://stackoverflow.com/questions/19980020/get-currently-selected-text-in-active-application-in-cocoa
 
 But this method need allow Accessibility in setting first, no pop-up alerts.
 
 Cannot work in Apps: Safari, Mail, etc.
 */
- (void)getSelectedTextByAccessibility:(void (^)(NSString *_Nullable text, AXError error))completion {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focusedElement = NULL;
    
    AXError getFocusedUIElementError = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement);
    
    NSString *selectedText;
    AXError error = getFocusedUIElementError;
    
    // !!!: This frame is left-top position
    CGRect selectedTextFrame = [self getSelectedTextFrame];
    //    NSLog(@"selected text: %@", @(selectedTextFrame));
    
    self.selectedTextFrame = [EZCoordinateUtils convertRectToBottomLeft:selectedTextFrame];
    
    if (getFocusedUIElementError == kAXErrorSuccess) {
        AXValueRef selectedTextValue = NULL;
        AXError getSelectedTextError = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute, (CFTypeRef *)&selectedTextValue);
        if (getSelectedTextError == kAXErrorSuccess) {
            // Note: selectedText may be @""
            selectedText = (__bridge NSString *)(selectedTextValue);
            selectedText = [selectedText removeInvisibleChar];
            self.selectedText = selectedText;
            MMLogInfo(@"--> Accessibility success, getText: %@", selectedText);
        } else {
            if (getSelectedTextError == kAXErrorNoValue) {
                MMLogInfo(@"Not support Auxiliary, error: %d", getSelectedTextError);
            } else {
                MMLogInfo(@"Accessibility error: %d", getSelectedTextError);
            }
        }
        error = getSelectedTextError;
    }
    
    if (focusedElement != NULL) {
        CFRelease(focusedElement);
    }
    CFRelease(systemWideElement);
    
    completion(selectedText, error);
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
        //        NSLog(@"Range: %lu, %lu", selectionRange.length, selectionRange.location); // {4, 7290}
        
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
    NSLog(@"accessibilityEnabled: %d", accessibilityEnabled);
    return accessibilityEnabled == YES;
}

/// Check if should use simulation key to get selected text.
- (BOOL)shouldUseSimulatedKey:(NSString *)text error:(AXError)error {
    BOOL isAutoSelectQuery = self.actionType == EZActionTypeAutoSelectQuery;
    BOOL allowedForceAutoGetSelectedText = [EZConfiguration.shared forceAutoGetSelectedText];
    
    NSString *easydictBundleID = [[NSBundle mainBundle] bundleIdentifier];

    NSRunningApplication *application = [self getFrontmostApp];
    NSString *bundleID = application.bundleIdentifier;
    
    BOOL isInEasydict = [bundleID isEqualToString:easydictBundleID];
        
    /**
     When front most app is Easydict and user is recording select text shortcut key, should not use simulation key `Cmd + C`.
     
     FIX: https://github.com/tisfeng/Easydict/issues/192#issuecomment-1797878909
     */
    if (isInEasydict && EZConfiguration.shared.isRecordingSelectTextShortcutKey) {
        return NO;
    }
    
    if (isAutoSelectQuery && !allowedForceAutoGetSelectedText) {
        return NO;
    }
    
    //    NSLog(@"Accessibility error: %d", error);
    
    /**
     If Accessibility get text failed but actually has selected text, error may be kAXErrorNoValue -25212
     ???: Typora support Auxiliary, But [small probability] may return kAXErrorAPIDisabled when get selected text failed.
     
     kAXErrorNoValue: Safari, Mail, Telegram, Reeder
     kAXErrorAPIDisabled: Typora?
     */
    if (error == kAXErrorNoValue) {
        NSLog(@"unsupport Accessibility App --> %@", bundleID);
        return YES;
    }
    
    
    NSDictionary *allowedAppErrorDict = @{
        /**
         Some Apps return kAXErrorSuccess 0 but text is empty, so we need to check bundleID.
         
         VSCode: Only Terminal textView return kAXErrorSuccess but text is empty 😑
         IDEA: Javadoc rendered view will return empty text
         */
        @(kAXErrorSuccess) : @[
            @"com.microsoft.VSCode",      // VSCode
            @"com.jetbrains.intellij.ce", // IDEA
            @"com.foxitsoftware.FoxitReaderLite", // Foxit PDF Reader
        ],
        
        // Some Apps return kAXErrorAttributeUnsupported -25205, but actually has selected text.
        @(kAXErrorAttributeUnsupported) : @[
            @"com.sublimetext.4",  // Sublime Text
            @"com.microsoft.Word", // Word
            
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
            @"com.apple.freeform",      // Freeform 无边记
            // Fix:  https://github.com/tisfeng/Easydict/issues/166
            @"org.mozilla.firefox",       // Firefox
        ],
        
        // kAXErrorFailure -25200
        @(kAXErrorFailure) : @[
            @"com.apple.dt.Xcode", // Xcode, error when All messages page
        ],
    };
    
    // If allowedDict keys contains error, and values contain bundleID, then allow to use shortcut.
    for (NSNumber *errorCode in allowedAppErrorDict.allKeys) {
        if ([errorCode integerValue] == error) {
            NSArray *bundleIDs = allowedAppErrorDict[errorCode];
            if ([bundleIDs containsObject:bundleID]) {
                NSLog(@"%@, %@, %@", errorCode, bundleID, application.localizedName);
                return YES;
            }
        }
    }
    
    // Fallback, If using shortcut, to make sure we can get text, we use simulation key to get selected text.
    if (self.actionType == EZActionTypeShortcutQuery) {
        MMLogInfo(@"Fallback, need to add it to allowed app error list dict");
        MMLogInfo(@"%d, %@, %@", error, bundleID, application.localizedName);
        
        return YES;
    }
    
    return NO;
}


/// Check if current app support emtpy copy action.
- (BOOL)isSupportEmptyCopy {
    NSRunningApplication *application = [self getFrontmostApp];
    NSString *bundleID = application.bundleIdentifier;
    
    NSArray *unsupportEmptyCopyApps = @[
        @"com.apple.Safari",   // Safari
        @"com.apple.mail",     // Mail
        @"com.apple.TextEdit", // TextEdit
        @"com.apple.Terminal", // Terminal
        @"com.apple.finder",   // Finder
        @"com.apple.dt.Xcode", // Xcode
        
        @"com.eusoft.freeeudic", // Eudic
        @"com.eusoft.eudic",
        @"com.reederapp.5.macOS",   // Reeder
        @"com.apple.ScriptEditor2", // 脚本编辑器
        @"abnerworks.Typora",       // Typora
        @"com.jinghaoshe.shi",      // 晓诗
        @"xyz.chatboxapp.app",      // chatbox
        @"com.wutian.weibo",        // Maipo，微博客户端
    ];
    
    if ([unsupportEmptyCopyApps containsObject:bundleID]) {
        NSLog(@"unsupport emtpy copy: %@, %@", bundleID, application.localizedName);
        return NO;
    }
    
    return YES;
}


#pragma mark - Handle Event


- (void)handleMonitorEvent:(NSEvent *)event {
    //  NSLog(@"type: %ld", event.type);
    
    switch (event.type) {
        case NSEventTypeLeftMouseUp: {
            if ([self checkIfLeftMouseDragged]) {
                self.triggerType = EZTriggerTypeDragged;
                if (self.frontmostAppTriggerType & self.triggerType) {
                    [self autoGetSelectedText:YES];
                }
            }
            break;
        }
        case NSEventTypeLeftMouseDown: {
//            NSLog(@"mouse down");
            
            // Record some mouse event except dragged event.
            [self updateRecordedEvents:event];

            [self handleLeftMouseDownEvent:event];
            break;
        }
        case NSEventTypeLeftMouseDragged: {
            // Record dragged event.
            [self updateRecordedEvents:event];
            //                NSLog(@"NSEventTypeLeftMouseDragged");
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
            //            NSLog(@"key down");
            
            [self dismissPopButton];
            break;
        }
        case NSEventTypeScrollWheel: {
            if (self.isPopButtonVisible) {
                CGFloat deltaY = event.scrollingDeltaY;
                self.movedY += deltaY;
                //            NSLog(@"movedY: %.1f", self.movedY);
                
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
            //            NSLog(@"NSEventTypeFlagsChanged: %ld, %ld", event.type, event.modifierFlags);
            
            if (event.modifierFlags & NSEventModifierFlagShift) {
                // Shift key is released.
                //                NSLog(@"Shift key is typed.");
            }
            
            //            NSLog(@"keyCode: %d", event.keyCode); // one command key event contains key down and key up
            
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
            //            NSLog(@"default type: %ld", event.type);
            
            if (self.isPopButtonVisible) {
                [self dismissPopButton];
            }
            break;
    }
}


- (void)dismissWindowsIfMouseLocationOutsideFloatingWindow {
    EZWindowManager *windowManager = EZWindowManager.shared;
    if (windowManager.floatingWindowType == EZWindowTypeMini) {
        BOOL outsideMiniWindow = ![self checkIfMouseLocationInWindow:windowManager.miniWindow];
        if (outsideMiniWindow && self.dismissMiniWindowBlock) {
            self.dismissMiniWindowBlock();
        }
    } else {
        if (windowManager.floatingWindowType == EZWindowTypeFixed) {
            BOOL outsideFixedWindow = ![self checkIfMouseLocationInWindow:windowManager.fixedWindow];
            if (outsideFixedWindow && self.dismissFixedWindowBlock) {
                self.dismissFixedWindowBlock();
            }
        }
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

- (void)cancelDismissPop {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissPopButton) object:nil];
}

- (void)dismissPopButton {
    if (self.dismissPopButtonBlock) {
        self.dismissPopButtonBlock();
    }
    self.isPopButtonVisible = NO;
    
    [self stopCGEventTap];
}


#pragma mark - Delay get selected text

- (void)delayGetSelectedText {
    [self performSelector:@selector(autoGetSelectedText:) withObject:@(NO) afterDelay:kDelayGetSelectedTextTime];
}

- (void)delayGetSelectedText:(NSTimeInterval)delayTime {
    [self performSelector:@selector(autoGetSelectedText:) withObject:@(NO) afterDelay:delayTime];
}

/// Cancel delay get selected text.
- (void)cancelDelayGetSelectedText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoGetSelectedText:) object:@(NO)];
}


#pragma mark -

// Get the frontmost window
- (void)getFrontmostWindowInfo:(void (^)(NSDictionary *_Nullable))completion {
    NSArray *arr = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID));
    NSString *frontAppName = [self getFrontmostApp].localizedName;
    for (NSDictionary *dict in arr) {
        if ([dict[@"kCGWindowOwnerName"] isEqualToString:frontAppName]) {
            NSLog(@"dict: %@", dict);
            completion(dict);
            return;
        }
    }
    completion(nil);
}

// Get the frontmost app
- (NSRunningApplication *)getFrontmostApp {
    NSRunningApplication *app = NSWorkspace.sharedWorkspace.frontmostApplication ?: NSRunningApplication.currentApplication;
    return app;
}

- (AXUIElementRef)focusedElement2 {
    pid_t pid = [self getFrontmostApp].processIdentifier;
    AXUIElementRef focusedApp = AXUIElementCreateApplication(pid);
    
    AXUIElementRef focusedElement;
    AXError focusedElementError = AXUIElementCopyAttributeValue(focusedApp, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement);
    if (focusedElementError == kAXErrorSuccess) {
        return focusedElement;
    } else {
        return nil;
    }
}

- (void)authorize {
    NSLog(@"AuthorizeButton clicked");
    
    /// Open privacy prefpane
    
    NSString *urlString = @"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility";
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:urlString]];
}


/// Check selected text frame is valid.
/**
 If selected text frame size is zero, return YES
 If selected text frame size is not zero, and start point and end point is in selected text frame, return YES, else return NO
 */
- (BOOL)isValidSelectedFrame {
    CGRect selectedTextFrame = self.selectedTextFrame;
    // means get frame failed, but get selected text may success
    if (selectedTextFrame.size.width == 0 && selectedTextFrame.size.height == 0) {
        return YES;
    }
    
    // Sometimes, selectedTextFrame may be smaller than start and end point, so we need to expand selectedTextFrame slightly.
    CGFloat expandValue = 40;
    CGRect expandedSelectedTextFrame = CGRectMake(selectedTextFrame.origin.x - expandValue,
                                                  selectedTextFrame.origin.y - expandValue,
                                                  selectedTextFrame.size.width + expandValue * 2,
                                                  selectedTextFrame.size.height + expandValue * 2);
    
    // !!!: Note: sometimes selectedTextFrame is not correct, such as when select text in VSCode, selectedTextFrame is not correct.
    if (CGRectContainsPoint(expandedSelectedTextFrame, self.startPoint) &&
        CGRectContainsPoint(expandedSelectedTextFrame, self.endPoint)) {
        return YES;
    }
    
    NSLog(@"Invalid text frame: %@", @(expandedSelectedTextFrame));
    NSLog(@"start: %@, end: %@", @(self.startPoint), @(self.endPoint));
    
    return NO;
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


/// Check if current mouse position is in expanded selected text frame.
- (BOOL)isMouseInExpandedSelectedTextFrame2 {
    CGRect selectedTextFrame = self.selectedTextFrame;
    // means get frame failed, but get selected text may success
    if (CGSizeEqualToSize(selectedTextFrame.size, CGSizeZero)) {
        EZPopButtonWindow *popButtonWindow = EZWindowManager.shared.popButtonWindow;
        if (popButtonWindow.isVisible) {
            selectedTextFrame = popButtonWindow.frame;
        }
    }
    
    CGRect expandedSelectedTextFrame = CGRectMake(selectedTextFrame.origin.x - kExpandedRadiusValue,
                                                  selectedTextFrame.origin.y - kExpandedRadiusValue,
                                                  selectedTextFrame.size.width + kExpandedRadiusValue * 2,
                                                  selectedTextFrame.size.height + kExpandedRadiusValue * 2);
    
    CGPoint mouseLocation = NSEvent.mouseLocation;
    if (CGRectContainsPoint(expandedSelectedTextFrame, mouseLocation)) {
        return YES;
    }
    
    // Since selectedTextFrame may be zere, so we need to check start point and end point
    CGRect startEndPointFrame = [self frameFromStartPoint:self.startPoint endPoint:self.endPoint];
    if (CGRectContainsPoint(startEndPointFrame, mouseLocation)) {
        return YES;
    }
    
    return NO;
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

@end
