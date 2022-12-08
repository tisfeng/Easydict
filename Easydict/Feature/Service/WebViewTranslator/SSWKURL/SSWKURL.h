//
//  SSWKURL.h
//  SSWKURL
//
//  Created by sgcy on 2020/4/21.
//  Copyright © 2020 sgcy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>


@interface SSWKURLProtocol:NSObject

@property (nonatomic,readonly,copy) NSURLRequest *request;

+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;
- (void)startLoading:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
- (void)stopLoading;

@end


@interface WKWebViewConfiguration(ssRegisterURLProtocol)

- (void)ssRegisterURLProtocol:(Class)protocolClass;

@end
