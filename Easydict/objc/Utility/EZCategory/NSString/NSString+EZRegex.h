//
//  NSString+EZRegex.h
//  Easydict
//
//  Created by tisfeng on 2023/9/5.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EZRegex)

/// Get string value from HTML string with pattern.
- (nullable NSString *)getStringValueWithPattern:(NSString *)pattern;

@end

NS_ASSUME_NONNULL_END
