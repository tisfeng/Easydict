//
//  EZSelectTextEvent.m
//  Easydict
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZEventMonitor.h"
#include <Carbon/Carbon.h>
#import "EZWindowManager.h"
#import "EZConfiguration.h"
#import "EZPreferencesWindowController.h"
#import "EZLog.h"

static CGFloat kDismissPopButtonDelayTime = 0.5;
static NSTimeInterval kDelayGetSelectedTextTime = 0.1;

static NSInteger kRecordEventCount = 3;

static NSInteger kCommandKeyEventCount = 4;
static CGFloat kDoublCommandInterval = 0.5;

static CGFloat kExpandedFrameValue = 50;

typedef NS_ENUM(NSUInteger, EZEventMonitorType) {
    EZEventMonitorTypeLocal,
    EZEventMonitorTypeGlobal,
    EZEventMonitorTypeBoth,
};

@interface EZEventMonitor ()

@property (nonatomic, strong) NSString *selectedText;

@property (nonatomic, assign) EZEventMonitorType type;
@property (nonatomic, strong) id localMonitor;
@property (nonatomic, strong) id globalMonitor;

// recored last 3 events
@property (nonatomic, strong) NSMutableArray<NSEvent *> *recordEvents;

@property (nonatomic, strong) NSMutableArray<NSEvent *> *commandKeyEvents;

@end


@implementation EZEventMonitor

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _recordEvents = [NSMutableArray array];
    _commandKeyEvents = [NSMutableArray array];
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
    if (self.type == EZEventMonitorTypeLocal) {
        mm_weakify(self)
        self.localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:self.mask handler:^NSEvent *_Nullable(NSEvent *_Nonnull event) {
            mm_strongify(self);
            self.handler(event);
            return event;
        }];
    } else if (self.type == EZEventMonitorTypeGlobal) {
        self.globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:self.mask handler:self.handler];
    } else {
        mm_weakify(self)
        self.localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:self.mask handler:^NSEvent *_Nullable(NSEvent *_Nonnull event) {
            mm_strongify(self);
            self.handler(event);
            return event;
        }];
        self.globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:self.mask handler:self.handler];
    }
}

- (void)stop {
    if (self.localMonitor) {
        [NSEvent removeMonitor:self.localMonitor];
        self.localMonitor = nil;
    }
    if (self.globalMonitor) {
        [NSEvent removeMonitor:self.globalMonitor];
        self.globalMonitor = nil;
    }
}

- (void)getSelectedTextByKey:(void (^)(NSString *_Nullable))completion {
    self.endPoint = NSEvent.mouseLocation;
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSInteger changeCount = [pasteboard changeCount];
    
    NSString *lastText = [self getPasteboardText];
    
    // Simulate keyboard event: Cmd + C
    PostKeyboardEvent(kCGEventFlagMaskCommand, kVK_ANSI_C, true);  // key down
    PostKeyboardEvent(kCGEventFlagMaskCommand, kVK_ANSI_C, false); // key up
    
    //    [self postKeyboardEvent:NSEventModifierFlagCommand keyCode:kVK_ANSI_C keyDown:YES];
    //    [self postKeyboardEvent:NSEventModifierFlagCommand keyCode:kVK_ANSI_C keyDown:NO];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kDelayGetSelectedTextTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSInteger newChangeCount = [pasteboard changeCount];
        // If changeCount is equal to newChangeCount, it means that the copy value is nil.
        if (changeCount == newChangeCount) {
            completion(nil);
            return;
        }
        
        NSString *selectedText = [self getPasteboardText];
        self.selectedText = selectedText;
        MMLogInfo(@"--> Key getText: %@", selectedText);
        
        [lastText copyToPasteboard];
        
        completion(selectedText);
    });
}

// Return last NSPasteboard string text.
- (nullable NSString *)getPasteboardText {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    // !!!: Do not use [pasteboard stringForType:NSPasteboardTypeString], it will get the last text even current copy value is nil.
    NSString *text = [[[pasteboard pasteboardItems] firstObject] stringForType:NSPasteboardTypeString];
    return text;
}

/// Use NSEvent keyEventWithType to post keyboard event Cmd + C. Why doesn't it work?
- (void)postKeyboardEventCmdC {
    NSEvent *event = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:NSEventModifierFlagCommand timestamp:[[NSProcessInfo processInfo] systemUptime] windowNumber:0 context:nil characters:@"c" charactersIgnoringModifiers:@"c" isARepeat:NO keyCode:kVK_ANSI_C];
    [NSApp postEvent:event atStart:YES];
    
    NSEvent *eventUp = [NSEvent keyEventWithType:NSEventTypeKeyUp location:NSZeroPoint modifierFlags:NSEventModifierFlagCommand timestamp:[[NSProcessInfo processInfo] systemUptime] windowNumber:0 context:nil characters:@"c" charactersIgnoringModifiers:@"c" isARepeat:NO keyCode:kVK_ANSI_C];
    [NSApp postEvent:eventUp atStart:YES];
}


