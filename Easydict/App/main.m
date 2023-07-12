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

static void delay_block(dispatch_block_t block) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        block();
    });
}

void queryText(NSString *text) {
    // ???: need to wait AppDelegate loaded.
    delay_block(^{
        [EZWindowManager.shared showFloatingWindowType:EZWindowTypeFixed queryText:text];
    });
}

void parseArmguments(void) {
    XPMArgumentSignature
    *helpSig = [XPMArgumentSignature argumentSignatureWithFormat:@"[-h --help]"],
    *detectTextSig = [XPMArgumentSignature argumentSignatureWithFormat:@"[-d --detectText]="],
    *queryTextSig = [XPMArgumentSignature argumentSignatureWithFormat:@"[-q --queryText]="];
    
    NSArray *signatures = @[ helpSig, detectTextSig, queryTextSig ];
    
    XPMArgumentPackage *arguments = [[NSProcessInfo processInfo] xpmargs_parseArgumentsWithSignatures:signatures];
    
    bool print_help = false;
    
    if ([arguments booleanValueForSignature:helpSig]) {
        print_help = true;
    } else {
        NSString *query_text = [[arguments firstObjectForSignature:queryTextSig] description];
        if (query_text) {
            NSLog(@"queryText: %@", query_text);
            queryText(query_text);
        }
        
        NSString *detect_text = [[arguments firstObjectForSignature:detectTextSig] description];
        if (detect_text) {
            NSLog(@"detectText: %@", detect_text);
        }
        
        if (detect_text) {
            delay_block(^{
                [EZWindowManager.shared detectQueryText:detect_text completion:^(NSString * _Nonnull language) {
                    printf("%s\n", [language UTF8String]);
                }];
            });
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
