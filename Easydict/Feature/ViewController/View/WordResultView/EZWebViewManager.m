//
//  EZWebViewManager.m
//  Easydict
//
//  Created by tisfeng on 2023/8/29.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZWebViewManager.h"

@interface EZWebViewManager () <WKNavigationDelegate, WKScriptMessageHandler>

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
        [configuration.userContentController addScriptMessageHandler:self name:@"logHandler"];
        [configuration.userContentController addScriptMessageHandler:self name:@"updateWebViewHeight"];

        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    }
    return _webView;
}

#pragma mark - WKScriptMessageHandler
// 处理来自 JavaScript 的消息
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"logHandler"]) {
        NSLog(@"<javascript log>: %@", message.body);
    } else if ([message.name isEqualToString:@"updateWebViewHeight"]) {
        NSLog(@"<javascript updateWebViewHeight>: %@", message.body);

    }
}

- (void)reset {
    self.wordResultViewHeight = 0;
    self.isLoaded = NO;
    self.needUpdateIframeHeight = NO;
}

@end
