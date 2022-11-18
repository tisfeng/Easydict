//
//  EZSelectTextEvent.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZEventMonitor.h"
#include <Carbon/Carbon.h>

static CGFloat kDismissPopButtonDelayTime = 1.0;
static NSInteger kRecordEventCount = 3;

typedef NS_ENUM(NSUInteger, EZEventMonitorType) {
    EZEventMonitorTypeLocal,
    EZEventMonitorTypeGlobal,
    EZEventMonitorTypeBoth,
};

@interface EZEventMonitor ()

@property (nonatomic, strong) NSPasteboard *pasteboard;
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
    AXUIElementRef focussedElement = NULL;

    AXError getFocusedUIElementError = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focussedElement);

    NSString *selectedText;
    AXError error = getFocusedUIElementError;

    if (getFocusedUIElementError == kAXErrorSuccess) {
        AXValueRef selectedTextValue = NULL;
        AXError getSelectedTextError = AXUIElementCopyAttributeValue(focussedElement, kAXSelectedTextAttribute, (CFTypeRef *)&selectedTextValue);
        error = getSelectedTextError;
        if (getSelectedTextError == kAXErrorSuccess) {
            // Note: selectedText may be @""
            selectedText = (__bridge NSString *)(selectedTextValue);
            self.selectedText = selectedText;
            NSLog(@"--> Auxiliary Selected Text: %@", selectedText);
        } else {
            if (getSelectedTextError == kAXErrorNoValue) {
                NSLog(@"No Value: %d", getSelectedTextError);
            } else {
                NSLog(@"Could not get selected text: %d", getSelectedTextError);
            }
        }
    }

    if (focussedElement != NULL) {
        CFRelease(focussedElement);
    }
    CFRelease(systemWideElement);

    completion(selectedText, error);
}

// Ref: https://macdevelopers.wordpress.com/2014/02/05/how-to-get-selected-text-and-its-coordinates-from-any-system-wide-application-using-accessibility-api/
- (void)getSelectedTextRange {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focussedElement = NULL;

    CFRange selectedCFRange;
    AXValueRef selectedRangeValue = NULL;

    AXError error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focussedElement);
    if (error != kAXErrorSuccess) {
        //        NSLog(@"Could not get focussed element: %d", (int)error);
        //        if (error == kAXErrorAPIDisabled) {
        //            NSLog(@"accessibility API is disabled");
        //        }
    } else {
        // Access selected range attribute from focused element
        AXError selectedRangeError = AXUIElementCopyAttributeValue(focussedElement, kAXSelectedTextRangeAttribute, (CFTypeRef *)&selectedRangeValue);
        if (selectedRangeError == kAXErrorSuccess)

        {
            NSLog(@"\nSelected Range: %@", selectedRangeValue);

            // Selected Range is retrieved successfully, then get the range into CFRange type object

            AXValueGetValue(selectedRangeValue, kAXValueCFRangeType, &selectedCFRange);
        } else {
            NSLog(@"Error while retrieving selected range");
            return;
        }

        // The length and location of the selected text will be selectedCFRange.length and selectedCFRange.location

        NSLog(@"\nLength: %ld, Location: %ld", selectedCFRange.length, selectedCFRange.location);

        CGRect selectedRect;

        AXValueRef selectedBounds = NULL;
        // Get the selected bounds value from the selected range

        AXError selectedBoundsError = AXUIElementCopyParameterizedAttributeValue(focussedElement, kAXBoundsForRangeParameterizedAttribute, selectedRangeValue, (CFTypeRef *)&selectedBounds);
        CFRelease(selectedRangeValue);

        if (selectedBoundsError == kAXErrorSuccess)

        {
            AXValueGetValue(selectedBounds, kAXValueCGRectType, &selectedRect);
            NSLog(@"Selection bounds: %@", NSStringFromRect(NSRectFromCGRect(selectedRect))); // Selection Rect retrieved
        }

        else

        {
            NSLog(@"Error while retrieving selected range bounds");
        }
    }
}


