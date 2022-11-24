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

// get string width
- (CGFloat)mm_widthWithFont:(NSFont *)font;
- (CGFloat)mm_widthWithFont:(NSFont *)font constrainedToHeight:(CGFloat)height;

// get string height
- (CGFloat)mm_heightWithFont:(NSFont *)font;
- (CGFloat)mm_heightWithFont:(NSFont *)font constrainedToWidth:(CGFloat)width;

// get string size
- (CGSize)mm_sizeWithFont:(NSFont *)font;
- (CGSize)mm_sizeWithFont:(NSFont *)font constrainedToSize:(CGSize)size;
- (CGSize)mm_sizetWithAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
               constrainedToSize:(CGSize)size;

- (NSString *)mm_urlencode;

+ (NSString *)mm_stringByCombineComponents:(NSArray<NSString *> *)components separatedString:(nullable NSString *)separatedString;

@end

NS_ASSUME_NONNULL_END
