//
//  EZAppleScript.m
//  Easydict
//
//  Created by tisfeng on 2023/10/15.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZAppleScriptManager.h"
#import "EZConfiguration.h"

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
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, EZError *_Nonnull error) {
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
    
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, EZError *_Nonnull error) {
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
    
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, EZError *_Nonnull error) {
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
    
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, EZError *_Nonnull error) {
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
    
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, EZError *_Nonnull error) {
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
    
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, EZError *_Nonnull error) {
        // If success, result is true.
        NSLog(@"Chrome replace selected text result: %@", result);
        completion(result, error);
    }];
}

#pragma mark -

/// Use AppleScript to check if front app support copy action in menu bar.
- (void)checkApplicationSupportCopyAction:(NSString *)appBundleID completion:(void (^)(BOOL supportCopyAction))completion {
    NSBundle *appBundle = [NSBundle bundleWithIdentifier:appBundleID];
    NSString *appLanguage = [[appBundle preferredLocalizations] objectAtIndex:0];
    if ([appLanguage isEqualToString:@"en"]) {
        appLanguage = EZLanguageEnglish;
    }
    
    NSString *copy;
    NSString *edit;
    
    if (!appLanguage) {
        appLanguage = EZConfiguration.shared.firstLanguage;
    }
    
    if ([appLanguage isEqualToString:EZLanguageEnglish]) {
        copy = @"Copy";
        edit = @"Edit";
    }
    NSLog(@"--> App language: %@", appLanguage);
    
    /**
     tell application "System Events"
     tell process "Xcode"
     try
     set editMenu to menu bar item "Edit" of menu bar 1
     on error
     return false
     end try
     if exists editMenu then
     try
     set copyMenuItem to menu item "Copy" of menu 1 of editMenu
     on error
     return false
     end try
     if enabled of copyMenuItem then
     return true
     else
     return false
     end if
     else
     return false
     end if
     end tell
     end tell
     */
    
    /**
     Since the Copy and Edit button title are different in different languages or apps, such as "复制" in Chrome, but "拷贝" in Safari, or "Copy" in English.
     
     So we use the position of the menu item to determine whether the app supports the Copy action.
     
     TODO: Sometimes this method isn't accurate, even some apps copy menu enabled, but cannot click.
     
     */
    //    NSInteger editIndex = 4; // Few Apps eidt index is 3, such as Eudic, QQ Music 🙄
    NSInteger copyIndex = 5; // Note: separator is also a menu item, so the index of Copy is 5.
    
    //    NSRunningApplication *app = [[NSRunningApplication runningApplicationsWithBundleIdentifier:appBundleID] firstObject];
    //    NSString *appName = app.localizedName;
    
    NSString *script = [NSString stringWithFormat:
                        @"set appBundleID to \"%@\"\n"
                        "tell application \"System Events\"\n"
                        "try\n"
                        "    set foundProcess to process 1 whose bundle identifier is appBundleID\n"
                        "on error\n"
                        "    return false\n"
                        "end try\n"
                        "if foundProcess is not missing value then\n"
                        "    tell foundProcess\n"
                        "        set editMenu to missing value\n"
                        "        repeat with menuItem in menu bar 1's menu bar items\n"
                        "            if name of menuItem contains \"编辑\" or name of menuItem contains \"Edit\" then\n"
                        "                set editMenu to menuItem\n"
                        "                exit repeat\n"
                        "            end if\n"
                        "        end repeat\n"
                        "        if editMenu is missing value then\n"
                        "            return false\n"
                        "        end if\n"
                        "        try\n"
                        "            set copyMenuItem to menu item %@ of menu 1 of editMenu\n"
                        "            set menuItemName to name of copyMenuItem\n"
                        "            set menuItemEnabled to enabled of copyMenuItem\n"
                        "            # display dialog menuItemName\n"
                        "            if menuItemName is in {\"复制\", \"拷贝\", \"Copy\"} then\n"
                        "                return menuItemEnabled\n"
                        "            else\n"
                        "                return false\n"
                        "            end if\n"
                        "        on error\n"
                        "            return false\n"
                        "        end try\n"
                        "    end tell\n"
                        "else\n"
                        "    return false\n"
                        "end if\n"
                        "end tell",
                        appBundleID, @(copyIndex)];
    
    //    NSLog(@"checkFrontAppSupportCopyAction:\n%@", script);
    
    NSDate *startTime = [NSDate date];
    
    // NSTask cost 0.18s
    [self.scriptExecutor runAppleScriptWithTask:script completionHandler:^(NSString *_Nonnull result, EZError *_Nonnull error) {
        NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:startTime];
        NSLog(@"NSTask cost: %f seconds", elapsedTime);
        NSLog(@"--> supportCopy: %@", @([result boolValue]));
    }];
    
    // NSAppleScript cost 0.06 ~ 0.12s
    [self.scriptExecutor runAppleScript:script completionHandler:^(NSString *_Nonnull result, EZError *_Nonnull error) {
        BOOL supportCopy = [result boolValue];
        
        NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:startTime];
        NSLog(@"NSAppleScript cost: %f seconds", elapsedTime);
        NSLog(@"result: %@", result);
        
        completion(supportCopy);
    }];
}

@end
