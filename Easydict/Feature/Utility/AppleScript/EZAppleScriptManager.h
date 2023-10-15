//
//  EZAppleScript.h
//  Easydict
//
//  Created by tisfeng on 2023/10/15.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZScriptExecutor.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZAppleScriptManager : NSObject

+ (instancetype)shared;

- (BOOL)isKnownBrowser:(NSString *)bundleID;

/// Simulate key event.
void postKeyboardEvent(CGEventFlags flags, CGKeyCode virtualKey, bool keyDown);


#pragma mark - Replace Brower selected text

- (void)replaceBrowserSelectedText:(NSString *)replacementString
                          bundleID:(NSString *)bundleID
                        completion:(AppleScriptCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
