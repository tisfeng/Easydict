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

- (void)queryURL:(NSString *)URL
         success:(void (^)(NSString *translatedText))success
         failure:(void (^)(NSError *error))failure;
@end

NS_ASSUME_NONNULL_END
