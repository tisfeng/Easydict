//
//  EZWebViewManager.m
//  Easydict
//
//  Created by tisfeng on 2023/8/29.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZWebViewManager.h"

@interface EZWebViewManager () <WKNavigationDelegate>

@end

@implementation EZWebViewManager

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] init];
    }
    return _webView;
}

@end
