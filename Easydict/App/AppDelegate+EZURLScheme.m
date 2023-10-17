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
        NSString *queryText = parameters[@"text"];
        /**
         easydict://good
         easydict://query?text=good
         
         easydictd://good
         easydictd://query?text=good
         easydictd://good%2Fgirl  (easydictd://good/girl)
         */
        if (!([action isEqualToString:EZQueryKey] && queryText.length)) {
            queryText = action;
        }
        [windowManager showFloatingWindowType:EZWindowTypeFixed queryText:queryText actionType:EZActionTypeInvokeQuery];
        
        return YES; // return YES to say we have handled the route
    }];
    
    [routes addRoute:@"*" handler:^BOOL(NSDictionary *parameters) {
        NSLog(@"parameters: %@", parameters);
        
        NSURL *URL = parameters[JLRouteURLKey];
        NSLog(@"URL: %@", URL);
        
//        NSString *queryText = [URL.resourceSpecifier stringByReplacingOccurrencesOfString:@"//" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, 2)];
//        [windowManager showFloatingWindowType:EZWindowTypeFixed queryText:queryText];
        
        return YES;
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
