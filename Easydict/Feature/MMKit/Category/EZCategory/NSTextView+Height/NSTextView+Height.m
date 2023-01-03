//
//  NSTextView+AutoHeight.m
//  Easydict
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import "NSTextView+Height.h"

@implementation NSTextView (Height)

- (CGFloat)getHeight {
    NSAssert(self.width != 0, @"self.width cannot be 0");
    
    CGSize textContainerInset = self.textContainerInset;
    CGFloat width = self.width - textContainerInset.width * 2;
    CGFloat height = [self.attributedString mm_getTextHeightWithWidth:width];
    height += textContainerInset.height * 2;
    
    return ceil(height);
}

- (CGFloat)getHeightWithWidth:(CGFloat)width {
    CGSize textContainerInset = self.textContainerInset;
    CGFloat renderWidth = width - textContainerInset.width * 2;
    CGFloat height = [self.attributedString mm_getTextHeightWithWidth:renderWidth];
    height += textContainerInset.height * 2;
    
    return ceil(height);
}

- (CGFloat)getTextViewHeightWithWidth:(CGFloat)width {    
    NSDictionary *attr;
    if (self.string.length) {
        attr = [self.attributedString attributesAtIndex:0 effectiveRange:nil];
    }
    CGSize textContainerInset = self.textContainerInset;
    CGFloat renderWidth = width - textContainerInset.width * 2;
    CGFloat height = [self.string mm_sizetWithAttributes:attr constrainedToSize:CGSizeMake(renderWidth, CGFLOAT_MAX)].height;
    height += textContainerInset.height * 2;
    
    return ceil(height);
}

@end
