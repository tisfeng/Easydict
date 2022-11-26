//
//  EZSelectTextEvent.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZEventMonitor.h"
#include <Carbon/Carbon.h>
#import "EZWindowManager.h"

static CGFloat kDismissPopButtonDelayTime = 10.0;
static NSInteger kRecordEventCount = 3;

typedef NS_ENUM(NSUInteger, EZEventMonitorType) {
    EZEventMonitorTypeLocal,
    EZEventMonitorTypeGlobal,
    EZEventMonitorTypeBoth,
};

@interface EZEventMonitor ()

@property (nonatomic, strong) NSString *selectedText;
@property (nonatomic, assign) NSInteger changeCount;

@property (nonatomic, assign) EZEventMonitorType type;
@property (nonatomic, strong) id localMonitor;
@property (nonatomic, strong) id globalMonitor;

// recored last 3 events
@property (nonatomic, strong) NSMutableArray<NSEvent *> *recordEvents;

@end


@implementation EZEventMonitor

- (instancetype)init {
    if (self = [super init]) {
        _recordEvents = [NSMutableArray array];
        //        [self monitorForEvents];
        //        [self checkAppIsTrusted];
    }
    return self;
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

    // Simulation shortcut cmd+c
    CGEventRef push = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_C, true);
    CGEventSetFlags(push, kCGEventFlagMaskCommand);
    CGEventPost(kCGHIDEventTap, push);
    CFRelease(push);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        NSString *selectedText = [[[pasteboard pasteboardItems] firstObject] stringForType:NSPasteboardTypeString];
        self.selectedText = selectedText;
        NSLog(@"Key getText: %@", selectedText);

        [pasteboard clearContents];

        completion(selectedText);
    });
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

    // ⚠️ This frame is left-top position
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
            NSLog(@"--> Auxiliary selected text: %@", selectedText);
        } else {
            if (getSelectedTextError == kAXErrorNoValue) {
                NSLog(@"No Value: %d", getSelectedTextError);
            } else {
                NSLog(@"Can't get selected text: %d", getSelectedTextError);
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
            // ⚠️ Sometimes, frame is incorrect { value = x:591 y:-16071 w:24 h:17 }
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
        if (event.keyCode == 53) { // escape
            NSLog(@"escape");
        }
        return event;
    }];

    mm_weakify(self);
    NSEventMask eventMask = NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp | NSEventMaskScrollWheel | NSEventMaskKeyDown | NSEventMaskFlagsChanged | NSEventMaskLeftMouseDragged | NSEventMaskCursorUpdate | NSEventMaskMouseMoved | NSEventMaskAny;
    [self addGlobalMonitorWithEvent:eventMask handler:^(NSEvent *_Nonnull event) {
        mm_strongify(self);

        [self handleMonitorEvent:event];
    }];
}

#pragma mark - Handle Event

- (void)handleMonitorEvent:(NSEvent *)event {
    //        NSLog(@"type: %lu", (unsigned long)event.type);

    switch (event.type) {
        case NSEventTypeLeftMouseUp: {
            //                NSLog(@"mouse up");
            if ([self checkIfLeftMouseDragged]) {
                //                    NSLog(@"Dragged selected");
                [self getSelectedText:YES];
            }
            break;
        }
        case NSEventTypeLeftMouseDown: {
            //                NSLog(@"mouse down");
            self.startPoint = NSEvent.mouseLocation;
            [self dismissIfMouseLocationInFloatingWindows];

            // check if it is a double click
            if (event.clickCount == 2) {
                //                    NSLog(@"double click");
                
                // ⚠️ Since use auxiliary to get selected text in Chrome immediately by double click may fail, so we delay a little.
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self getSelectedText:NO];
                });
                
            } else {
                [self dismissPopButton];
            }
            break;
        }
        case NSEventTypeLeftMouseDragged: {
            //                NSLog(@"NSEventTypeLeftMouseDragged");
            break;
        }
        case NSEventTypeKeyDown: { // seems not work...
            //                NSLog(@"key down");
            [self dismissPopButton];
            break;
        }
        case NSEventTypeScrollWheel:
        case NSEventTypeMouseMoved: {
//            [self delayDismissPopButton];
            break;
        }

        default:
//            [self dismissPopButton];
            break;
    }

    [self updateRecoredEvents:event];
}

