//
//  EZNetworkManager.h
//  Easydict
//
//  Created by tisfeng on 2023/4/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZNetworkManager : NSObject

/// Request cookie of URL.
- (void)requestCookieOfURL:(NSString *)URL cookieName:(NSString *)cookieName completion:(void (^)(NSString *cookie))completion;

@end

NS_ASSUME_NONNULL_END
