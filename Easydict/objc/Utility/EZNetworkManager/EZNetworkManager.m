//
//  EZNetworkManager.m
//  Easydict
//
//  Created by tisfeng on 2023/4/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZNetworkManager.h"

@interface EZNetworkManager ()

@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;

@end

@implementation EZNetworkManager

- (AFHTTPSessionManager *)htmlSession {
    if (!_htmlSession) {
        AFHTTPSessionManager *htmlSession = [AFHTTPSessionManager manager];
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        htmlSession.requestSerializer = requestSerializer;
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
        htmlSession.responseSerializer = responseSerializer;

        _htmlSession = htmlSession;
    }
    return _htmlSession;
}

/// Request cookie of URL.
- (void)requestCookieOfURL:(NSString *)URL cookieName:(NSString *)cookieName completion:(void (^)(NSString *))completion {
    [self.htmlSession GET:URL parameters:nil progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:URL]];
        NSString *cookieString = @"";
        for (NSHTTPCookie *cookie in cookies) {
            if ([cookie.name isEqualToString:cookieName]) {
                cookieString = [NSString stringWithFormat:@"%@=%@; domain=%@; expires=%@", cookie.name, cookie.value, cookie.domain, cookie.expiresDate];
                break;
            }
        }
//        MMLogError(@"get cookie of URL: %@", URL);
//        MMLogError(@"cookie: %@", cookieString);
                
        completion(cookieString);
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        MMLogError(@"request cookie error: %@", error);
    }];
}

@end
