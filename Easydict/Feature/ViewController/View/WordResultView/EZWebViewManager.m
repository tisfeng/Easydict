//
//  EZWebViewManager.m
//  Easydict
//
//  Created by tisfeng on 2023/8/29.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZWebViewManager.h"
#import "EZConfiguration.h"

static NSString *kObjcHandler = @"objcHandler";
static NSString *kMethod = @"method";

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
            NSLog(@"<javascript log>: %@", message);
        }
        
        if ([body[kMethod] isEqualToString:@"noteToUpdateScrollHeight"]) {
            CGFloat scrollHeight = [body[@"scrollHeight"] floatValue];
            if (self.didFinishUpdatingIframeHeightBlock) {
                self.didFinishUpdatingIframeHeightBlock(scrollHeight);
            }
        }
    }
}

#pragma mark - WebView evaluateJavaScript

- (void)updateAllIframe {
    CGFloat fontSize = EZConfiguration.shared.fontSizeRatio; // 1.4 --> 140%
    NSString *script = [NSString stringWithFormat:@"changeIframeBodyFontSize(%.1f); updateAllIframeStyle();", fontSize];
    [self.webView evaluateJavaScript:script completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        if (!error) {
        }
    }];
}

- (void)reset {
    self.wordResultViewHeight = 0;
    self.isLoaded = NO;
    self.needUpdateIframeHeight = NO;
    self.didFinishUpdatingIframeHeightBlock = nil;
}

@end
