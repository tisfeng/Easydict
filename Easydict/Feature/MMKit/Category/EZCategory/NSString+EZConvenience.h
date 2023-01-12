//
//  NSString+EZConvenience.h
//  Easydict
//
//  Created by tisfeng on 2023/1/1.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EZConvenience)

- (NSString *)trim;

- (NSString *)encode;

- (void)copyToPasteboard;

@end

NS_ASSUME_NONNULL_END
