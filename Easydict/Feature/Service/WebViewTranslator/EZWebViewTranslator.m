//
//  EZBaiduWebTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/4.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZWebViewTranslator.h"
#import <WebKit/WebKit.h>
#import "EZURLSchemeHandler.h"
#import "EZTranslateError.h"

// Delay query seconds
static NSTimeInterval const DELAY_SECONDS = 0.1; // Usually takes more than 0.1 seconds.

@interface EZWebViewTranslator () <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) EZURLSchemeHandler *urlSchemeHandler;

@property (nonatomic, copy) NSString *queryURL;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, copy) void (^completionHandler)(NSArray<NSString *> *_Nullable, NSError *);

@end


@implementation EZWebViewTranslator

- (EZURLSchemeHandler *)urlSchemeHandler {
    if (!_urlSchemeHandler) {
        _urlSchemeHandler = [[EZURLSchemeHandler alloc] init];
    }
    return _urlSchemeHandler;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKPreferences *preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = NO;
        configuration.preferences = preferences;
        [configuration setURLSchemeHandler:self.urlSchemeHandler forURLScheme:@"https"];
        
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        _webView = webView;
        webView.navigationDelegate = self;
        
        NSString *cookieString = @"APPGUIDE_10_0_2=1; REALTIME_TRANS_SWITCH=1; FANYI_WORD_SWITCH=1; HISTORY_SWITCH=1; SOUND_SPD_SWITCH=1; SOUND_PREFER_SWITCH=1; ZD_ENTRY=google; BAIDUID=483C3DD690DBC65C6F133A670013BF5D:FG=1; BAIDUID_BFESS=483C3DD690DBC65C6F133A670013BF5D:FG=1; newlogin=1; BDUSS=50ZnpUNG93akxsaGZZZ25tTFBZZEY4TzQ2ZG5ZM3FVaUVPS0J-M2JVSVpvNXBqSVFBQUFBJCQAAAAAAAAAAAEAAACFn5wyus3Jz7Xb1sD3u9fTMjkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABkWc2MZFnNjSX; BDUSS_BFESS=50ZnpUNG93akxsaGZZZ25tTFBZZEY4TzQ2ZG5ZM3FVaUVPS0J-M2JVSVpvNXBqSVFBQUFBJCQAAAAAAAAAAAEAAACFn5wyus3Jz7Xb1sD3u9fTMjkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABkWc2MZFnNjSX; Hm_lvt_64ecd82404c51e03dc91cb9e8c025574=1670083644; Hm_lvt_afd111fa62852d1f37001d1f980b6800=1670084751; Hm_lpvt_afd111fa62852d1f37001d1f980b6800=1670084751; Hm_lpvt_64ecd82404c51e03dc91cb9e8c025574=1670166705";
        
        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:@{
            NSHTTPCookieName : @"Cookie",
            NSHTTPCookieValue : cookieString,
        }];
        
        WKHTTPCookieStore *cookieStore = webView.configuration.websiteDataStore.httpCookieStore;
        [cookieStore setCookie:cookie completionHandler:^{
            // cookie 设置完成
        }];
        
        // custom UserAgent.
        [webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id obj, NSError *error) {
            if (error) {
                return;
            }
            [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent" : EZUserAgent}];
        }];
    }
    return _webView;
}


#pragma mark - Publick Methods

/// Preload url.
- (void)preloadURL:(NSString *)URL {
    [self loadURL:URL];
}

/// Monitor designated url request when load url.
- (void)monitorBaseURLString:(NSString *)monitorURL
                     loadURL:(NSString *)URL
           completionHandler:(void (^)(NSURLResponse *_Nonnull, id _Nullable, NSError *_Nullable))completionHandler {
    if (!URL.length || !monitorURL.length) {
        NSLog(@"loadURL or monitorURL cannot be emtpy");
        return;
    }
    
    [self.urlSchemeHandler monitorBaseURLString:monitorURL completionHandler:completionHandler];
    [self loadURL:URL];
    
    // Handle timeout.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(EZNetWorkTimeoutInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.urlSchemeHandler containsMonitorBaseURLString:monitorURL]) {
            [self.urlSchemeHandler removeMonitorBaseURLString:monitorURL];
            
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:monitorURL] statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Type": @"application/json"}];
            completionHandler(response, nil, [EZTranslateError timeoutError]);
        }
    });
}

/// Query webView rranslate url result.
- (void)queryTranslateURL:(NSString *)URL
        completionHandler:(nullable void (^)(NSArray<NSString *> *_Nullable, NSError *))completionHandler {
    if (self.querySelector.length == 0) {
        NSLog(@"querySelector is empty, url: %@", URL);
        return;
    }
    
    [self loadURL:URL];
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    if (URL.length && completionHandler) {
        mm_weakify(self);
        self.queryURL = URL;
        self.retryCount = 0;
        self.completionHandler = ^(NSArray<NSString *> *texts, NSError *error) {
            mm_strongify(self);
            
            if (error) {
                completionHandler(nil, error);
            } else {
                completionHandler(texts, nil);
                CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
                NSLog(@"webView cost: %.1f ms", (endTime - startTime) * 1000); // cost ~2s
            }
            
            // !!!: When finished, set completion to nil, and
            self.completionHandler = nil;
            self.queryURL = nil;
            
            // ???: reset webView.
            [self.webView loadHTMLString:@"" baseURL:nil];
        };
    }
}

