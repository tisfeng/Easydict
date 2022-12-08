//
//  EZURLSchemeHandler.m
//  Easydict
//
//  Created by tisfeng on 2022/12/8.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZURLSchemeHandler.h"

@interface EZURLSchemeHandler ()

@property (nonatomic, strong) AFURLSessionManager *urlSession;

@end

@implementation EZURLSchemeHandler

- (AFURLSessionManager *)urlSession {
    if (!_urlSession) {
        AFURLSessionManager *jsonSession = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];;
        _urlSession = jsonSession;
    }
    return _urlSession;
}


- (void)webView:(WKWebView *)webView startURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask {
    NSURLRequest *request = [urlSchemeTask request];
    NSString *url = request.URL.absoluteString;
    NSLog(@"url: %@", url);
    
    NSString *monitorUrl = @"https://www2.deepl.com/jsonrpc?method=LMT_handle_jobs";
    
    if ([url isEqualToString:monitorUrl]) {
        NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:kNilOptions error:nil];
        NSLog(@"bodyDict: %@", bodyDict);
    }
    
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if ([url isEqualToString:monitorUrl]) {
            NSLog(@"responseObject: %@", responseObject);
        }
        
        [urlSchemeTask didReceiveResponse:response];
        [urlSchemeTask didReceiveData:responseObject];
        [urlSchemeTask didFinish];
    }];
    
    [task resume];
}




- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getClassMethod([WKWebView class], @selector(handlesURLScheme:));
        Method swizzledMethod = class_getClassMethod([self class], @selector(qm_handlesURLScheme:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

+ (BOOL)qm_handlesURLScheme:(NSString *)urlScheme
{
    if ([urlScheme isEqualToString:@"https"] || [urlScheme isEqualToString:@"http"])
    {
        return NO;
    }
    else
    {
        return [self qm_handlesURLScheme:urlScheme];
    }
}

@end
