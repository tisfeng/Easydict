//
//  main.m
//  Easydict
//
//  Created by tisfeng on 2022/10/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZWindowManager.h"
#import "Easydict-Swift.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        
        NSMutableArray<NSString *> *arguments = [NSMutableArray array];
        
        // easydict good
        for (int i = 0; i < argc; i++) {
            NSString *argument = [NSString stringWithUTF8String:argv[i]];
            [arguments addObject:argument];
            //            printf("Argument %d: %s\n", i, argv[i]);
        }
        
        MyArgumentParser *argumentParser = [[MyArgumentParser alloc] init];
        [argumentParser runAndReturnError:nil];
        
        if (argc > 1) {

            // get the second arg, convert to nsstring
            NSString *queryText = arguments[1];
            printf("easydict query: %s\n", [queryText UTF8String]);

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                 [EZWindowManager.shared showFloatingWindowType:EZWindowTypeFixed queryText:@"good"];
            });
        }
    }
    
    return NSApplicationMain(argc, argv);
}
