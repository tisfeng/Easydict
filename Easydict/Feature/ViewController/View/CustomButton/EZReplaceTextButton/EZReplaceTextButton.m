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
#import "EZWindowManager.h"
#import "EZConfiguration.h"
#import "EZAppleScriptManager.h"

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
    
    NSRunningApplication *app = NSWorkspace.sharedWorkspace.frontmostApplication;
    NSString *bundleID = app.bundleIdentifier;
    
    EZAppleScriptManager *appleScriptManager = [EZAppleScriptManager shared];
    if ([appleScriptManager isKnownBrowser:bundleID]) {
        [appleScriptManager replaceBrowserSelectedText:replacementString bundleID:bundleID completion:^(NSString * _Nullable result, NSError * _Nullable error) {
            if (error) {
                [self replaceSelectedTextByKey:replacementString];
            }
        }];
    } else {
        [self replaceSelectedTextByAccessibility:replacementString];
    }
}

- (void)replaceSelectedTextByAccessibility:(NSString *)replacementString {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focusedElement = NULL;
    
    AXError error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement);
    
    if (error == kAXErrorSuccess && focusedElement) {
        // ???: Sometimes in Chrome, error is kAXErrorSuccess but replace text failed 😓
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
    
    NSString *lastText = [self getPasteboardText];

    [replacementString copyToPasteboard];
    postKeyboardEvent(kCGEventFlagMaskCommand, kVK_ANSI_V, true);
    
    [lastText copyToPasteboard];
}

/// Get last NSPasteboard string text.
- (nullable NSString *)getPasteboardText {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    // !!!: Do not use [pasteboard stringForType:NSPasteboardTypeString], it will get the last text even current copy value is nil.
    NSString *text = [[[pasteboard pasteboardItems] firstObject] stringForType:NSPasteboardTypeString];
    return text;
}

@end