#pragma mark -

- (void)loadURL:(NSString *)URL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]];
    // !!!: Set up User-Agent to ensure that the HTML elements are consistent with the Mac side for easy parsing of UI elements
    [request setValue:EZUserAgent forHTTPHeaderField:@"User-Agent"];
    
    [self.webView loadRequest:request];
    self.queryURL = URL;
    NSLog(@"query url: %@", URL);
}

- (void)getTextContentOfElement:(NSString *)selector
                     completion:(void (^)(NSArray<NSString *> *_Nullable, NSError *))completion {
    NSLog(@"get result count: %ld", self.retryCount + 1);
    
    // 打印页面 HTML： document.documentElement.outerHTML
    NSString *checkIfElementExist = [NSString stringWithFormat:@"document.querySelector('%@') != null", selector];
    [self.webView evaluateJavaScript:checkIfElementExist completionHandler:^(NSString *_Nullable result, NSError *_Nullable error) {
        if (error) {
            // 如果执行出错，则直接返回
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        void (^retryBlock)(void) = ^{
            // 如果页面中不存在目标元素，则延迟一段时间后再次判断
            self.retryCount++;
            NSInteger maxRetryCount = ceil(EZNetWorkTimeoutInterval / DELAY_SECONDS);
            if (self.retryCount < maxRetryCount && self.completionHandler) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_SECONDS * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self getTextContentOfElement:selector completion:completion];
                });
            } else {
                NSLog(@"finish, retry count: %ld", self.retryCount);
                if (completion) {
                    completion(nil, [EZTranslateError timeoutError]);
                }
            }
        };
        
        if ([result boolValue]) {
            NSString *elementTextContent = [NSString stringWithFormat:@"Array.from(document.querySelectorAll('%@')).map(el => el.textContent)", selector];
//            elementTextContent = @"document.body.innerHTML";
            
            if (self.jsBlock.length) {
                elementTextContent = self.jsBlock;
            }
            
            [self.webView evaluateJavaScript:elementTextContent completionHandler:^(NSArray<NSString *> *_Nullable texts, NSError *_Nullable error) {
                if (error) {
                    // 如果执行出错，则直接返回
                    if (completion) {
                        completion(nil, error);
                        return;
                    }
                }
                // !!!: Trim text, and wait translatedText length > 0
                NSArray *translatedTexts = [self getValidTranslatedTexts:texts];
                if (completion && translatedTexts) {
                    completion(translatedTexts, nil);
                } else {
                    retryBlock();
                }
            }];
        } else {
            retryBlock();
        }
    }];
}

- (nullable NSArray<NSString *> *)getValidTranslatedTexts:(NSArray<NSString *> *)texts {
    NSString *text = [texts componentsJoinedByString:@"\n"];
    NSString *translatedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (translatedText.length == 0) {
        return nil;
    }
    
    // Volcano translate sometimes returns ... first, this is invalid.
    if ([translatedText isEqualToString:@"..."]) {
        return nil;
    }
    
    texts = [translatedText componentsSeparatedByString:@"\n"];
    return texts;
}


#pragma mark - WKNavigationDelegate

// 页面加载完成后，获取翻译结果
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"didFinishNavigation: %@", webView.URL.absoluteString);
    
    if (self.completionHandler) {
        [self getTextContentOfElement:self.querySelector completion:self.completionHandler];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"didFailNavigation: %@", error);
}

/** 请求服务器发生错误 (如果是goBack时，当前页面也会回调这个方法，原因是NSURLErrorCancelled取消加载) */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"didFailProvisionalNavigation: %@", error);
}

// 监听 JavaScript 代码是否执行
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    // JavaScript 代码执行
    NSLog(@"runJavaScriptAlertPanelWithMessage: %@", message);
}


/** 在收到响应后，决定是否跳转 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSLog(@"decidePolicyForNavigationResponse: %@", navigationResponse.response.URL.absoluteString);
    
    // 这里可以查看页面内部的网络请求，并做出相应的处理
    // navigationResponse 包含了请求的相关信息，你可以通过它来获取请求的 URL、请求方法、请求头等信息
    // decisionHandler 是一个回调，你可以通过它来决定是否允许这个请求发送
    
    
    //允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
    //不允许跳转
    // decisionHandler(WKNavigationResponsePolicyCancel);
}

/** 接收到服务器跳转请求即服务重定向时之后调用 */
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"didReceiveServerRedirectForProvisionalNavigation: %@", webView.URL.absoluteURL);
}

/** 收到服务器响应后，在发送请求之前，决定是否跳转 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *navigationActionURL = navigationAction.request.URL.absoluteString;
    NSLog(@"decidePolicyForNavigationAction URL: %@", navigationActionURL);
    
    if ([navigationActionURL isEqualToString:@"about:blank"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    //允许跳转
    decisionHandler(WKNavigationActionPolicyAllow);
    //不允许跳转
    // decisionHandler(WKNavigationActionPolicyCancel);
}

@end
