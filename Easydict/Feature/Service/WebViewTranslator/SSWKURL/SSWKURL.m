//
//  SSWKURL.m
//  SSWKURL
//
//  Created by sgcy on 2020/4/21.
//  Copyright © 2020 sgcy. All rights reserved.
//

#import "SSWKURL.h"
#import <objc/runtime.h>
#import "SSCache.h"
#import "SSUtils.h"
#import "SSResourceLoader.h"

@interface WKWebView(handlesURLScheme)


@end

@implementation WKWebView(handlesURLScheme)


+ (BOOL)handlesURLScheme:(NSString *)urlScheme
{
    return NO;
}

@end

#pragma mark -

typedef BOOL (^HTTPDNSCookieFilter)(NSHTTPCookie *, NSURL *);

@interface NSURLRequest(requestId)

@property (nonatomic,assign) BOOL ss_stop;
- (NSString *)requestId;
- (NSString *)requestRepresent;

@end

static char *kNSURLRequestSSTOPKEY = "kNSURLRequestSSTOPKEY";

@implementation NSURLRequest(requestId)

- (BOOL)ss_stop
{
    return [objc_getAssociatedObject(self, kNSURLRequestSSTOPKEY) boolValue];
}

- (void)setSs_stop:(BOOL)ss_stop
{
    objc_setAssociatedObject(self, kNSURLRequestSSTOPKEY, @(ss_stop), OBJC_ASSOCIATION_ASSIGN);
}

- (NSString *)requestId
{
    return [@([self hash]) stringValue];
}

- (NSString *)requestRepresent
{
    return [NSString stringWithFormat:@"%@---%@",self.URL.absoluteString,self.HTTPMethod];
}

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}

+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString *)host {
    
}


@end

#pragma mark -

@interface SSWKTaskDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic,weak) id<WKURLSchemeTask> schemeTask;

@end

@implementation SSWKTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if (error) {
        [self.schemeTask didFailWithError:error];
    }else{
        [self.schemeTask didFinish];
        [[SSCache sharedCache] finishRequestForRequestId:[SSUtils requestIdForRequest:task.currentRequest]];
    }
}

- (void)URLSession:(NSURLSession *)session
      dataTask:(NSURLSessionDataTask *)dataTask
didReceiveData:(NSData *)data
{
    if (dataTask.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    [self.schemeTask didReceiveData:data];
    [[SSCache sharedCache] saveData:data forRequestId:[SSUtils requestIdForRequest:dataTask.currentRequest]];
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler;
{
    if (dataTask.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    [self.schemeTask didReceiveResponse:response];
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
        [[SSCache sharedCache] saveResponseHeaders:httpRes.allHeaderFields forRequestId:[SSUtils requestIdForRequest:dataTask.currentRequest]];

    }
}


@end


#pragma mark -

@interface SSWKURLProtocol()

@property (nonatomic,readwrite,copy) NSURLRequest *request;

@end

@implementation SSWKURLProtocol


@end



@interface SSWKURLHandler:NSObject <WKURLSchemeHandler,NSURLSessionDelegate>

@property (nonatomic,strong) Class protocolClass;
@property (nonatomic,strong) NSURLSession *session;
@property (nonatomic,strong) dispatch_queue_t queue;

@property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;
@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableTaskDelegatesKeyedByTaskIdentifier;
@property (readwrite, nonatomic, strong) NSLock *lock;

@property (nonatomic, strong) AFURLSessionManager *urlSession;


@end


@implementation SSWKURLHandler{
    HTTPDNSCookieFilter cookieFilter;
}

static SSWKURLHandler *sharedInstance = nil;

+ (SSWKURLHandler *)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
        sharedInstance->cookieFilter = ^BOOL(NSHTTPCookie *cookie, NSURL *URL) {
            if ([URL.host containsString:cookie.domain]) {
                return YES;
            }
            return NO;
        };
    });
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.mutableTaskDelegatesKeyedByTaskIdentifier = [[NSMutableDictionary alloc] init];
        [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"https"];

    }
    return self;
}

- (AFURLSessionManager *)urlSession {
    if (!_urlSession) {
        AFURLSessionManager *jsonSession = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];;
        _urlSession = jsonSession;
    }
    return _urlSession;
}


- (NSURLSession *)session
{
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:self.operationQueue];
    }
    return _session;
}


