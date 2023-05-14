//
//  NSTextView+AutoHeight.h
//  Easydict
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTextView (Height)

- (CGSize)ez_getTextViewSize;

/// One line height
- (CGFloat)ez_getTextViewHeight;

- (CGFloat)ez_getTextViewHeightDesignatedWidth:(CGFloat)width;



@end

NS_ASSUME_NONNULL_END
