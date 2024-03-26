//
//  EZCommonResultView.h
//  Easydict
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZQueryResult.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZWordResultView : NSView <WKNavigationDelegate>

@property (nonatomic, assign, readonly) CGFloat viewHeight;
@property (nonatomic, strong, readonly) EZQueryResult *result;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong, readonly) NSButton *replaceTextButton;


@property (nonatomic, copy) void (^queryTextBlock)(NSString *word);

@property (nonatomic, copy) void (^updateViewHeightBlock)(CGFloat viewHeight);

@property (nonatomic, copy) void (^didFinishLoadingHTMLBlock)(void);

- (void)refreshWithResult:(EZQueryResult *)result;

@end

NS_ASSUME_NONNULL_END