- (dispatch_queue_t)queue
{
    if (!_queue) {
        _queue = dispatch_queue_create("SSWKURLHandler.queue", DISPATCH_QUEUE_SERIAL);
        _queue = dispatch_get_main_queue();
    }
    return _queue;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask
{
//    if (![self.protocolClass isKindOfClass:[SSWKURLProtocol class]]) {
//        @throw [NSException exceptionWithName:@"SSWKURLProtolRegisterFail" reason:@"URLProtocol is not subclass of SSWKURLProtol" userInfo:@{}];
//    }
    NSURLRequest *request = [urlSchemeTask request];
    NSString *url = request.URL.absoluteString;
    NSLog(@"url: %@", url);
    
    NSString *monitorUrl = @"https://www2.deepl.com/jsonrpc?method=LMT_handle_jobs";
    if ([url isEqualToString:monitorUrl]) {
        NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:kNilOptions error:nil];
        NSLog(@"bodyDict: %@", bodyDict);
        
        NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
            
        } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
            
        } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            if ([url isEqualToString:monitorUrl]) {
                NSLog(@"responseObject: %@", responseObject);
            }
            
        }];
        
        [task resume];
    }
    
    
    NSMutableURLRequest *mutaRequest = [request mutableCopy];
    [mutaRequest setValue:[self getRequestCookieHeaderForURL:request.URL] forHTTPHeaderField:@"Cookie"];
    request = [mutaRequest copy];
    
    // Cache
    BOOL shouldCache = YES;
    if (request.HTTPMethod && ![request.HTTPMethod.uppercaseString isEqualToString:@"GET"]) {
        shouldCache = NO;
    }
    NSString *hasAjax = [request valueForHTTPHeaderField:@"X-Requested-With"];
    if (hasAjax != nil) {
        shouldCache = NO;
    }
    
    //
    SSReourceItem *item = [[SSResourceLoader sharedLoader] loadResource:request];
    
    NSDictionary *responseHeaders = [(NSHTTPURLResponse *)item.response allHeaderFields];
    NSString *contentRange = responseHeaders[@"content-range"];
    NSString *contentType = responseHeaders[@"Content-Type"];
    if ([contentType isEqualToString:@"video/mp4"]) {
        shouldCache = NO;
    }
    
    if (item && shouldCache) {
        [urlSchemeTask didReceiveResponse:item.response];
        if (item.data) {
            [urlSchemeTask didReceiveData:item.data];
        }
        [urlSchemeTask didFinish];

    } else {
         NSURLSessionTask *task = [self.session dataTaskWithRequest:request];
         SSWKTaskDelegate *delegate = [[SSWKTaskDelegate alloc] init];
         delegate.schemeTask = urlSchemeTask;
         [self setDelegate:delegate forTask:task];
         [task resume];
    }
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask
{
    dispatch_async(self.queue, ^{
        urlSchemeTask.request.ss_stop = YES;
    });
}

#pragma mark - wkwebview信任https接口
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, card);
    }
}


- (NSArray<NSHTTPCookie *> *)handleHeaderFields:(NSDictionary *)headerFields forURL:(NSURL *)URL {
    NSArray *cookieArray = [NSHTTPCookie cookiesWithResponseHeaderFields:headerFields forURL:URL];
    if (cookieArray.count == 0) {
        return cookieArray;
    }
    if (cookieArray != nil) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in cookieArray) {
            if (cookieFilter(cookie, URL)) {
                [cookieStorage setCookie:cookie];
            }
        }
    }
    return cookieArray;
}

- (NSString *)getRequestCookieHeaderForURL:(NSURL *)URL {
    NSArray *cookieArray = [self searchAppropriateCookies:URL];
    if (cookieArray != nil && cookieArray.count > 0) {
        NSDictionary *cookieDic = [NSHTTPCookie requestHeaderFieldsWithCookies:cookieArray];
        if ([cookieDic objectForKey:@"Cookie"]) {
            return cookieDic[@"Cookie"];
        }
    }
    return nil;
}

- (NSArray *)searchAppropriateCookies:(NSURL *)URL {
    NSMutableArray *cookieArray = [NSMutableArray array];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if (cookieFilter(cookie, URL)) {
            [cookieArray addObject:cookie];
        }
    }
    return cookieArray;
}

#pragma mark - delegate


- (void)setDelegate:(SSWKTaskDelegate *)delegate
            forTask:(NSURLSessionTask *)task
{
    [self.lock lock];
    self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)] = delegate;
    [self.lock unlock];
}

- (SSWKTaskDelegate *)delegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    SSWKTaskDelegate *delegate = nil;
    [self.lock lock];
    delegate = self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)];
    [self.lock unlock];

    return delegate;
}

- (void)removeDelegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    [self.lock lock];
    [self.mutableTaskDelegatesKeyedByTaskIdentifier removeObjectForKey:@(task.taskIdentifier)];
    [self.lock unlock];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    SSWKTaskDelegate *delegate = [self delegateForTask:task];
    [delegate URLSession:session task:task didCompleteWithError:error];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
//    SSWKTaskDelegate *delegate = [self delegateForTask:task];
    SSWKTaskDelegate *delegate = [self delegateForTask:dataTask];
     if (delegate) {
         [self removeDelegateForTask:dataTask];
         [self setDelegate:delegate forTask:downloadTask];
     }

}

- (void)URLSession:(NSURLSession *)session
      dataTask:(NSURLSessionDataTask *)dataTask
didReceiveData:(NSData *)data
{
    SSWKTaskDelegate *delegate = [self delegateForTask:dataTask];
    [delegate URLSession:session dataTask:dataTask didReceiveData:data];
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler;
{
    SSWKTaskDelegate *delegate = [self delegateForTask:dataTask];
    [delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;
    if (completionHandler) {
        completionHandler(disposition);
    }
}

//- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
//                            didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
//                              completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler;
//{
//    NSLog(@"");
//
//}


//}

@end

@implementation WKWebViewConfiguration(ssRegisterURLProtocol)

- (void)ssRegisterURLProtocol:(Class)protocolClass
{
    SSWKURLHandler *handler = [SSWKURLHandler sharedInstance];
    handler.protocolClass = protocolClass;
    [self setURLSchemeHandler:handler forURLScheme:@"https"];
    [self setURLSchemeHandler:handler forURLScheme:@"http"];
}

@end
