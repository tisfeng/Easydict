//
//  EZWebViewManager.m
//  Easydict
//
//  Created by tisfeng on 2023/8/29.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZWebViewManager.h"
#import <math.h>

static NSString *kObjcHandler = @"objcHandler";
static NSString *kMethod = @"method";
static const CGFloat kHeightChangeTolerance = 0.5;

@interface EZWebViewManager () <WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, assign) BOOL isUpdatingIframe;
@property (nonatomic, assign) BOOL forceNextScrollHeightCallback;
@property (nonatomic, assign) CGFloat lastScrollHeight;

- (void)teardownWebView;

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
        [configuration.userContentController addScriptMessageHandler:self name:kObjcHandler];
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
                                 fabs(scrollHeight - self.lastScrollHeight) >= kHeightChangeTolerance;
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
    self.didFinishUpdatingIframeHeightBlock = nil;
    self.isUpdatingIframe = NO;
    self.forceNextScrollHeightCallback = NO;
    self.lastScrollHeight = 0;
    [self teardownWebView];
}

- (void)dealloc {
    [self teardownWebView];
}

#pragma mark - MJExtension

+ (NSArray *)mj_ignoredPropertyNames {
    return @[
        @"webView",
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

@end