- (void)postKeyboardEvent:(NSEventModifierFlags)modifierFlags keyCode:(CGKeyCode)keyCode keyDown:(BOOL)keyDown {
    NSString *key = [self stringFromKeyCode:keyCode];
    
    [self getFrontmostWindowInfo:^(NSDictionary *dict) {
        NSNumber *windowID = dict[@"kCGWindowNumber"];
        NSEvent *event = [NSEvent keyEventWithType:keyDown ? NSEventTypeKeyDown : NSEventTypeKeyUp location:self.endPoint modifierFlags:modifierFlags timestamp:0 windowNumber:windowID.integerValue context:nil characters:key charactersIgnoringModifiers:key isARepeat:NO keyCode:keyCode];
        [NSApp postEvent:event atStart:YES];
    }];
}

/// return nsstring from keycode
- (NSString *)stringFromKeyCode:(CGKeyCode)keyCode {
    TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
    CFDataRef uchr = (CFDataRef)TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
    const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(uchr);
    UInt32 keysDown = 0;
    UniCharCount maxStringLength = 255;
    UniCharCount actualStringLength = 0;
    UniChar unicodeString[maxStringLength];
    UCKeyTranslate(keyboardLayout, keyCode, kUCKeyActionDown, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &keysDown, maxStringLength, &actualStringLength, unicodeString);
    CFRelease(currentKeyboard);
    return [NSString stringWithCharacters:unicodeString length:actualStringLength];
}


/// Simulate key event.
void PostKeyboardEvent(CGEventFlags flags, CGKeyCode virtualKey, bool keyDown) {
    // Ref: http://www.enkichen.com/2018/09/12/osx-mouse-keyboard-event/
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
    CGEventRef push = CGEventCreateKeyboardEvent(source, virtualKey, keyDown);
    CGEventSetFlags(push, flags);
    CGEventPost(kCGHIDEventTap, push);
    CFRelease(push);
    CFRelease(source);
}

/// Simulate mouse click.  PostMouseEvent(kCGMouseButtonLeft, kCGEventLeftMouseDown, focusPoint, 1);
void PostMouseEvent(CGMouseButton button, CGEventType type, const CGPoint point, int64_t clickCount) {
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
    CGEventRef theEvent = CGEventCreateMouseEvent(source, type, point, button);
    CGEventSetIntegerValueField(theEvent, kCGMouseEventClickState, clickCount);
    CGEventSetType(theEvent, type);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
    CFRelease(source);
}


/// Check App is trusted, if no, it will prompt user to add it to trusted list.
- (BOOL)checkAppIsTrusted {
    BOOL isTrusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef) @{(__bridge NSString *)kAXTrustedCheckOptionPrompt : @YES});
    NSLog(@"isTrusted: %d", isTrusted);
    
    return isTrusted == YES;
}

/**
 Get selected text, Ref: https://stackoverflow.com/questions/19980020/get-currently-selected-text-in-active-application-in-cocoa
 
 But this method need allow auxiliary in setting first, no pop-up alerts.
 
 Cannot work in App: Safari
 */
