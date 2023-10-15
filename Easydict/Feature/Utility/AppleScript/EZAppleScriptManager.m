//
//  EZAppleScript.m
//  Easydict
//
//  Created by tisfeng on 2023/10/15.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZAppleScriptManager.h"

@interface EZAppleScriptManager ()

@property (nonatomic, strong) EZScriptExecutor *scriptExecutor;

@end

@implementation EZAppleScriptManager

static EZAppleScriptManager *_instance = nil;

+ (instancetype)shared {
    @synchronized (self) {
        if (!_instance) {
            _instance = [[super allocWithZone:NULL] init];
            [_instance setup];
        }
    }
    return _instance;
}

- (EZScriptExecutor *)scriptExecutor {
    if (!_scriptExecutor) {
        _scriptExecutor = [[EZScriptExecutor alloc] init];
    }
    return _scriptExecutor;
}

- (void)setup {
    
}

#pragma mark -

- (BOOL)isKnownBrowser:(NSString *)bundleID {
    NSArray *knownBrowserBundleIDs = @[
        @"com.apple.Safari",      // Safari
        @"com.google.Chrome",     // Google Chrome
        @"com.microsoft.edgemac", // Microsoft Edge
    ];
    return [knownBrowserBundleIDs containsObject:bundleID];
}

/// Is Safari
- (BOOL)isSafari:(NSString *)bundleID {
    return [bundleID isEqualToString:@"com.apple.Safari"];
}

/// Is Chrome Kernel browser
- (BOOL)isChromeKernelBrowser:(NSString *)bundleID {
    NSArray *chromeKernelBrowsers = @[
        @"com.google.Chrome",     // Google Chrome
        @"com.microsoft.edgemac", // Microsoft Edge
    ];
    return [chromeKernelBrowsers containsObject:bundleID];
}

#pragma mark - Get Brower selected text

- (void)getBrowserSelectedText:(NSString *)bundleID completion:(AppleScriptCompletionHandler)completion {
    //    NSLog(@"get Browser selected text: %@", bundleID);
    
    if ([self isSafari:bundleID]) {
        [self getSafariSelectedText:completion];
    } else if ([self isChromeKernelBrowser:bundleID]) {
        [self getChromeSelectedTextByAppleScript:bundleID completion:completion];
    } else {
        completion(nil, nil);
    }
}

/// Get Safari selected text by AppleScript. Cost ~100ms
- (void)getSafariSelectedText:(AppleScriptCompletionHandler)completion {
    NSString *bundleID = @"com.apple.Safari";
    NSString *script = [NSString stringWithFormat:
                        @"tell application id \"%@\"\n"
                        "   tell front document\n"
                        "       set selection_text to do JavaScript \"window.getSelection().toString();\"\n"
                        "   end tell\n"
                        "end tell\n",
                        bundleID];
    
    // runAppleScript is faster ~0.1s than runAppleScriptWithTask
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, NSError *_Nonnull error) {
        NSLog(@"Safari selected text: %@", result);
        completion(result, error);
    }];
}

/// Get Chrome kernel browser selected text by AppleScript, like Google Chrome, Microsoft Edge, etc. Cost ~100ms
- (void)getChromeSelectedTextByAppleScript:(NSString *)bundleID completion:(AppleScriptCompletionHandler)completion {
    NSString *script = [NSString stringWithFormat:
                        @"tell application id \"%@\"\n"
                        "   tell active tab of front window\n"
                        "       set selection_text to execute javascript \"window.getSelection().toString();\"\n"
                        "   end tell\n"
                        "end tell\n",
                        bundleID];
    
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, NSError *_Nonnull error) {
        NSLog(@"Chrome Browser selected text: %@", result);
        completion(result, error);
    }];
}

#pragma mark - Get Brower tab URL

