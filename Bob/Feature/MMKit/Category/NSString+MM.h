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

- (NSString *)mm_urlencode;

+ (NSString *)mm_stringByCombineComponents:(NSArray<NSString *> *)components separatedString:(nullable NSString *)separatedString;

@end

NS_ASSUME_NONNULL_END
