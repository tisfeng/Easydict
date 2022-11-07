//
//  NSTextView+AutoHeight.m
//  Bob
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "NSTextView+Height.h"
#import "NSMutableAttributedString+MM.h"

@implementation NSTextView (Height)

- (CGFloat)getHeight {
    NSAssert(self.width != 0, @"self.width cannot be 0");
    
    CGSize textContainerInset = self.textContainerInset;
    CGFloat width = self.width - textContainerInset.width * 2;
     CGFloat height = [self.attributedString mm_getTextHeightWithWidth:width];
    height += textContainerInset.height * 2;
    
    return height;
}

@end