// Since Brower is used so frequently, it is necessary to record tab URL like App, to optimize performance or fix bugs.
- (void)getBrowserCurrentTabURL:(NSString *)bundleID completion:(void (^)(NSString *_Nullable tabURL))completion {
    if ([self isSafari:bundleID]) {
        [self getSafariCurrentTabURL:bundleID completion:completion];
    } else if ([self isChromeKernelBrowser:bundleID]) {
        [self getChromeCurrentTabURL:bundleID completion:completion];
    } else {
        completion(nil);
    }
}

/// Get Chrome current tab URL.
- (void)getChromeCurrentTabURL:(NSString *)bundleID completion:(void (^)(NSString *_Nullable tabURL))completion {
    /**
     tell application "Google Chrome"
     set theUrl to URL of active tab of front window
     end tell
     */
    NSString *script = [NSString stringWithFormat:
                        @"tell application id \"%@\"\n"
                        "   set theUrl to URL of active tab of front window\n"
                        "end tell\n",
                        bundleID];
    
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, NSError *_Nonnull error) {
        NSLog(@"Chrome current tab URL: %@", result);
        completion(result);
    }];
}

/// Get Safari current tab URL.
- (void)getSafariCurrentTabURL:(NSString *)bundleID completion:(void (^)(NSString *_Nullable tabURL))completion {
    /**
     tell application "Safari"
     set theUrl to URL of front document
     end tell
     */
    NSString *script = [NSString stringWithFormat:
                        @"tell application id \"%@\"\n"
                        "   set theUrl to URL of front document\n"
                        "end tell\n",
                        bundleID];
    
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, NSError *_Nonnull error) {
        NSLog(@"Safari current tab URL: %@", result);
        completion(result);
    }];
}

#pragma mark - Replace Browser selected text

- (void)replaceBrowserSelectedText:(NSString *)replacementString
                          bundleID:(NSString *)bundleID
                        completion:(AppleScriptCompletionHandler)completion 
{
    if ([self isSafari:bundleID]) {
        [self replaceSafariSelectedText:replacementString bundleID:bundleID completion:completion];
    } else if ([self isChromeKernelBrowser:bundleID]) {
        [self replaceChromeSelectedText:replacementString bundleID:bundleID completion:completion];
    } else {
        completion(nil, nil);
    }
}

/// Replace Safari selected text by AppleScript. Cost ~100ms
- (void)replaceSafariSelectedText:(NSString *)selectedText bundleID:(NSString *)bundleID completion:(AppleScriptCompletionHandler)completion {
    NSString *script = [NSString stringWithFormat:
                        @"tell application id \"%@\"\n"
                        "     do JavaScript \"document.execCommand('insertText', false, '%@')\" in document 1\n"
                        "end tell\n",
                        bundleID, selectedText];
    
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, NSError *_Nonnull error) {
        // If success, result is nil.
        NSLog(@"Safari replace selected text result: %@", result);
        completion(result, error);
    }];
}

/// Replace Chrome kernel browser selected text by AppleScript, like Google Chrome, Microsoft Edge, etc. Cost ~100ms
- (void)replaceChromeSelectedText:(NSString *)selectedText bundleID:(NSString *)bundleID completion:(AppleScriptCompletionHandler)completion {
    NSString *script = [NSString stringWithFormat:
                        @"tell application id \"%@\"\n"
                        "   tell active tab of front window\n"
                        "       execute javascript \"document.execCommand('insertText', false, '%@')\"\n"
                        "   end tell\n"
                        "end tell\n",
                        bundleID, selectedText];
    
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, NSError *_Nonnull error) {
        // If success, result is true.
        NSLog(@"Chrome replace selected text result: %@", result);
        completion(result, error);
    }];
}

#pragma mark -

/// Simulate key event.
void postKeyboardEvent(CGEventFlags flags, CGKeyCode virtualKey, bool keyDown) {
    // Ref: http://www.enkichen.com/2018/09/12/osx-mouse-keyboard-event/
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
    CGEventRef push = CGEventCreateKeyboardEvent(source, virtualKey, keyDown);
    CGEventSetFlags(push, flags);
    CGEventPost(kCGHIDEventTap, push);
    CFRelease(push);
    CFRelease(source);
}

@end
