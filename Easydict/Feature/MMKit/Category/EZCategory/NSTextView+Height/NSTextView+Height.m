//
//  NSTextView+AutoHeight.m
//  Easydict
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import "NSTextView+Height.h"

@implementation NSTextView (Height)

- (CGFloat)ez_getHeight {
    NSAssert(self.width != 0, @"self.width cannot be 0");
    
    CGSize textContainerInset = self.textContainerInset;
    CGFloat width = self.width - textContainerInset.width * 2;
    CGFloat height = [self.attributedString mm_getTextHeightWithWidth:width];
    height += textContainerInset.height * 2;
    
    return ceil(height);
}

- (CGFloat)ez_getHeightWithWidth:(CGFloat)width {
    CGSize textContainerInset = self.textContainerInset;
    CGFloat renderWidth = width - textContainerInset.width * 2;
    CGFloat height = [self.attributedString mm_getTextHeightWithWidth:renderWidth];
    height += textContainerInset.height * 2;
    
    return ceil(height);
}

- (CGFloat)ez_getTextViewHeightWithWidth:(CGFloat)width {    
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


#pragma mark -

- (CGSize)ez_getTextViewSize {
    CGSize size = [self getTextContainerSize];
    size.width += self.textContainerInset.width * 2;
    size.height += self.textContainerInset.height * 2;
    return size;
}

- (CGSize)getTextContainerSize {
    return [self getTextContainerSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
}

- (CGFloat)getTextContainerWidth {
    return [self getTextContainerSize].width;
}

- (CGFloat)getTextContainerHeightWithWidth:(CGFloat)width {
    return [self getTextContainerSize:CGSizeMake(width, CGFLOAT_MAX)].height;
}

- (CGSize)getTextContainerSize:(CGSize)designatedSize {
    if (!designatedSize.width || !designatedSize.height) {
        return CGSizeZero;
    }

    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:designatedSize];
    textContainer.lineFragmentPadding = self.textContainer.lineFragmentPadding;
    
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self.attributedString];
    [textStorage addLayoutManager:layoutManager];
    
    [layoutManager glyphRangeForTextContainer:textContainer];
    CGSize size = [layoutManager usedRectForTextContainer:textContainer].size;
    
    CGSize ceilSize = CGSizeMake(ceil(size.width), ceil(size.height));
    
    return ceilSize;
}

@end
