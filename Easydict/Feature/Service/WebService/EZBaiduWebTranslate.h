//
//  EZBaiduWebTranslate.h
//  Easydict
//
//  Created by tisfeng on 2022/12/4.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZBaiduWebTranslate : NSObject

- (void)translate:(NSString *)text
          success:(void (^)(NSString *result))success
          failure:(void (^)(NSError *error))failure;
@end

NS_ASSUME_NONNULL_END
