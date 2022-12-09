//
//  EZBaiduWebTranslate.h
//  Easydict
//
//  Created by tisfeng on 2022/12/4.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZWebViewTranslator : NSObject

@property (nonatomic, copy) NSString *querySelector;

/// Preload url.
- (void)preloadURL:(NSString *)URL;

/// Monitor designated url request when load url.
- (void)monitorURL:(NSString *)monitorURL
           loadURL:(NSString *)URL
 completionHandler:(nullable void (^)(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error))completionHandler;

/// Query webView rranslate url result.
- (void)queryTranslateURL:(NSString *)URL
                  success:(nullable void (^)(NSString *translatedText))success
                  failure:(nullable void (^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
