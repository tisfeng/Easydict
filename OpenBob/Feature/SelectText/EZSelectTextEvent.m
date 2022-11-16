//
//  EZSelectTextEvent.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZSelectTextEvent.h"
#include <Carbon/Carbon.h>

@implementation EZSelectTextEvent

+ (void)getText:(void (^)(NSString *_Nullable))completion {
    [[NSPasteboard generalPasteboard] clearContents];
    
    CGEventRef push = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_C, true);
    CGEventSetFlags(push, kCGEventFlagMaskCommand);
    CGEventPost(kCGHIDEventTap, push);
    CFRelease(push);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *string = [[[[NSPasteboard generalPasteboard] pasteboardItems] firstObject] stringForType:NSPasteboardTypeString];
        NSLog(@"getText: %@", string);
        completion(string);
    });
}


/**
 Get selected text, Ref: https://stackoverflow.com/questions/19980020/get-currently-selected-text-in-active-application-in-cocoa

 But this method need allow auxiliary in setting first, also no pop-up alerts either.
 */
+ (void)getSelectedText:(void (^)(NSString *_Nullable))completion {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focussedElement = NULL;
    AXError error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focussedElement);
    if (error != kAXErrorSuccess) {
        NSLog(@"Could not get focussed element");
    } else {
        AXValueRef selectedTextValue = NULL;
        AXError getSelectedTextError = AXUIElementCopyAttributeValue(focussedElement, kAXSelectedTextAttribute, (CFTypeRef *)&selectedTextValue);
        if (getSelectedTextError == kAXErrorSuccess) {

            NSString *selectedText = (__bridge NSString *)(selectedTextValue);
            NSLog(@"selectedText: %@", selectedText);
        } else {
            NSLog(@"Could not get selected text");
        }
    }
    if (focussedElement != NULL) CFRelease(focussedElement);
    
    CFRelease(systemWideElement);
}

@end
