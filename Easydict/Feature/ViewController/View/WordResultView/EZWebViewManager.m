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
        [configuration.userContentController addScriptMessageHandler:self name:@"objcHandler"];

        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    }
    return _webView;
}

#pragma mark - WKScriptMessageHandler
// 处理来自 JavaScript 的消息
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    id body = message.body;
    
    if ([message.name isEqualToString:@"logHandler"]) {
        NSLog(@"<javascript log>: %@", body);
    }
    
    if([message.name isEqualToString:@"objcHandler"]) {
        if([body[@"method"] isEqualToString:@"getScrollHeight"]) {
            CGFloat scrollHeight = [body[@"scrollHeight"] floatValue];
            if (self.didFinishUpdatingIframeHeightBlock) {
                self.didFinishUpdatingIframeHeightBlock(scrollHeight);
            }
        }
      }
}

- (void)reset {
    self.wordResultViewHeight = 0;
    self.isLoaded = NO;
    self.needUpdateIframeHeight = NO;
    self.didFinishUpdatingIframeHeightBlock = nil;
}

@end
