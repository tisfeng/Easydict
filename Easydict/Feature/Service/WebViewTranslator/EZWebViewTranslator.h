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

- (void)preloadURL:(NSString *)url;

- (void)loadURL:(NSString *)URL
        success:(nullable void (^)(NSString *translatedText))success
        failure:(nullable void (^)(NSError *error))failure;

- (void)monitorURL:(NSString *)url completionHandler:(nullable void (^)(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
