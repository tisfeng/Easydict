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
        
        // WKWebView 的配置，设置 messageHandlers
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        [configuration.userContentController addScriptMessageHandler:self name:@"logHandler"];
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    }
    return _webView;
}

// 处理来自 JavaScript 的消息
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"logHandler"]) {
        NSLog(@"<javascript log>: %@", message.body);
    }
}

- (void)reset {
    self.wordResultViewHeight = 0;
    self.isLoaded = NO;
    self.HTMLString = nil;
}

@end
