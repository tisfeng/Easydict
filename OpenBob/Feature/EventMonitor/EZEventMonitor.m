//
//  EZSelectTextEvent.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZEventMonitor.h"
#include <Carbon/Carbon.h>

static CGFloat kReadPasteboardInterval = 1.0;

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

@end


@implementation EZEventMonitor

- (instancetype)init {
    if (self = [super init]) {
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

- (void)getText:(void (^)(NSString *_Nullable))completion {
    CGEventRef push = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_C, true);
    CGEventSetFlags(push, kCGEventFlagMaskCommand);
    CGEventPost(kCGHIDEventTap, push);
    CFRelease(push);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        //        NSString *string = [[[pasteboard pasteboardItems] firstObject] stringForType:NSPasteboardTypeString];
        //        NSLog(@"getText: %@", string);
        
        
        //        [pasteboard clearContents];
        
        NSString *selectedText = [self.pasteboard stringForType:NSPasteboardTypeString];
        
        //                    NSLog(@"getText: %@",selectedText);
        completion(selectedText);
        
        [self.pasteboard clearContents];
    });
}

// monitor pasteboard change
- (void)monitorPasteboardChange:(void (^)(NSString *_Nullable))completion {
    [NSTimer scheduledTimerWithTimeInterval:kReadPasteboardInterval repeats:YES block:^(NSTimer *_Nonnull timer) {
        [self getSelectedText:^(NSString *_Nullable text) {
            if (text.length > 0) {
                if (![text isEqualToString:self.selectedText]) {
                    self.selectedText = text;
                    completion(text);
                }
            }
        }];
    }];
}


/// Check App is trusted, if no, it will prompt user to add it to trusted list.
- (BOOL)checkAppIsTrusted {
    BOOL isTrusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef) @{(__bridge NSString *)kAXTrustedCheckOptionPrompt : @YES});
    NSLog(@"isTrusted: %d", isTrusted);
    
    return isTrusted == YES;
}

/**
 Get selected text, Ref: https://stackoverflow.com/questions/19980020/get-currently-selected-text-in-active-application-in-cocoa
 
 But this method need allow auxiliary in setting first, also no pop-up alerts either.
 */
- (void)getSelectedText:(void (^)(NSString *_Nullable))completion {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focussedElement = NULL;
    AXError error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focussedElement);
    if (error != kAXErrorSuccess) {
        //        NSLog(@"Could not get focussed element: %d", (int)error);
        //        if (error == kAXErrorAPIDisabled) {
        //            NSLog(@"accessibility API is disabled");
        //        }
    } else {
        AXValueRef selectedTextValue = NULL;
        AXError getSelectedTextError = AXUIElementCopyAttributeValue(focussedElement, kAXSelectedTextAttribute, (CFTypeRef *)&selectedTextValue);
        if (getSelectedTextError == kAXErrorSuccess) {
            // Note: selectedText can be @""
            NSString *selectedText = (__bridge NSString *)(selectedTextValue);
            //            NSLog(@"selectedText: %@", selectedText);
            completion(selectedText);
            return;
        } else {
            NSLog(@"Could not get selected text: %d", (int)getSelectedTextError);
        }
    }
    if (focussedElement != NULL) {
        CFRelease(focussedElement);
    }
    CFRelease(systemWideElement);
    
    completion(nil);
}

// Monitor global events, Ref: https://blog.csdn.net/ch_soft/article/details/7371136
- (void)startMonitor {
//    [self checkAppIsTrusted];
    
    mm_weakify(self);
    NSEventMask eventMask = NSEventMaskLeftMouseDown |NSEventMaskLeftMouseUp | NSEventMaskScrollWheel;
    [self addGlobalMonitorWithEvent:eventMask handler:^(NSEvent * _Nonnull event) {
        NSLog(@"type: %lu", (unsigned long)event.type);
        
        mm_strongify(self);
        switch (event.type) {
            case NSEventTypeLeftMouseUp: {
                [self getSelectedText:^(NSString *_Nullable text) {
                    // remove whitespace and new line
                    NSString *trimText = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
                    if (trimText.length > 0 && self.selectedTextBlock) {
                        self.selectedTextBlock(trimText);
                    }
                }];
                break;
            }
            case NSEventTypeScrollWheel:
            case NSEventTypeLeftMouseDown: {
                if (self.mouseDownBlock) {
                    self.mouseDownBlock();
                }
                break;
            }
            default:
                break;
        }
    }];
}

@end
