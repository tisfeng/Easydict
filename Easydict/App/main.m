//
//  main.m
//  Easydict
//
//  Created by tisfeng on 2022/10/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZWindowManager.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        
        // easydict good
        for (int i = 0; i < argc; i++) {
//            printf("Argument %d: %s\n", i, argv[i]);
        }
    }
    
    if (argc == 2) {
        // get the second arg, convert to nsstring
        NSString *queryText = [NSString stringWithUTF8String:argv[1]];
        printf("easydict query: %s\n", argv[1]);
        
        EZBaseQueryViewController *viewController = EZWindowManager.shared.fixedWindow.queryViewController;
        [viewController startQueryText:queryText actionType:EZActionTypeInputQuery];
    }
        
    return NSApplicationMain(argc, argv);
}