- (void)dismissIfMouseLocationInFloatingWindows {
    EZWindowManager *windowManager = EZWindowManager.shared;
    if (windowManager.floatingWindowType == EZWindowTypeMini) {
        BOOL outMiniWindow = ![self checkIfMouseLocationInWindow:windowManager.miniWindow];
        if (outMiniWindow && self.dismissMiniWindowBlock) {
            NSLog(@"dismiss mini window");
            self.dismissMiniWindowBlock();
        }
    } else {
        if (windowManager.floatingWindowType == EZWindowTypeFixed) {
            BOOL outFixedWindow = ![self checkIfMouseLocationInWindow:windowManager.fixedWindow];
            if (outFixedWindow && self.dismissFixedWindowBlock) {
                NSLog(@"dismiss fixed window");
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
    if (self.recordEvents.count > kRecordEventCount) {
        [self.recordEvents removeObjectAtIndex:0];
    }
    [self.recordEvents addObject:event];
}

// Check if RecoredEvents are all dragged event
- (BOOL)checkIfLeftMouseDragged {
    if (self.recordEvents.count < kRecordEventCount) {
        return NO;
    }

    BOOL isDragged = YES;
    for (NSEvent *event in self.recordEvents) {
        if (event.type != NSEventTypeLeftMouseDragged) {
            isDragged = NO;
            break;
        }
    }
    return isDragged;
}

- (void)delayDismissPopButton {
    [self performSelector:@selector(dismissPopButton) withObject:nil afterDelay:kDismissPopButtonDelayTime];
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
    [self getSelectedTextByAuxiliary:^(NSString *_Nullable text, AXError error) {
        if (![self isValidSelectedFrame]) {
            if (checkTextFrame) {
                return;
            }
        }

        if (text.length > 0) {
            [self handleSelectedText:text];
            return;
        }

        // if auxiliary get failed but actually has selected text, error may be kAXErrorNoValue
        if (error == kAXErrorNoValue) {
            [self getSelectedTextByKey:^(NSString *_Nullable text) {
                [self handleSelectedText:text];
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

- (void)useAppScriptSelectText {
    NSString *appleScript = [self getSelectedTextScript];
    [self runAppleScript:appleScript completionHandler:^(NSAppleEventDescriptor *_Nullable eventDescriptor) {
        NSString *selectedText = eventDescriptor.stringValue;
        NSLog(@"appleScript selectedText: %@", selectedText);

        NSString *trimText = [selectedText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (trimText.length > 0 && self.selectedTextBlock) {
            self.selectedTextBlock(trimText);
        }
    }];
}


// Get the frontmost window
- (void)getFrontmostWindow:(void (^)(NSString *_Nullable))completion {
    NSArray *arr = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID));
    NSString *frontAppName = [self getFrontmostApp].localizedName;
    for (NSDictionary *dict in arr) {
        if ([dict[@"kCGWindowOwnerName"] isEqualToString:frontAppName]) {
            NSLog(@"dict: %@", dict);
            completion(dict[@"kCGWindowName"]);
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

// Run AppleScript
- (void)runAppleScript:(NSString *)script completionHandler:(void (^)(NSAppleEventDescriptor *_Nullable eventDescriptor))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];

        //        NSURL *scriptURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"applescripts" ofType:@"scpt"]];
        //        appleScript = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:nil];

        NSAppleEventDescriptor *eventDescriptor = [appleScript executeAndReturnError:nil];
        NSLog(@"eventDescriptor: %@", eventDescriptor);
        completionHandler(eventDescriptor);
    });
}

// An apple script to get the selected text
- (NSString *)getSelectedTextScript {
    NSString *script = @"tell application \"System Events\"\n"
                       @"set frontApp to name of first application process whose frontmost is true\n"
                       @"set selectedText to value of (text area 1 of window 1 of application process frontApp)\n"
                       @"end tell\n"
                       @"return selectedText";

    NSRunningApplication *app = [self getFrontmostApp];
    NSString *appName = app.localizedName;
    NSString *bundleID = app.bundleIdentifier;
    NSLog(@"appName: %@, bundleID: %@", appName, bundleID);

    script = @"tell application \"Safari\" \
    activate \
end tell \
tell application \"System Events\" \
        keystroke \"c\" using {command down} \
        delay 0.2 \
        set myData to (the clipboard) as text \
        return myData \
end tell";

    return script;
}

/**
 tell application "Xcode"
 activate
 end tell

 tell application "System Events"
 keystroke "c" using {command down}
 delay 0.1
 set myData to (the clipboard) as text
 return myData
 end tell
 */


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
    CGFloat expandValue = 15;
    CGRect expandedSelectedTextFrame = CGRectMake(selectedTextFrame.origin.x - expandValue,
                                                  selectedTextFrame.origin.y - expandValue,
                                                  selectedTextFrame.size.width + expandValue * 2,
                                                  selectedTextFrame.size.height + expandValue * 2);

    if (CGRectContainsPoint(expandedSelectedTextFrame, self.startPoint) &&
        CGRectContainsPoint(expandedSelectedTextFrame, self.endPoint)) {
        return YES;
    }

    NSLog(@"Invalid text frame: %@", @(expandedSelectedTextFrame));
    NSLog(@"start: %@, end: %@", @(self.startPoint), @(self.endPoint));

    return NO;
}

@end
