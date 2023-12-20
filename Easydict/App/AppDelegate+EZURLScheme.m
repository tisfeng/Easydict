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
#import "EZConfiguration.h"

@implementation AppDelegate (EZURLScheme)

- (void)registerRouters {
    // Reigster URL Scheme handler.
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass
                            andEventID:kAEGetURL];
    
    JLRoutes *routes = [JLRoutes globalRoutes];
    [routes addRoute:@"/:action" handler:^BOOL(NSDictionary *parameters) {
        NSString *action = parameters[@"action"];
        NSString *queryText = parameters[@"text"];
        NSURL *URL = parameters[JLRouteURLKey];
        
        /**
         Recommend use easydict://query?text=xxx, easydict://xxx is a bit ambiguous and complex.
         
         easydict://good
         easydict://query?text=good
         easydict://good%2Fgirl  (easydict://good/girl)
         */
        if (!([action isEqualToString:EZQueryKey] && queryText.length)) {
            // Ukraine may get another Patriot battery.
            if (action.length == 0) {
                /**
                 !!!: action may be nil if URL contains '.'
                 FIX https://github.com/tisfeng/Easydict/issues/207#issuecomment-1786267017
                 */
                queryText = [self extractQueryTextFromURL:URL];
            } else {
                queryText = action;
            }
        }
        [self showFloatingWindowAndAutoQueryText:queryText];
        
        return YES; // return YES to say we have handled the route
    }];
    
    // good / girl
    [routes addRoute:@"*" handler:^BOOL(NSDictionary *parameters) {
        NSLog(@"parameters: %@", parameters);
        
        NSURL *URL = parameters[JLRouteURLKey];
        NSLog(@"URL: %@", URL);
        
        NSString *queryText = [self extractQueryTextFromURL:URL];
        [self showFloatingWindowAndAutoQueryText:queryText];
        
        return YES;
    }];
}

#pragma mark -

- (void)showFloatingWindowAndAutoQueryText:(NSString *)text {
    EZWindowManager *windowManager = [EZWindowManager shared];
    EZWindowType windowType = EZConfiguration.shared.shortcutSelectTranslateWindowType;

    [windowManager showFloatingWindowType:windowType
                                queryText:text.trim
                                autoQuery:YES
                               actionType:EZActionTypeInvokeQuery];
}

/// Get query text from url scheme, easydict://good%2Fgirl --> good%2Fgirl
- (NSString *)extractQueryTextFromURL:(NSURL *)URL {
    NSString *queryText = [URL.resourceSpecifier stringByReplacingOccurrencesOfString:@"//" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, 2)];
    return queryText.decode;
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    /**
     hello, #girl, good
     
     We need to encode the URL to avoid JLRoutes routing failures. PopClip
     
     ---
     
     urlString may have been encoded, so we need to check it.
     
     https://github.com/tisfeng/Easydict/issues/78#issuecomment-1862752708
     */
    NSURL *URL = [NSURL URLWithString:urlString.encodeSafely];
    
    // easydict://query?text=good, easydict://query?text=你好
    if ([URL.scheme containsString:EZEasydictScheme]) {
        NSLog(@"handle URL: %@", URL);
    }
    
    [JLRoutes routeURL:URL];
}

@end
