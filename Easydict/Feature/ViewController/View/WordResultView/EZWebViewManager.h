//
//  EZWebViewManager.h
//  Easydict
//
//  Created by tisfeng on 2023/8/29.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZWebViewManager : NSObject

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) CGFloat wordResultViewHeight;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL needUpdateIframeHeight;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
