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

- (CGFloat)getHeight;

- (CGFloat)getHeightWithWidth:(CGFloat)width;

- (CGFloat)getTextViewHeightWithWidth:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