// Monitor global events, Ref: https://blog.csdn.net/ch_soft/article/details/7371136
- (void)startMonitor {
    //    [self checkAppIsTrusted];

    mm_weakify(self);
    NSEventMask eventMask = NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp | NSEventMaskScrollWheel | NSEventMaskKeyDown | NSEventMaskFlagsChanged | NSEventMaskLeftMouseDragged | NSEventMaskCursorUpdate | NSEventMaskMouseMoved;
    [self addGlobalMonitorWithEvent:eventMask handler:^(NSEvent *_Nonnull event) {
        mm_strongify(self);
        
        //        NSLog(@"type: %lu", (unsigned long)event.type);

        switch (event.type) {
            case NSEventTypeLeftMouseUp: {
                NSLog(@"mouse up");
                if ([self checkIfLeftMouseDragged]) {
                    NSLog(@"Dragged selected");
                    [self getSelectedText];
                }
                break;
            }
            case NSEventTypeLeftMouseDown: {
                NSLog(@"mouse down");
                self.startPoint = NSEvent.mouseLocation;
                
                // check if it is a double click
                if (event.clickCount == 2) {
                    NSLog(@"double click");
                    [self getSelectedText];
                } else {
                    [self dismissPopButton];
                }
                break;
            }
            case NSEventTypeLeftMouseDragged: {
                NSLog(@"NSEventTypeLeftMouseDragged");
                break;
            }
            case NSEventTypeKeyDown: { // seems not work...
                NSLog(@"key down");
                [self dismissPopButton];
                break;
            }
            case NSEventTypeScrollWheel:
            case NSEventTypeMouseMoved: {
                [self delayDismissPopButton];
                break;
            }

            default:
                [self dismissPopButton];
                break;
        }

        [self updateRecoredEvents:event];
    }];
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
- (void)getSelectedText {
    [self getSelectedTextByAuxiliary:^(NSString *_Nullable text, AXError error) {
        if (text.length > 0) {
            [self handleSelectedText:text];
        } else {
            // if auxiliary get failed, error may be kAXErrorNoValue
            if (error == kAXErrorNoValue) {
                [self getSelectedTextByKey:^(NSString * _Nullable text) {
                    [self handleSelectedText:text];
                }];
            }
        }
    }];
}

- (void)handleSelectedText:(NSString *)text {
    [self cancelDismissPop];
    self.endPoint = NSEvent.mouseLocation;
    
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


- (AXUIElementRef)focusedElement {
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

- (CGRect)selectionRect {
    AXUIElementRef focusedElement = [self focusedElement];

    AXValueRef selectionRangeValue;
    AXError selectionRangeError = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute, (CFTypeRef *)&selectionRangeValue);
    if (selectionRangeError == kAXErrorSuccess) {
        CFRange selectionRange;
        AXValueGetValue(selectionRangeValue, kAXValueCFRangeType, &selectionRange);

        // selectionRange.length is 0 for "no selection" (aka a bare caret insertion point)
        NSLog(@"Range: %lu, %lu", selectionRange.length, selectionRange.location);

        AXValueRef selectionBoundsValue;
        AXError selectionBoundsError = AXUIElementCopyParameterizedAttributeValue(focusedElement, kAXBoundsForRangeParameterizedAttribute, selectionRangeValue, (CFTypeRef *)&selectionBoundsValue);

        if (selectionRange.length == 0 && selectionBoundsError == kAXErrorSuccess) {
            NSLog(@"This works in TextMate 2, but nowhere else that I have seen.");

            NSLog(@"This case is the objective of this bug report");
        }

        if (selectionRange.length > 0 && selectionBoundsError == kAXErrorSuccess) {
            NSLog(@"It's easy to get the selection bounds rect when text is selected.");
        }

        if (selectionBoundsError == kAXErrorSuccess) {
            CGRect selectionBounds;
            AXValueGetValue(selectionBoundsValue, kAXValueCGRectType, &selectionBounds);

            NSLog(@"This will generally only work if text is highlighted");
            NSLog(@"Selection rect: (%f, %f) (%f, %f)", selectionBounds.origin.x, selectionBounds.origin.y, selectionBounds.size.width, selectionBounds.size.height);

            return selectionBounds;
        } else if (selectionBoundsError == kAXErrorNoValue) {
            NSLog(@"Could not get selection rect. SelectionRange.length == %lu", selectionRange.length);
            return CGRectMake(0, 0, 0, 0);
        }
    }

    return CGRectMake(0, 0, 0, 0);
}

- (void)authorize {
    NSLog(@"AuthorizeButton clicked");

    /// Open privacy prefpane

    NSString *urlString = @"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility";
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:urlString]];
}

@end
