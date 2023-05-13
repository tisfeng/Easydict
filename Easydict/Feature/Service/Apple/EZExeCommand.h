//
//  EZAppleScript.h
//  Easydict
//
//  Created by tisfeng on 2023/1/6.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AppleScriptCompletionHandler)( NSString *_Nullable result, NSError *_Nullable error);

@interface EZExeCommand : NSObject

/// Run translate shortcut with parameters.
- (NSTask *)runTranslateShortcut:(NSDictionary *)parameters
               completionHandler:(void (^)(NSString *result, NSError *error))completionHandler;

/// Run shortcut with parameters.
- (NSTask *)runShortcut:(NSString *)shortcutName
             parameters:(NSDictionary *)parameters
      completionHandler:(void (^)(NSString *result, NSError *error))completionHandler;

/// Use NSTask to run AppleScript.
- (NSTask *)runAppleScriptWithTask:(NSString *)script completionHandler:(void (^)(NSString *result, NSError *error))completionHandler;

- (void)runAppleScript:(NSString *)script completionHandler:(void (^)(NSString *result, NSError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END