- (void)getSelectedTextByAuxiliary:(void (^)(NSString *_Nullable text, AXError error))completion {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focusedElement = NULL;
    
    AXError getFocusedUIElementError = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement);
    
    NSString *selectedText;
    AXError error = getFocusedUIElementError;
    
    // !!!: This frame is left-top position
    CGRect selectedTextFrame = [self getSelectedTextFrame];
    //    NSLog(@"selected text: %@", @(selectedTextFrame));
    self.selectedTextFrame = [self convertRect:selectedTextFrame];
    
    if (getFocusedUIElementError == kAXErrorSuccess) {
        AXValueRef selectedTextValue = NULL;
        AXError getSelectedTextError = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute, (CFTypeRef *)&selectedTextValue);
        if (getSelectedTextError == kAXErrorSuccess) {
            // Note: selectedText may be @""
            selectedText = (__bridge NSString *)(selectedTextValue);
            self.selectedText = selectedText;
            self.endPoint = NSEvent.mouseLocation;
            MMLogInfo(@"--> Auxiliary getText: %@", selectedText);
        } else {
            if (getSelectedTextError == kAXErrorNoValue) {
                MMLogInfo(@"No Value: %d", getSelectedTextError);
            } else {
                MMLogInfo(@"Can't get selected text: %d", getSelectedTextError);
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


// Monitor global events, Ref: https://blog.csdn.net/ch_soft/article/details/7371136
- (void)startMonitor {
    //    [self checkAppIsTrusted];
    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *_Nullable(NSEvent *_Nonnull event) {
        if (event.keyCode == kVK_Escape) { // escape
            NSLog(@"escape");
        }
        return event;
    }];
    
    mm_weakify(self);
    NSEventMask eventMask = NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp | NSEventMaskScrollWheel | NSEventMaskKeyDown | NSEventMaskKeyUp | NSEventMaskFlagsChanged | NSEventMaskLeftMouseDragged | NSEventMaskCursorUpdate | NSEventMaskMouseMoved | NSEventMaskAny;
    [self addGlobalMonitorWithEvent:eventMask handler:^(NSEvent *_Nonnull event) {
        mm_strongify(self);
        
        [self handleMonitorEvent:event];
    }];
}

#pragma mark - Handle Event

- (void)handleMonitorEvent:(NSEvent *)event {
    //                    NSLog(@"type: %ld", event.type);
    
    switch (event.type) {
        case NSEventTypeLeftMouseUp: {
            //                            NSLog(@"mouse up");
            if ([self checkIfLeftMouseDragged]) {
                //                    NSLog(@"Dragged selected");
                [self getSelectedText:YES];
//                [self delayGetSelectedText:0.5];
            }
            break;
        }
        case NSEventTypeLeftMouseDown: {
            //                NSLog(@"mouse down");
            self.startPoint = NSEvent.mouseLocation;
            [self dismissWindowsIfMouseLocationOutsideFloatingWindow];
            
            // FIXME: Since use auxiliary to get selected text in Chrome immediately by double click may fail, so we delay a little.
            
            // Check if it is a double or triple click.
            if (event.clickCount == 2) {
                // Delay more time, in case it is a triple click, we don't want to get selected text twice.
                [self delayGetSelectedText:0.2];
            } else if (event.clickCount == 3) {
                // Cancel former double click selected text.
                [self cancelDelayGetSelectedText];
                [self delayGetSelectedText];
            } else if (event.modifierFlags & NSEventModifierFlagShift) {
                // Shift + Left mouse button pressed.
                [self delayGetSelectedText];
            } else {
                [self dismissPopButton];
            }
            break;
        }
        case NSEventTypeLeftMouseDragged: {
            //                NSLog(@"NSEventTypeLeftMouseDragged");
            break;
        }
        case NSEventTypeKeyDown: {
            // ???: The debugging environment sometimes does not work and it seems that you have to move the application to the application directory to get it to work properly.
            //            NSLog(@"key down");
            [self dismissPopButton];
            break;
        }
        case NSEventTypeScrollWheel: {
            [self delayDismissPopButton];
        }
        case NSEventTypeMouseMoved: {
            // Hide the button after exceeding a certain range of selected text frame.
            if (![self isMouseInExpandedSelectedTextFrame]) {
                [self dismissPopButton];
            }
            break;
        }
        case NSEventTypeFlagsChanged: {
            //            NSLog(@"NSEventTypeFlagsChanged: %ld, %ld", event.type, event.modifierFlags);
            
            if (event.modifierFlags & NSEventModifierFlagShift) {
                // Shift key is released.
                //                NSLog(@"Shift key is typed.");
            }
            
            // If not Shift key is released.
            if (!((event.keyCode == kVK_Shift || kVK_RightShift) && event.modifierFlags == 256)) {
                [self dismissPopButton];
            }
            
            //            NSLog(@"keyCode: %d", event.keyCode); // one command key event contains key down and key up
            
            if (event.keyCode == kVK_Command || event.keyCode == kVK_RightCommand) {
                [self updateCommandKeyEvents:event];
                if ([self checkIfDoubleCommandEvents] && self.doubleCommandBlock) {
                    self.doubleCommandBlock();
                }
            }
            break;
        }
            
        default:
            //            NSLog(@"default type: %ld", event.type);
            [self dismissPopButton];
            break;
    }
    
    [self updateRecoredEvents:event];
}

- (void)dismissWindowsIfMouseLocationOutsideFloatingWindow {
    NSWindow *preferencesWindow = [EZPreferencesWindowController shared].window;
    BOOL outsidePreferencesWindow = ![self checkIfMouseLocationInWindow:preferencesWindow];
    if (outsidePreferencesWindow) {
        [preferencesWindow close];
    }
    
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
- (void)updateRecoredEvents:(NSEvent *)event {
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
}

/// Use auxiliary to get selected text first, if failed, use cmd key to get.
- (void)getSelectedText:(BOOL)checkTextFrame {
    BOOL enableAutoSelectText = EZConfiguration.shared.autoSelectText;
    if (!enableAutoSelectText) {
        NSLog(@"user did not enableAutoSelectText");
        return;
    }
    
    [self getSelectedTextByAuxiliary:^(NSString *_Nullable text, AXError error) {
        if (![self isValidSelectedFrame]) {
            if (checkTextFrame) {
                return;
            }
        }
        
        if (text.length > 0) {
            [self handleSelectedText:text];
            [self logSelectedText:text type:@"auxiliary"];
            return;
        }
        
        // if auxiliary get failed but actually has selected text, error may be kAXErrorNoValue
        if (error == kAXErrorNoValue) {
            [self getSelectedTextByKey:^(NSString *_Nullable text) {
                [self handleSelectedText:text];
                [self logSelectedText:text type:@"shortcut"];
            }];
        }
    }];
}

- (void)handleSelectedText:(NSString *)text {
    [self cancelDismissPop];
    
    NSString *trimText = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimText.length > 0 && self.selectedTextBlock) {
        self.selectedTextBlock(trimText);
        [self cancelDismissPop];
    }
}

#pragma mark -

/// Delay get selected text.
- (void)delayGetSelectedText {
    [self performSelector:@selector(getSelectedText:) withObject:@(NO) afterDelay:kDelayGetSelectedTextTime];
}

- (void)delayGetSelectedText:(NSTimeInterval)delayTime {
    [self performSelector:@selector(getSelectedText:) withObject:@(NO) afterDelay:delayTime];
}

/// Cancel delay get selected text.
- (void)cancelDelayGetSelectedText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getSelectedText:) object:@(NO)];
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
    NSRunningApplication *app = NSWorkspace.sharedWorkspace.frontmostApplication;
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

