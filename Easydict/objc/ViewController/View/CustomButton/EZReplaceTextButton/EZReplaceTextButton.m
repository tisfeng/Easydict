//
//  EZReplaceTextButton.m
//
//
//  Created by tisfeng on 2023/10/13.
//

#import "EZReplaceTextButton.h"
#import "NSImage+EZSymbolmage.h"
#import "EZWindowManager.h"
#import "EZSystemUtility.h"
#import "EZLog.h"
#import "Easydict-Swift.h"

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
    BOOL useCompatibilityMode = Configuration.shared.replaceWithTranslationInCompatibilityMode;

    NSDictionary *parameters = @{
        @"floating_window_type" : @(EZWindowManager.shared.floatingWindowType),
        @"app_name" : app.localizedName,
        @"bundle_id" : bundleID,
        @"text_length" : textLengthRange,
        @"use_compatibility_mode" : @(useCompatibilityMode)
    };
    [EZLog logEventWithName:@"replace_selected_text" parameters:parameters];
    MMLogInfo(@"repalce selected text: %@", parameters);

    /**
     Since some apps (such as Browsers) environment is complex, use Accessibility to replace text may fail, so it is better to use key event to replace text. Fix https://github.com/tisfeng/Easydict/issues/622

     But Copy and Paste action will pollute the clipboard, and may cause Cmd + C does not work 😓

     So we add a option for user to decide whether to use key event to replace text.
     */
    if (useCompatibilityMode) {
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
            MMLogError(@"replaceSelectedText error: %d", error);
            [self replaceSelectedTextByKey:replacementString];
        }
        CFRelease(focusedElement);
    } else {
        MMLogError(@"replaceSelectedText error: %d", error);
        [self replaceSelectedTextByKey:replacementString];
    }
    CFRelease(systemWideElement);
}

- (void)replaceSelectedTextByKey:(NSString *)replacementString {
    NSRunningApplication *app = NSWorkspace.sharedWorkspace.frontmostApplication;
    MMLogInfo(@"Use Cmd+V to replace selected text, App: %@", app.localizedName);

    NSString *lastText = [EZSystemUtility getLastPasteboardText];
    [replacementString copyToPasteboard];

    CGFloat delayTime = 2 * EZGetClipboardTextDelayTime;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [EZSystemUtility postPasteEvent];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [lastText copyToPasteboard];
        });
    });
}

@end
