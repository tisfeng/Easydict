//
//  NSTextView+AutoHeight.m
//  Easydict
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import "NSTextView+Height.h"

@implementation NSTextView (Height)

- (CGSize)ez_getTextViewSize {
    CGSize size = [self getTextContainerSize];
    size.width += self.textContainerInset.width * 2;
    size.height += self.textContainerInset.height * 2;
    return size;
}

/// One line height
- (CGFloat)ez_getTextViewHeight {
    CGSize size = [self ez_getTextViewSize];
    return size.height;
}

- (CGFloat)ez_getTextViewHeightDesignatedWidth:(CGFloat)width {
    CGSize textContainerInset = self.textContainerInset;
    CGFloat renderWidth = width - textContainerInset.width * 2;
    CGFloat height = [self getTextContainerHeightDesignatedWidth:renderWidth];
    height += textContainerInset.height * 2;
    
    return height;
}


#pragma mark - Private

- (CGSize)getTextContainerSize {
    return [self getTextContainerSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
}

- (CGFloat)getTextContainerWidth {
    return [self getTextContainerSize].width;
}

- (CGFloat)getTextContainerHeightDesignatedWidth:(CGFloat)width {
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
