//
//  EZAppleScript.h
//  Easydict
//
//  Created by tisfeng on 2023/1/6.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZError.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^AppleScriptCompletionHandler)( NSString *_Nullable result, EZError *_Nullable error);

@interface EZScriptExecutor : NSObject

/// Run translate shortcut with parameters.
- (NSTask *)runTranslateShortcut:(NSDictionary *)parameters
               completionHandler:(void (^)(NSString *result, EZError *error))completionHandler;

/// Run shortcut with parameters.
- (NSTask *)runShortcut:(NSString *)shortcutName
             parameters:(NSDictionary *)parameters
      completionHandler:(void (^)(NSString *result, EZError *error))completionHandler;

/// Use NSTask to run AppleScript.
- (NSTask *)runAppleScriptWithTask:(NSString *)script completionHandler:(void (^)(NSString *result, EZError *error))completionHandler;

- (void)runAppleScript:(NSString *)script completionHandler:(void (^)(NSString *result, EZError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END
