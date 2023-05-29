//
//  AppDelegate+EZURLScheme.m
//  Easydict
//
//  Created by tisfeng on 2023/5/29.
//  Copyright © 2023 izual. All rights reserved.
//

#import "AppDelegate+EZURLScheme.h"
#import <JLRoutes.h>
#import "EZWindowManager.h"
#import "EZSchemeParser.h"

@implementation AppDelegate (EZURLScheme)

- (void)registerRouters {
    // Reigster URL Scheme handler.
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    EZWindowManager *windowManager = [EZWindowManager shared];
    
    JLRoutes *routes = [JLRoutes globalRoutes];
    [routes addRoute:@"/:action" handler:^BOOL(NSDictionary *parameters) {
        NSString *action = parameters[@"action"];
        
        // easydict://query?text=good
        if ([action isEqualToString:EZQueryKey]) {
            NSString *queryText = parameters[@"text"];
            
            [windowManager showFloatingWindowType:EZWindowTypeFixed queryText:queryText];
        }

        return YES; // return YES to say we have handled the route
    }];
}

#pragma mark -

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSURL *URL = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    
    // easydict://query?text=good
    if ([URL.scheme isEqualToString:EZEasydictScheme]) {
        NSLog(@"handle URL: %@", URL);
    }
    
    [JLRoutes routeURL:URL];
}

@end
