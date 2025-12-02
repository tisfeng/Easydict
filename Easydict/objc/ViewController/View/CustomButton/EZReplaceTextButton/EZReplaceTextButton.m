//
//  EZReplaceTextButton.m
//  Easydict
//
//  Created by tisfeng on 2023/10/13.
//

#import "EZReplaceTextButton.h"
#import "NSImage+EZSymbolmage.h"
#import "EZWindowManager.h"
#import "EZLog.h"
#import "Easydict-Swift.h"

@import SelectedTextKit;

@implementation EZReplaceTextButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.image = [NSImage ez_imageWithSymbolName:@"arrow.forward.square"];

    [self executeLight:^(NSButton *button) {
        button.image = [button.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
    } dark:^(NSButton *button) {
        button.image = [button.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
    }];

    NSString *action = NSLocalizedString(@"replace_text", nil);
    self.toolTip = [NSString stringWithFormat:@"%@", action];
}

/// Replace selected text in the frontmost application.
///
/// - TODO: Replace this method with new insert api.
- (void)replaceSelectedText:(NSString *)replacementString {
    [EZWindowManager.shared activeLastFrontmostApplication];

    NSRunningApplication *app = NSWorkspace.sharedWorkspace.frontmostApplication;
    NSString *bundleID = app.bundleIdentifier;
    NSString *textLengthRange = [EZLog textLengthRange:replacementString];
    BOOL useCompatibilityMode = Configuration.shared.enableCompatibilityReplace;

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
     
     For browsers, we should use AppleScript to replace text first if enabled.
     */
    
    [EZSystemUtility.shared insertText:replacementString completionHandler:^{}];
}

@end
