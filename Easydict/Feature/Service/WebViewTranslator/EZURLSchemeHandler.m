//
//  EZURLSchemeHandler.m
//  Easydict
//
//  Created by tisfeng on 2022/12/8.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZURLSchemeHandler.h"

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        NSLog(@"--> exception error: %@", exception);
        return exception;
    }
    return nil;
}


typedef BOOL (^HTTPDNSCookieFilter)(NSHTTPCookie *, NSURL *);

@interface NSURLRequest (requestId)

@property (nonatomic, assign) BOOL ss_stop;

- (NSString *)requestId;
- (NSString *)requestRepresent;

@end


static char *kNSURLRequestSSTOPKEY = "kNSURLRequestSSTOPKEY";

@implementation NSURLRequest (requestId)

- (BOOL)ss_stop {
    return [objc_getAssociatedObject(self, kNSURLRequestSSTOPKEY) boolValue];
}

- (void)setSs_stop:(BOOL)ss_stop {
    objc_setAssociatedObject(self, kNSURLRequestSSTOPKEY, @(ss_stop), OBJC_ASSOCIATION_ASSIGN);
}

- (NSString *)requestId {
    return [@([self hash]) stringValue];
}

- (NSString *)requestRepresent {
    return [NSString stringWithFormat:@"%@---%@", self.URL.absoluteString, self.HTTPMethod];
}

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}

+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString *)host {
}


@end


#pragma mark - EZSessionTaskDelegate

@interface EZSessionTaskDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, weak) id<WKURLSchemeTask> schemeTask;

@end

@implementation EZSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    if (task.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    
    if (self.schemeTask.request.ss_stop) {
        NSLog(@"--> This task has already been stopped");
        return;
    }
    
    if (error) {
        tryBlock(^{
            [self.schemeTask didFailWithError:error];
        });
    } else {
        [self.schemeTask didFinish];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (dataTask.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    if (self.schemeTask.request.ss_stop) {
        NSLog(@"--> This task has already been stopped");
        return;
    }
    
    tryBlock(^{
        [self.schemeTask didReceiveData:data];
    });
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    if (dataTask.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    if (self.schemeTask.request.ss_stop) {
        NSLog(@"--> This task has already been stopped");
        return;
    }
    
    tryBlock(^{
        [self.schemeTask didReceiveResponse:response];
    });
}


@end


#pragma mark - EZURLSchemeHandler

typedef void (^EZURLSessionTaskCompletionHandler)(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error);


@interface EZURLSchemeHandler () <WKURLSchemeHandler, NSURLSessionDelegate>

@property (nonatomic, strong) Class protocolClass;
@property (nonatomic, strong) NSURLSession *session;

@property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;
@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableTaskDelegatesKeyedByTaskIdentifier;
@property (readwrite, nonatomic, strong) NSLock *lock;
@property (nonatomic, copy) HTTPDNSCookieFilter cookieFilter;

@property (nonatomic, strong) AFURLSessionManager *urlSession;
@property (nonatomic, strong) NSMutableDictionary<NSString *, EZURLSessionTaskCompletionHandler> *monitorDictionary;

@end


@implementation EZURLSchemeHandler

static EZURLSchemeHandler *_sharedInstance = nil;

/// Hook method +handlesURLScheme
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getClassMethod([WKWebView class], @selector(handlesURLScheme:));
        Method swizzledMethod = class_getClassMethod([self class], @selector(ez_handlesURLScheme:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
    
    [AFHTTPRequestSerializer serializer].timeoutInterval = EZNetWorkTimeoutInterval;
}

+ (BOOL)ez_handlesURLScheme:(NSString *)urlScheme {
    if ([urlScheme isEqualToString:@"https"] || [urlScheme isEqualToString:@"http"]) {
        return NO;
    } else {
        return [self ez_handlesURLScheme:urlScheme];
    }
}

- (instancetype)init {
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.mutableTaskDelegatesKeyedByTaskIdentifier = [[NSMutableDictionary alloc] init];
        [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"https"];
        
        self.monitorDictionary = [NSMutableDictionary dictionary];
        
        self.cookieFilter = ^BOOL(NSHTTPCookie *cookie, NSURL *URL) {
            if ([URL.host containsString:cookie.domain]) {
                return YES;
            }
            return NO;
        };
    }
    return self;
}

- (void)dealloc {
    NSLog(@"dealloc: %@", self);
}

- (AFURLSessionManager *)urlSession {
    if (!_urlSession) {
        AFURLSessionManager *sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", nil];
        sessionManager.responseSerializer = responseSerializer;
        
        _urlSession = sessionManager;
    }
    return _urlSession;
}

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // !!!: The session object keeps a strong reference to the delegate.
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:self.operationQueue];
    }
    return _session;
}

#pragma mark - Publick Methods

