//
//  NSView+MM.h
//  Bob
//
//  Created by ripper on 2019/12/1.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 已考虑 flipped
@interface NSView (MM)

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@property (nonatomic, assign) CGFloat top;
@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat bottom;
@property (nonatomic, assign) CGFloat right;

@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;

@property (nonatomic, assign) NSPoint origin;
@property (nonatomic, assign) NSSize size;
@property (nonatomic, assign) NSPoint center;

@property (nonatomic, assign) NSPoint topLeft;
@property (nonatomic, assign) NSPoint leftBottom;
@property (nonatomic, assign) NSPoint bottomRight;
@property (nonatomic, assign) NSPoint topRight;

@end

NS_ASSUME_NONNULL_END
