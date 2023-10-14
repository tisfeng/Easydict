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
#import "EZConfiguration.h"

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

- (void)replaceSelectedText:(NSString *)replacementString {
    [EZWindowManager.shared activeLastFrontmostApplication];
    
    if (EZConfiguration.shared.isBeta) {
        [self replaceSelectedTextByKey:replacementString];
    } else {
        [self replaceSelectedTextByAccessibility:replacementString];
    }
}

- (void)replaceSelectedTextByAccessibility:(NSString *)replacementString {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focusedElement = NULL;
    
    AXError error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement);
    
    if (error == kAXErrorSuccess && focusedElement) {
        error = AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextAttribute, (__bridge CFTypeRef)(replacementString));
        if (error != kAXErrorSuccess) {
            MMLogInfo(@"replaceSelectedText error: %d", error);
            [self replaceSelectedTextByKey:replacementString];
        }
        CFRelease(focusedElement);
    } else {
        MMLogInfo(@"replaceSelectedText error: %d", error);
        [self replaceSelectedTextByKey:replacementString];
    }
    CFRelease(systemWideElement);
}

- (void)replaceSelectedTextByKey:(NSString *)replacementString {
    NSRunningApplication *app = NSWorkspace.sharedWorkspace.frontmostApplication;
    MMLogInfo(@"Use Cmd+V to replace selected text, App: %@", app.localizedName);
    
    [replacementString copyToPasteboard];
    
    PostKeyboardEvent(kCGEventFlagMaskCommand, kVK_ANSI_V, true);
    PostKeyboardEvent(kCGEventFlagMaskCommand, kVK_ANSI_V, false);
}

@end
