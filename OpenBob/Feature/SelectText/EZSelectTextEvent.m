//
//  EZSelectTextEvent.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZSelectTextEvent.h"
#include <Carbon/Carbon.h>

static CGFloat kReadPasteboardInterval = 1.0;

@interface EZSelectTextEvent ()

@property (nonatomic, strong) NSPasteboard *pasteboard;
@property (nonatomic, strong) NSString *selectedText;
@property (nonatomic, assign) NSInteger changeCount;

@end

@implementation EZSelectTextEvent

- (instancetype)init {
    if (self = [super init]) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        self.pasteboard = pasteboard;
        self.changeCount = pasteboard.changeCount;
        
        [self monitorForEvents];
        
        [self checkAppIsTrusted];
    }
    return self;
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
    // use AXIsProcessTrustedWithOptions to check if the app is trusted
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
- (void)monitorForEvents {
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseUp handler:^(NSEvent *event) {
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
            default:
                break;
        }
    }];
}

@end




