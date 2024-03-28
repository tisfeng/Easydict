//
//  EZReplaceTextButton.m
//
//
//  Created by tisfeng on 2023/10/13.
//

#import "EZReplaceTextButton.h"
#import "NSImage+EZSymbolmage.h"
#import "EZWindowManager.h"
#import "EZAppleScriptManager.h"
#import "EZSystemUtility.h"
#import "EZLog.h"

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
    NSString *textLengthRange = [EZLog textLengthRange:replacementString];
    
    NSDictionary *parameters = @{
        @"floating_window_type" : @(EZWindowManager.shared.floatingWindowType),
        @"app_name" : app.localizedName,
        @"bundle_id" : bundleID,
        @"text_length" : textLengthRange,
    };
    [EZLog logEventWithName:@"replace_selected_text" parameters:parameters];
    
    EZAppleScriptManager *appleScriptManager = [EZAppleScriptManager shared];
    if ([appleScriptManager isKnownBrowser:bundleID]) {
        // Since browser environment is complex, use AppleScript to replace text may fail, so use key event to replace text.
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
    
    NSString *lastText = [EZSystemUtility getLastPasteboardText];
    [replacementString copyToPasteboard];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(EZGetClipboardTextDelayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [EZSystemUtility postPasteEvent];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(EZGetClipboardTextDelayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [lastText copyToPasteboard];
        });
    });
}

@end
