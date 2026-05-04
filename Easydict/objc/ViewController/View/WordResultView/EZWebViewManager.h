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

/// Owns the WKWebView used by Apple Dictionary results.
/// It keeps iframe rendering state beside the query result so reused cells do
/// not reload HTML or repeatedly propagate unchanged content heights.
@interface EZWebViewManager : NSObject

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) CGFloat wordResultViewHeight;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL needUpdateIframeHeight;

@property (nonatomic, copy, nullable) void (^didFinishUpdatingIframeHeightBlock)(CGFloat height);

- (void)reset;

- (void)updateAllIframe;

@end

NS_ASSUME_NONNULL_END
