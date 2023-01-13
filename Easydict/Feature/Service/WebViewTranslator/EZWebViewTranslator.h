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

@property (nonatomic, copy) NSString *jsCode;


/// Preload url.
- (void)preloadURL:(NSString *)URL;

/// Monitor designated url request when load url.
- (void)monitorBaseURLString:(NSString *)monitorURL
                     loadURL:(NSString *)URL
           completionHandler:(nullable void (^)(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error))completionHandler;

/// Query webView rranslate url result.
- (void)queryTranslateURL:(NSString *)URL
        completionHandler:(nullable void (^)(NSArray<NSString *> *_Nullable translatedText, NSError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END
