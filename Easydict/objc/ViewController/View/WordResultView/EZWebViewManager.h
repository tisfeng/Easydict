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

@class EZQueryResult;

FOUNDATION_EXPORT BOOL EZResultNeedsDictionaryHTMLHeight(EZQueryResult *result);
FOUNDATION_EXPORT BOOL EZResultShouldRenderDictionaryHTML(EZQueryResult *result);

/// Owns the WKWebView used by dictionary HTML results.
/// It keeps iframe rendering state beside the query result so reused cells do
/// not repeatedly propagate unchanged content heights.
@interface EZWebViewManager : NSObject

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) CGFloat wordResultViewHeight;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL needUpdateIframeHeight;
@property (nonatomic, copy, nullable) NSString *loadedHTMLString;

@property (nonatomic, copy, nullable) void (^didFinishUpdatingIframeHeightBlock)(CGFloat height);

- (void)reset;
- (void)discardReusableWebView;

- (NSUInteger)beginRenderingHTML;
- (void)trackRenderingNavigation:(nullable WKNavigation *)navigation renderGeneration:(NSUInteger)renderGeneration;
- (BOOL)shouldHandleNavigation:(nullable WKNavigation *)navigation;

- (void)updateAllIframe;

@end

NS_ASSUME_NONNULL_END
