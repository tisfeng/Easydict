//
//  EZAppleScript.m
//  Easydict
//
//  Created by tisfeng on 2023/1/6.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZScriptExecutor.h"
#import "EZError.h"
#import "EZToast.h"

static NSString *const kEasydictTranslatShortcutName = @"Easydict-Translate-V1.2.0";

@implementation EZScriptExecutor

/// Run translate shortcut with parameters.
- (NSTask *)runTranslateShortcut:(NSDictionary *)parameters completionHandler:(void (^)(NSString *result, EZError *error))completionHandler {
    return [self runShortcut:kEasydictTranslatShortcutName parameters:parameters completionHandler:completionHandler];
}

/// Run shortcut with parameters.
- (NSTask *)runShortcut:(NSString *)shortcutName
             parameters:(NSDictionary *)parameters
      completionHandler:(void (^)(NSString *result, EZError *error))completionHandler {
    /**
     tell application "Shortcuts Events"
        run the shortcut named "Easydict-Translate-V1.2.0" with input "text=apple&from=en_US&to=zh_CN"
     end tell
     
     @"tell application \"Shortcuts Events\" \n run the shortcut named \"Easydict-Translate-V1.2.0\" with input \"text=apple&from=en_US&to=zh_CN\" \n end tell"
     */
    NSString *appleScript = [self shortcutsAppleScript:shortcutName parameters:parameters];
    return [self runAppleScriptWithTask:appleScript completionHandler:completionHandler];
}

/// Use NSTask to run AppleScript.
- (NSTask *)runAppleScriptWithTask:(NSString *)script completionHandler:(void (^)(NSString *result, EZError *error))completionHandler {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/osascript";
    task.arguments = @[ @"-e", script ];
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSPipe *outputPipe = [NSPipe pipe];
        task.standardOutput = outputPipe;
        NSPipe *errorPipe = [NSPipe pipe];
        task.standardError = errorPipe;
        
        NSString *result = @"";
        // This method can only catch errors inside the NSTask object, and the error of executing the task needs to be used with standardError.
        EZError *error;
        if ([task launchAndReturnError:&error]) {
            NSData *data = [[outputPipe fileHandleForReading] readDataToEndOfFileAndReturnError:&error];
            // ???: This method value may be incorrect, read bool "true" from pipe.
//            data = [[outputPipe fileHandleForReading] readDataToEndOfFile];
            NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            result = [output trim];
//            NSLog(@"Apple translate result: %@", result);
        }
        
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        NSString *errorString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
        
        if (error) {
            errorString = [error localizedDescription];
        }
        
        //  *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[NSConcreteTask terminationStatus]: task still running'
        if (errorString.length) {
            // 34:114: execution error: “Shortcuts Events”遇到一个错误：不能获得“shortcut "123abc"”。 (-1728)
            errorString = [errorString trim];
            NSArray *array = [errorString componentsSeparatedByString:@"execution error: "];
            if (array.count > 1) {
                errorString = [array[1] trim];
                EZErrorType type = EZErrorTypeAPI;
                if ([errorString containsString:kEasydictTranslatShortcutName]) {
                    type = EZErrorTypeParam;
                }
                error = [EZError errorWithType:type description:errorString];
            }
        }
        
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        NSLog(@"run AppleScript Task cost: %.1f ms", (endTime - startTime) * 1000);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(result, error);
        });
    });
    return task;
}

/// Use NSAppleScript to run AppleScript, faster than NSTask.
/// !!!: Note that this method may fail due to execution permissions, it will not automatically apply for permissions when I test.
- (void)runAppleScript:(NSString *)script completionHandler:(void (^)(NSString *result, EZError *error))completionHandler {
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            EZError *error = nil;
            NSDictionary *errorInfo = nil;
            // ???: Sometimes it will crash in this line
            NSAppleEventDescriptor *result = [appleScript executeAndReturnError:&errorInfo];
            NSString *resultString = [result stringValue];
            resultString = [resultString trim];
            if (errorInfo) {
                MMLogInfo(@"runAppleScript errorInfo: %@", errorInfo);
                NSString *errorString = errorInfo[NSAppleScriptErrorMessage];
                EZErrorType type = EZErrorTypeAPI;
                if ([errorString containsString:kEasydictTranslatShortcutName]) {
                    type = EZErrorTypeParam;
                }
                error = [EZError errorWithType:type description:errorString];
            }
            
            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
            NSLog(@"run AppleScript cost: %.1f ms", (endTime - startTime) * 1000);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(resultString, error);
            });
        } @catch (NSException *exception) {
            MMLogInfo(@"exception: %@", exception);
            [self runAppleScriptWithTask:script completionHandler:completionHandler];
             
#if Debug
            [EZToast showToast:exception.reason];
#endif
        }
    });
}

- (NSString *)shortcutsAppleScript:(NSString *)shortcutName parameters:(NSDictionary *)parameters {
    NSString *queryString = AFQueryStringFromParameters(parameters);
    NSString *appleScript = [NSString stringWithFormat:@"tell application \"Shortcuts Events\" \n run the shortcut named \"%@\" with input \"%@\" \n end tell", shortcutName, queryString];
    
    return appleScript;
}

@end
