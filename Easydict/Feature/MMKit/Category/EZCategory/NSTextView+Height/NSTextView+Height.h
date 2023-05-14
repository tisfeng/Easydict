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

- (CGFloat)ez_getHeight;

- (CGFloat)ez_getHeightWithWidth:(CGFloat)width;

- (CGFloat)ez_getTextViewHeightWithWidth:(CGFloat)width;


#pragma mark -

- (CGSize)ez_getTextViewSize;

@end

NS_ASSUME_NONNULL_END
