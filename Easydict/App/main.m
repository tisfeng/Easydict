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
#import "XPMArguments.h"
#include <stdio.h>
#include <sys/ioctl.h>

void queryText(NSString *text) {
    // ???: need to wait AppDelegate loaded.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [EZWindowManager.shared showFloatingWindowType:EZWindowTypeFixed queryText:text];
    });
}

void parseArmguments(void) {
    XPMArgumentSignature
    *helpSig = [XPMArgumentSignature argumentSignatureWithFormat:@"[-h --help]"],
    *queryTextSig = [XPMArgumentSignature argumentSignatureWithFormat:@"[-q --queryText]="];
    
    NSArray *signatures = @[ helpSig, queryTextSig ];
    
    XPMArgumentPackage *arguments = [[NSProcessInfo processInfo] xpmargs_parseArgumentsWithSignatures:signatures];
    
    bool print_help = false;
    
    if ([arguments booleanValueForSignature:helpSig]) {
        print_help = true;
    } else {
        NSString *text = [[arguments firstObjectForSignature:queryTextSig] description];
        NSLog(@"queryText: %@", text);
        
        if (text) {
            queryText(text);
        }
    }
    
    if (print_help) {
        struct winsize ws;
        ioctl(0, TIOCGWINSZ, &ws);
        
        printf("Example program:\n");
        printf("  %s Query text\n", [[queryTextSig descriptionForHelpWithIndent:2 terminalWidth:(NSUInteger)ws.ws_col] UTF8String]);
    }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        
        NSMutableArray<NSString *> *arguments = [NSMutableArray array];
        
        // easydict -query
        for (int i = 0; i < argc; i++) {
            NSString *argument = [NSString stringWithUTF8String:argv[i]];
            [arguments addObject:argument];
            //            printf("Argument %d: %s\n", i, argv[i]);
        }
        
        NSLog(@"arguments: %@", arguments);
        
//        MyArgumentParser *argumentParser = [[MyArgumentParser alloc] init];
//        [argumentParser runAndReturnError:nil];
        
        parseArmguments();
    }
    
    return NSApplicationMain(argc, argv);
}
