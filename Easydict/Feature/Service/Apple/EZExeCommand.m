//
//  EZAppleScript.m
//  Easydict
//
//  Created by tisfeng on 2023/1/6.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZExeCommand.h"

@implementation EZExeCommand

/// Run AppleScript
- (void)runAppleScript:(NSString *)script completionHandler:(void (^)(NSString *result))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/osascript";
        task.arguments = @[@"-e", script];
        
        NSPipe *pipe = [NSPipe pipe];
        task.standardOutput = pipe;
        [task launch];
        
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *result = [output trim];
        NSLog(@"Apple translate result: %@", result);
        completionHandler(result);
    });
}

- (NSString *)shortcutsAppleScript:(NSString *)shortcutName parameters:(NSDictionary *)parameters {
    NSString *queryString = AFQueryStringFromParameters(parameters);
    NSString *appleScript = [NSString stringWithFormat:@"tell application \"Shortcuts Events\" \n run the shortcut named \"%@\" with input \"%@\" \n end tell", shortcutName, queryString];
    
    return appleScript;
}

- (void)runShortcut:(NSString *)shortcutName
         parameters:(NSDictionary *)parameters
  completionHandler:(void (^)(NSString *result))completionHandler {
    // @"tell application \"Shortcuts Events\" \n run the shortcut named \"Easydict-Translate-V1.2.0\" with input \"text=apple&from=en_US&to=zh_CN\" \n end tell"
    NSString *appleScript = [self shortcutsAppleScript:shortcutName parameters:parameters];
    [self runAppleScript:appleScript completionHandler:completionHandler];
}

- (void)runTranslateShortcut:(NSDictionary *)parameters
  completionHandler:(void (^)(NSString *result))completionHandler {
    NSString *appleScript = [self shortcutsAppleScript:@"Easydict-Translate-V1.2.0" parameters:parameters];
    [self runAppleScript:appleScript completionHandler:completionHandler];
}

@end