- (void)monitorBaseURLString:(NSString *)url completionHandler:(nullable void (^)(NSURLResponse *_Nonnull, id _Nullable, NSError *_Nullable))completionHandler {
    self.monitorDictionary[url] = completionHandler;
}

- (void)removeMonitorBaseURLString:(NSString *)url {
    [self.monitorDictionary removeObjectForKey:url];
}

- (BOOL)containsMonitorBaseURLString:(NSString *)url {
    return [self.monitorDictionary.allKeys containsObject:url];
}

#pragma mark - WKURLSchemeHandler

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    NSURLRequest *request = [urlSchemeTask request];
    NSURL *URL = request.URL;
//        NSLog(@"url: %@", URL.absoluteString);
    
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [mutableRequest setValue:[self getRequestCookieHeaderForURL:request.URL] forHTTPHeaderField:@"Cookie"];
    request = [mutableRequest copy];
    
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request];
    EZSessionTaskDelegate *delegate = [[EZSessionTaskDelegate alloc] init];
    delegate.schemeTask = urlSchemeTask;
    [self setDelegate:delegate forTask:task];
    [task resume];
    
    // Monitor designated url.
    
    /**
     Since Baidu translation API has different URLs for different languages.
     Such as, en -> zh: https://fanyi.baidu.com/v2transapi?from=en&to=zh
     fra -> zh: https://fanyi.baidu.com/v2transapi?from=fra&to=zh
     */
    
    EZURLSessionTaskCompletionHandler completionHandler = [self completionHandlerForMonitorURL:URL];
    if (completionHandler) {
//        NSData *bodyData = request.HTTPBody;
//        if (bodyData) {
//            NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
//            NSData *data = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
//            
//            NSError *error;
//            NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//            if (error) {
//                NSLog(@"error: %@", error);
//            }
//            if (bodyDict) {
//                NSLog(@"HTTPBody dict: %@", bodyDict);
//            } else {
//                NSLog(@"HTTPBody string: %@", bodyString);
//            }
//        }
        
        NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:completionHandler];
        [task resume];
        
        NSString *monitorURL = [self monitorURLForURL:URL];
        if (monitorURL) {
            [self.monitorDictionary removeObjectForKey:monitorURL];
        }
    }
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    dispatch_async(dispatch_get_main_queue(), ^{
        urlSchemeTask.request.ss_stop = YES;
    });
}

#pragma mark -

- (nullable EZURLSessionTaskCompletionHandler)completionHandlerForMonitorURL:(NSURL *)URL {
    // Convert https://fanyi.baidu.com/v2transapi?from=en&to=zh to https://fanyi.baidu.com/v2transapi
    
    NSString *monitorURL = [self monitorURLForURL:URL];
    if (monitorURL) {
        EZURLSessionTaskCompletionHandler completionHandler = self.monitorDictionary[monitorURL];
        return completionHandler;
    }
    return nil;
}

- (nullable NSString *)monitorURLForURL:(NSURL *)URL {
    // Convert https://fanyi.baidu.com/v2transapi?from=en&to=zh to https://fanyi.baidu.com/v2transapi
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
    // Remove url query.
    components.query = nil;
    NSString *baseURLString = components.URL.absoluteString;
    
    for (NSString *monitorURL in self.monitorDictionary.allKeys) {
        if ([monitorURL hasPrefix:baseURLString]) {
            return monitorURL;
        }
    }
    return nil;
}

#pragma mark - wkwebview 信任 https 接口

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *_Nullable credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *card = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
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
            if (self.cookieFilter(cookie, URL)) {
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
        if (self.cookieFilter(cookie, URL)) {
            [cookieArray addObject:cookie];
        }
    }
    return cookieArray;
}


#pragma mark - delegate

- (void)setDelegate:(EZSessionTaskDelegate *)delegate
            forTask:(NSURLSessionTask *)task {
    [self.lock lock];
    self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)] = delegate;
    [self.lock unlock];
}

- (EZSessionTaskDelegate *)delegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    EZSessionTaskDelegate *delegate = nil;
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
didCompleteWithError:(NSError *)error {
    if (task.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    
    EZSessionTaskDelegate *delegate = [self delegateForTask:task];
    [delegate URLSession:session task:task didCompleteWithError:error];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    if (dataTask.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    
    EZSessionTaskDelegate *delegate = [self delegateForTask:dataTask];
    if (delegate) {
        [self removeDelegateForTask:dataTask];
        [self setDelegate:delegate forTask:downloadTask];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (dataTask.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    
    EZSessionTaskDelegate *delegate = [self delegateForTask:dataTask];
    [delegate URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    if (dataTask.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    
    EZSessionTaskDelegate *delegate = [self delegateForTask:dataTask];
    [delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;
    if (completionHandler) {
        completionHandler(disposition);
    }
}

@end
