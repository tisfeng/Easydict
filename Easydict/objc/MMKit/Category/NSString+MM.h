//
//  NSString+MM.h
//  Bob
//
//  Created by ripper on 2019/11/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSString (MM)

/// 将字符串数组用指定分隔符拼接
/// @param components 字符串数组
/// @param separatedString 分隔符，为 nil 时返回 nil
+ (NSString *)mm_stringByCombineComponents:(NSArray<NSString *> *)components separatedString:(nullable NSString *)separatedString;

// https://stackoverflow.com/questions/8088473/how-do-i-url-encode-a-string
- (NSString *)mm_urlencode;

@end

NS_ASSUME_NONNULL_END
