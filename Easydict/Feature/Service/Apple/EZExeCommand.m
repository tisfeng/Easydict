//
//  EZAppleScript.m
//  Easydict
//
//  Created by tisfeng on 2023/1/6.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZExeCommand.h"
#import "EZTranslateError.h"

@implementation EZExeCommand

/// Run AppleScript
- (void)runAppleScript:(NSString *)script completionHandler:(void (^)(NSString *result, NSError *error))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/osascript";
        task.arguments = @[ @"-e", script ];

        NSPipe *outputPipe = [NSPipe pipe];
        task.standardOutput = outputPipe;
        NSPipe *errorPipe = [NSPipe pipe];
        task.standardError = errorPipe;

        NSString *result;
        // This method can only catch errors inside the NSTask object, and the error of executing the task needs to be used with standardError.
        NSError *error;
        if ([task launchAndReturnError:&error]) {
            NSData *data = [[outputPipe fileHandleForReading] readDataToEndOfFile];
            NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            result = [output trim];
            NSLog(@"Apple translate result: %@", result);
        }

        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        NSString *errorString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
        if (task.terminationStatus != 0) {
            // 34:114: execution error: “Shortcuts Events”遇到一个错误：不能获得“shortcut "123abc"”。 (-1728)
            errorString = [errorString trim];
            NSArray *array = [errorString componentsSeparatedByString:@"execution error: "];
            if (array.count > 1) {
                errorString = [array[1] trim];
                error = [EZTranslateError errorWithString:errorString];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(result, error);
        });
    });
}

- (NSString *)shortcutsAppleScript:(NSString *)shortcutName parameters:(NSDictionary *)parameters {
    NSString *queryString = AFQueryStringFromParameters(parameters);
    NSString *appleScript = [NSString stringWithFormat:@"tell application \"Shortcuts Events\" \n run the shortcut named \"%@\" with input \"%@\" \n end tell", shortcutName, queryString];

    return appleScript;
}

- (void)runShortcut:(NSString *)shortcutName
           parameters:(NSDictionary *)parameters
    completionHandler:(void (^)(NSString *result, NSError *error))completionHandler {
    // @"tell application \"Shortcuts Events\" \n run the shortcut named \"Easydict-Translate-V1.2.0\" with input \"text=apple&from=en_US&to=zh_CN\" \n end tell"
    NSString *appleScript = [self shortcutsAppleScript:shortcutName parameters:parameters];
    [self runAppleScript:appleScript completionHandler:completionHandler];
}

- (void)runTranslateShortcut:(NSDictionary *)parameters
           completionHandler:(void (^)(NSString *result, NSError *error))completionHandler {
    NSString *appleScript = [self shortcutsAppleScript:@"Easydict-Translate-V1.2.0" parameters:parameters];
    [self runAppleScript:appleScript completionHandler:completionHandler];
}

@end