// Convert rect from left-top coordinate to left-bottom coordinate
- (CGRect)convertRect:(CGRect)rect {
    CGRect screenRect = NSScreen.mainScreen.frame;
    CGFloat height = screenRect.size.height;
    rect.origin.y = height - rect.origin.y - rect.size.height;
    return rect;
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
    CGFloat expandValue = 30;
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

- (void)logSelectedText:(nullable NSString *)text type:(NSString *)type {
    if (!text.length) {
        return;
    }
    
    NSRunningApplication *application = [self getFrontmostApp];
    NSString *appName = application.localizedName;
    NSString *bundleID = application.bundleIdentifier;
    NSString *textLength = [EZLog textLengthRange:text];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
        @"text" : text,
        @"type" : type,
        @"textLength" : textLength,
        @"appName" : appName,
        @"bundleID" : bundleID,
    }];
    
    [EZLog logEventWithName:@"getSelectedText" parameters:dict];
}

/// Check if current mouse position is in expanded selected text frame.
- (BOOL)isMouseInExpandedSelectedTextFrame {
    CGRect selectedTextFrame = self.selectedTextFrame;
    // means get frame failed, but get selected text may success
    if (CGSizeEqualToSize(selectedTextFrame.size, CGSizeZero)) {
        EZPopButtonWindow *popButtonWindow = EZWindowManager.shared.popButtonWindow;
        if (popButtonWindow.isVisible) {
            selectedTextFrame = popButtonWindow.frame;
        }
    }
    
    CGRect expandedSelectedTextFrame = CGRectMake(selectedTextFrame.origin.x - kExpandedFrameValue,
                                                  selectedTextFrame.origin.y - kExpandedFrameValue,
                                                  selectedTextFrame.size.width + kExpandedFrameValue * 2,
                                                  selectedTextFrame.size.height + kExpandedFrameValue * 2);
    
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
        x = endPoint.x - kExpandedFrameValue;
    }
    
    CGFloat y = MIN(startPoint.y, endPoint.y);
    // if endPoint.y == startPoint.y, y = endPoint.y - expandValue
    if (y == endPoint.y) {
        y = endPoint.y - kExpandedFrameValue;
    }
    
    CGFloat width = fabs(startPoint.x - endPoint.x);
    // if endPoint.x == startPoint.x, width = expandValue * 2
    if (width == 0) {
        width = kExpandedFrameValue * 2;
    }
    CGFloat height = fabs(startPoint.y - endPoint.y);
    // if endPoint.y == startPoint.y, height = expandValue * 2
    if (height == 0) {
        height = kExpandedFrameValue * 2;
    }
    
    CGRect frame = CGRectMake(x, y, width, height);
    return frame;
}

@end
