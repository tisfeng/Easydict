//
//  EZSystemUtility.m
//  Easydict
//
//  Created by tisfeng on 2023/10/15.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZSystemUtility.h"
#include <Carbon/Carbon.h>

#pragma mark - Simulate Key Event

@implementation EZSystemUtility

+ (void)postKeyboardEvent:(CGEventFlags)flags virtualKey:(CGKeyCode)virtualKey keyDown:(_Bool)keyDown {
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
    CGEventRef event = CGEventCreateKeyboardEvent(source, virtualKey, keyDown);
    CGEventSetFlags(event, flags);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
    CFRelease(source);
}

+ (void)postCopyEvent {
    [self postKeyboardEvent:kCGEventFlagMaskCommand virtualKey:kVK_ANSI_C keyDown:true];
    [self postKeyboardEvent:kCGEventFlagMaskCommand virtualKey:kVK_ANSI_C keyDown:false];
}

+ (void)postPasteEvent {
    // Disable local keyboard events while pasting.
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    CGEventSourceSetLocalEventsFilterDuringSuppressionState(source, kCGEventFilterMaskPermitLocalMouseEvents | kCGEventFilterMaskPermitSystemDefinedEvents, kCGEventSuppressionStateSuppressionInterval);

    [self postKeyboardEvent:kCGEventFlagMaskCommand virtualKey:kVK_ANSI_V keyDown:true];
    [self postKeyboardEvent:kCGEventFlagMaskCommand virtualKey:kVK_ANSI_V keyDown:false];
}

+ (nullable NSString *)stringFromKeyCode:(CGKeyCode)keyCode {
    TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
    CFDataRef layoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
    const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    UInt32 keysDown = 0;
    UniChar chars[4];
    UniCharCount realLength;
    OSStatus status = UCKeyTranslate(keyboardLayout,
                                     keyCode,
                                     kUCKeyActionDisplay,
                                     0,
                                     LMGetKbdType(),
                                     kUCKeyTranslateNoDeadKeysBit,
                                     &keysDown,
                                     sizeof(chars) / sizeof(chars[0]),
                                     &realLength,
                                     chars);
    CFRelease(currentKeyboard);
    if (status != noErr) {
        return nil;
    }
    return [NSString stringWithCharacters:chars length:1];
}

#pragma mark -

/// Check if the current focused element is editable. Cost 0.1~0.2s
+ (BOOL)isSelectedTextEditable {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();

    AXUIElementRef focusedElement = NULL;
    AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement);

    BOOL isEditable = NO;

    // focusedElement may be NULL in Telegram App
    if (focusedElement != NULL) {
        CFTypeRef roleValue;
        AXUIElementCopyAttributeValue(focusedElement, kAXRoleAttribute, &roleValue);
        if (roleValue != NULL) {
            if (CFGetTypeID(roleValue) == CFStringGetTypeID()) {
                NSString *role = (__bridge NSString *)roleValue;
                NSSet *editableTextRoles = [NSSet setWithArray:@[
                    (__bridge NSString *)kAXTextFieldRole,
                    (__bridge NSString *)kAXTextAreaRole,
                    (__bridge NSString *)kAXComboBoxRole, // Safari: Google search field
                    (__bridge NSString *)kAXSearchFieldSubrole,
                    (__bridge NSString *)kAXPopUpButtonRole,
                    (__bridge NSString *)kAXMenuRole,
                ]];
                if ([editableTextRoles containsObject:role]) {
                    isEditable = YES;
                    NSLog(@"role: %@", role);
                }
            }
            CFRelease(roleValue);
        }
        CFRelease(focusedElement);
    }
    CFRelease(systemWideElement);
    
    NSLog(@"isEditable: %d", isEditable);

    return isEditable;
}

/// Get pasteboard text
+ (NSString *)getLastPasteboardText {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    // !!!: Do not use [pasteboard stringForType:NSPasteboardTypeString], it will get the last text even current copy value is nil.
    NSString *text = [[[pasteboard pasteboardItems] firstObject] stringForType:NSPasteboardTypeString];
    return text;
}

@end


#pragma mark -

/// Simulate mouse click.  PostMouseEvent(kCGMouseButtonLeft, kCGEventLeftMouseDown, focusPoint, 1);
void postMouseEvent(CGMouseButton button, CGEventType type, const CGPoint point, int64_t clickCount) {
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
    CGEventRef theEvent = CGEventCreateMouseEvent(source, type, point, button);
    CGEventSetIntegerValueField(theEvent, kCGMouseEventClickState, clickCount);
    CGEventSetType(theEvent, type);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
    CFRelease(source);
}

/// Get NSString from keycode
NSString *stringFromKeyCode(CGKeyCode keyCode) {
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


/// Get last NSPasteboard string text.
NSString *getLastPasteboardText(void) {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    // !!!: Do not use [pasteboard stringForType:NSPasteboardTypeString], it will get the last text even current copy value is nil.
    NSString *text = [[[pasteboard pasteboardItems] firstObject] stringForType:NSPasteboardTypeString];
    return text;
}
