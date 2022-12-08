//
//  SSResourceLoader.m
//  SSWKURLDemo
//
//  Created by sgcy on 2021/1/20.
//  Copyright © 2021 sgcy. All rights reserved.
//

#import "SSResourceLoader.h"
#import "SSCache.h"
#import "SSUtils.h"

@implementation SSReourceItem

@end


@interface SSResourceLoader()<NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic,strong) NSMutableData *data;
@property (nonatomic,strong) NSURLResponse *response;

@end

@implementation SSResourceLoader

+ (instancetype)sharedLoader
{
    static SSResourceLoader *defaultLoader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultLoader = [[self alloc]init];
    });
    return defaultLoader;
}

- (SSReourceItem *)loadResource:(NSURLRequest *)request
{
    //load from cache
    NSString *requestId = [SSUtils requestIdForRequest:request];
    NSDictionary *responseHeaders = [[SSCache sharedCache] responseHeadersWithRequestID:requestId];
    if (responseHeaders) {
        SSReourceItem *item = [[SSReourceItem alloc] init];
        NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc]initWithURL:request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:responseHeaders];
        item.response = resp;
        NSData *data = [[SSCache sharedCache] dataForRequestId:requestId];
        if (data) {
            item.data = data;
        }
        return item;
    }else{
        return nil;
    }
}

- (void)preloadResourceWithRequest:(NSURLRequest *)request
{
    //preload from cache
    SSReourceItem *item = [self loadResource:request];
    //preload from network
    if (!item) {
        
    }
}

@end
