//
//  EZWebViewManager.m
//  Easydict
//
//  Created by tisfeng on 2023/8/29.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZWebViewManager.h"
#import "EZConst.h"
#import <math.h>

static NSString *kObjcHandler = @"objcHandler";
static NSString *kMethod = @"method";

@interface EZWeakScriptMessageHandler : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak) id<WKScriptMessageHandler> target;

- (instancetype)initWithTarget:(id<WKScriptMessageHandler>)target;

@end

@implementation EZWeakScriptMessageHandler

- (instancetype)initWithTarget:(id<WKScriptMessageHandler>)target {
    if (self = [super init]) {
        _target = target;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.target userContentController:userContentController didReceiveScriptMessage:message];
}

@end

@interface EZWebViewManager () <WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, assign) BOOL isUpdatingIframe;
@property (nonatomic, assign) BOOL forceNextScrollHeightCallback;
@property (nonatomic, assign) CGFloat lastScrollHeight;

- (void)teardownWebView;
- (void)resetReusableWebView;

@end

@implementation EZWebViewManager

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        EZWeakScriptMessageHandler *handler = [[EZWeakScriptMessageHandler alloc] initWithTarget:self];
        [configuration.userContentController addScriptMessageHandler:handler name:kObjcHandler];
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    }
    return _webView;
}

#pragma mark - WKScriptMessageHandler

// 处理来自 JavaScript 的消息
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    id body = message.body;
    
    if ([message.name isEqualToString:kObjcHandler]) {
        if ([body[kMethod] isEqualToString:@"consoleLog"]) {
            NSString *message = body[@"message"];
            MMLogInfo(@"<javascript log>: %@", message);
        }
        
        if ([body[kMethod] isEqualToString:@"noteToUpdateScrollHeight"]) {
            CGFloat scrollHeight = [body[@"scrollHeight"] floatValue];
            BOOL heightChanged = self.lastScrollHeight <= 0 ||
                                 fabs(scrollHeight - self.lastScrollHeight) >=
                                 EZLayoutGeometryTolerance_0_5;
            BOOL shouldNotifyHeight = heightChanged || self.forceNextScrollHeightCallback;
            if (shouldNotifyHeight) {
                self.lastScrollHeight = scrollHeight;
                self.forceNextScrollHeightCallback = NO;
                if (self.didFinishUpdatingIframeHeightBlock) {
                    self.didFinishUpdatingIframeHeightBlock(scrollHeight);
                }
            }
            self.isUpdatingIframe = NO;
        }
    }
}

#pragma mark - WebView evaluateJavaScript

- (void)updateAllIframe {
    if (self.isUpdatingIframe) {
        if (self.needUpdateIframeHeight) {
            self.forceNextScrollHeightCallback = YES;
        }
        return;
    }

    self.forceNextScrollHeightCallback = self.forceNextScrollHeightCallback ||
                                          self.needUpdateIframeHeight;
    self.needUpdateIframeHeight = NO;
    self.isUpdatingIframe = YES;

    CGFloat fontSize = MyConfiguration.shared.fontSizeRatio; // 1.4 --> 140%
    NSString *script = [NSString stringWithFormat:
                        @"changeIframeBodyFontSize(%.1f); updateAllIframeStyle();",
                        fontSize];
    [self.webView evaluateJavaScript:script
                   completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        if (error) {
            MMLogError(@"updateAllIframe failed: %@", error);
        }
        self.isUpdatingIframe = NO;
        if (self.needUpdateIframeHeight) {
            [self updateAllIframe];
        }
    }];
}

- (void)reset {
    self.wordResultViewHeight = 0;
    self.isLoaded = NO;
    self.needUpdateIframeHeight = NO;
    self.loadedHTMLString = nil;
    self.didFinishUpdatingIframeHeightBlock = nil;
    self.isUpdatingIframe = NO;
    self.forceNextScrollHeightCallback = NO;
    self.lastScrollHeight = 0;
    [self resetReusableWebView];
}

- (void)dealloc {
    [self teardownWebView];
}

#pragma mark - MJExtension

+ (NSArray *)mj_ignoredPropertyNames {
    return @[
        @"webView",
        @"loadedHTMLString",
        @"isUpdatingIframe",
        @"forceNextScrollHeightCallback",
        @"lastScrollHeight"
    ];
}

- (void)teardownWebView {
    WKWebView *webView = _webView;
    if (!webView) {
        return;
    }

    [webView stopLoading];
    webView.navigationDelegate = nil;
    webView.UIDelegate = nil;
    [webView.configuration.userContentController removeScriptMessageHandlerForName:kObjcHandler];
    _webView = nil;
}

- (void)resetReusableWebView {
    WKWebView *webView = _webView;
    if (!webView) {
        return;
    }

    [webView stopLoading];
    webView.navigationDelegate = nil;
    webView.UIDelegate = nil;
    [webView loadHTMLString:@"" baseURL:nil];
}

@end
