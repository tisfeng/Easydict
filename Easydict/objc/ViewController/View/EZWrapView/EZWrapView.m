//
//  EZWrapView.m
//  Easydict
//
//  Created by choykarl on 2023/11/28.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZWrapView.h"

@implementation EZWrapView

- (void)layout {
    [super layout];
    
    NSView *lastView;
    CGFloat spacing = self.spacing;
    CGFloat runSpacing = self.runSpacing;
    
    for (NSView *view in self.subviews) {
        if (lastView) {
            if (CGRectGetMaxX(lastView.frame) + view.frame.size.width + spacing > self.frame.size.width) {
                view.frame = CGRectMake(0, CGRectGetMaxY(lastView.frame) + runSpacing, view.frame.size.width, view.frame.size.height);
            } else {
                view.frame = CGRectMake(CGRectGetMaxX(lastView.frame) + spacing, lastView.frame.origin.y, view.frame.size.width, view.frame.size.height);
            }
        } else {
            view.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
        }
        lastView = view;
    }
    
    [self invalidateIntrinsicContentSize];
}

- (NSSize)intrinsicContentSize {
    NSSize size = NSMakeSize(CGRectGetMaxX(self.subviews.lastObject.frame), CGRectGetMaxY(self.subviews.lastObject.frame));
    return size;
}

- (BOOL)isFlipped {
    return YES;
}

@end
