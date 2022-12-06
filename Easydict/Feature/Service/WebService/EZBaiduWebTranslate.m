//
//  EZBaiduWebTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/4.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZBaiduWebTranslate.h"
#import <WebKit/WebKit.h>

// Max query seconds
static NSTimeInterval const MAX_QUERY_SECONDS = 2;

// Delay query seconds
static NSTimeInterval const DELAY_SECONDS = 0.1; // Usually takes more than 0.1 seconds.


@interface EZBaiduWebTranslate () <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, weak) NSViewController *viewController;

@property (nonatomic, copy) void (^completion)(NSString *, NSError *);

@property (nonatomic, assign) NSUInteger retryCount;

@end

@implementation EZBaiduWebTranslate

- (instancetype)initWithViewController:(NSViewController *)viewController {
    if (self = [super init]) {
        self.viewController = viewController;
        [viewController.view addSubview:self.webView];
    }
    return self;
}

- (AFHTTPSessionManager *)htmlSession {
    if (!_htmlSession) {
        AFHTTPSessionManager *htmlSession = [AFHTTPSessionManager manager];
        
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        [requestSerializer setValue:@"BAIDUID=0F8E1A72A51EE47B7CA0A81711749C00:FG=1;" forHTTPHeaderField:@"Cookie"];
        htmlSession.requestSerializer = requestSerializer;
        
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
        htmlSession.responseSerializer = responseSerializer;
        
        _htmlSession = htmlSession;
    }
    return _htmlSession;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *webViewConfiguration = [[WKWebViewConfiguration alloc] init];
        WKPreferences *preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = NO;
        webViewConfiguration.preferences = preferences;
        
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(1, 1, 1, 1) configuration:webViewConfiguration];
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
            [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": EZUserAgent}];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }];
    }
    return _webView;
}

/**
 使用 WKWebView 加载百度翻译网页，然后获取翻译结果
 
 百度翻译结果的样式为：
 <p class="ordinary-output target-output clearfix"> <span leftpos="0|4" rightpos="0|4" space="">好的</span> </p>
 */
- (void)translate:(NSString *)text
          success:(void (^)(NSString *result))success
          failure:(void (^)(NSError *error))failure {
    NSString *urlString = [NSString stringWithFormat:@"https://fanyi.baidu.com/#en/zh/%@", text];
    NSLog(@"translate url: %@", urlString);
    
    self.retryCount = 0;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    
    mm_weakify(self);
    self.completion = ^(NSString *result, NSError *error) {
        mm_strongify(self);
        
        if (result) {
            success(result);
        } else {
            failure(error);
        }
        
        // !!!: When finished, set completion to nil, and reset webView.
        self.completion = nil;
        [self.webView loadHTMLString:@"" baseURL:nil];
    };
}


// 页面加载完成后，获取翻译结果
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"didFinishNavigation: %@", webView.URL.absoluteString);
    
    if (self.completion) {
        NSString *selector = @"p.ordinary-output.target-output.clearfix";
        [self getInnerTextOfElement:selector completion:self.completion];
    }
}

- (void)getInnerTextOfElement:(NSString *)selector
                   completion:(void (^)(NSString *_Nullable, NSError *))completion {
    NSLog(@"get result count: %ld", self.retryCount + 1);
    
    // 定义一个异步方法，用于判断页面中是否存在目标元素
    // 先判断页面中是否存在目标元素
    NSString *js = [NSString stringWithFormat:@"document.querySelector('%@') != null", selector];
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        if (error) {
            // 如果执行出错，则直接返回
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        if ([result boolValue]) {
            // 如果页面中存在目标元素，则执行下面的代码获取它的 innerText 属性
            NSString *js = [NSString stringWithFormat:@"document.querySelector('%@').innerText", selector];
            [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError *_Nullable error) {
                if (error) {
                    // 如果执行出错，则直接返回
                    if (completion) {
                        completion(nil, error);
                    }
                }
                
                if (completion) {
                    completion(result, nil);
                }
            }];
        } else {
            // 如果页面中不存在目标元素，则延迟一段时间后再次判断
            self.retryCount++;
            NSInteger maxRetryCount = ceil(MAX_QUERY_SECONDS / DELAY_SECONDS);
            if (self.retryCount < maxRetryCount  && self.completion) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_SECONDS * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self getInnerTextOfElement:selector completion:completion];
                });
            } else {
                NSLog(@"finish, retry count: %ld", self.retryCount);
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"com.eztranslation" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"retry count is too large"}];
                    completion(nil, error);
                }
            }
        }
    }];
}


#pragma mark - WKNavigationDelegate

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
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
//    NSLog(@"decidePolicyForNavigationResponse: %@", navigationResponse.response.URL.absoluteString);
//
//    //允许跳转
//    decisionHandler(WKNavigationResponsePolicyAllow);
//    //不允许跳转
//    // decisionHandler(WKNavigationResponsePolicyCancel);
//}
/** 接收到服务器跳转请求即服务重定向时之后调用 */
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"didReceiveServerRedirectForProvisionalNavigation: %@", webView.URL.absoluteURL);
}
/** 收到服务器响应后，在发送请求之前，决定是否跳转 */
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
//    NSString *navigationActionURL = navigationAction.request.URL.absoluteString;
//    NSLog(@"decidePolicyForNavigationAction URL: %@", navigationActionURL);
//
////    if ([navigationActionURL isEqualToString:@"about:blank"]) {
////        decisionHandler(WKNavigationActionPolicyCancel);
////        return;
////    }
//
//    //允许跳转
//    decisionHandler(WKNavigationActionPolicyAllow);
//    //不允许跳转
//    // decisionHandler(WKNavigationActionPolicyCancel);
//}

@end
