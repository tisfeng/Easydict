//
//  EZReplaceTextButton.m
//  
//
//  Created by tisfeng on 2023/10/13.
//

#import "EZReplaceTextButton.h"
#import "NSImage+EZResize.h"
#import "NSImage+EZSymbolmage.h"
#include <Carbon/Carbon.h>
#import "EZEventMonitor.h"
#import "EZWindowManager.h"

@implementation EZReplaceTextButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.image = [NSImage ez_imageWithSymbolName:@"arrow.forward.square"];
    
    [self excuteLight:^(NSButton *button) {
        button.image = [button.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
    } dark:^(NSButton *button) {
        button.image = [button.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
    }];
    
    NSString *action = NSLocalizedString(@"replace_text", nil);
    self.toolTip = [NSString stringWithFormat:@"%@", action];
}

// 替换当前选中的文本
- (void)replaceSelectedText2:(NSString *)replacementString {
  
    [replacementString copyToPasteboard];
    
    [EZWindowManager.shared activeLastFrontmostApplication];
    
    PostKeyboardEvent(kCGEventFlagMaskCommand, kVK_ANSI_V, true);  // key down
    PostKeyboardEvent(kCGEventFlagMaskCommand, kVK_ANSI_V, false);  // key down

}

- (void)replaceSelectedText:(NSString *)replacementString {
    [EZWindowManager.shared activeLastFrontmostApplication];

    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focusedElement = NULL;
    
    AXError getFocusedUIElementError = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement);
    
    NSString *selectedText;
    AXError error = getFocusedUIElementError;
    
    if (getFocusedUIElementError == kAXErrorSuccess) {
        AXValueRef selectedTextValue = NULL;
        AXError getSelectedTextError = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute, (CFTypeRef *)&selectedTextValue);
        if (getSelectedTextError == kAXErrorSuccess) {
            // Note: selectedText may be @""
            selectedText = (__bridge NSString *)(selectedTextValue);
            selectedText = [selectedText removeInvisibleChar];
            MMLogInfo(@"--> replaceSelectedText: %@", selectedText);
            
            AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextAttribute, (__bridge CFTypeRef)(replacementString));
            
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
}



- (void)getSelectedTextByAccessibility:(void (^)(NSString *_Nullable text, AXError error))completion {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focusedElement = NULL;
    
    AXError getFocusedUIElementError = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement);
    
    NSString *selectedText;
    AXError error = getFocusedUIElementError;
    
    if (getFocusedUIElementError == kAXErrorSuccess) {
        AXValueRef selectedTextValue = NULL;
        AXError getSelectedTextError = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute, (CFTypeRef *)&selectedTextValue);
        if (getSelectedTextError == kAXErrorSuccess) {
            // Note: selectedText may be @""
            selectedText = (__bridge NSString *)(selectedTextValue);
            selectedText = [selectedText removeInvisibleChar];
            MMLogInfo(@"--> Accessibility success, getText: %@", selectedText);
            
            AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextAttribute, (__bridge CFTypeRef)(@"123"));

            
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

@end
