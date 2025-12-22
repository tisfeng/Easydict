//
//  EZBaiduWebTranslate.h
//  Easydict
//
//  Created by tisfeng on 2022/12/4.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EZQueryModel;

NS_ASSUME_NONNULL_BEGIN

@interface EZWebViewTranslator : NSObject

@property (nonatomic, copy) NSString *querySelector;
@property (nonatomic, copy) NSString *jsCode;

// if querySelector failed, delay to use delayQuerySelector.
@property (nonatomic, copy) NSString *delayQuerySelector;
@property (nonatomic, copy) NSString *delayJsCode;

@property (nonatomic, assign) NSInteger delayRetryCount; // 10

@property (nonatomic, strong) EZQueryModel *queryModel;

/// Preload url.
- (void)preloadURL:(NSString *)URL;

/// Monitor designated url request when load url.
- (void)monitorBaseURLString:(NSString *)monitorURL
                     loadURL:(NSString *)URL
           completionHandler:(nullable void (^)(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error))completionHandler;

/// Query webView rranslate url result.
- (void)queryTranslateURL:(NSString *)URL
        completionHandler:(nullable void (^)(NSArray<NSString *> *_Nullable translatedText, NSError *error))completionHandler;

- (void)resetWebView;

@end

NS_ASSUME_NONNULL_END
