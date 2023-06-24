//
//  EZCoordinateUtils.h
//  Easydict
//
//  Created by tisfeng on 2022/11/23.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZCoordinateUtils : NSObject

/// Get safe point, bottom-left coordinate.
+ (CGPoint)getFrameSafePoint:(CGRect)frame moveToPoint:(CGPoint)point inScreen:(NSScreen *)screen;
+ (CGRect)getSafeFrame:(CGRect)frame moveToPoint:(CGPoint)point inScreen:(NSScreen *)screen;

/// Make sure frame show in screen visible frame, return left-bottom postion frame.
+ (CGRect)getSafeAreaFrame:(CGRect)frame inScreen:(nullable NSScreen *)screen;
+ (CGPoint)getSafeLocation:(CGRect)frame inScreen:(NSScreen *)screen;


/// Convert point from top-left to bottom-left coordinate system
+ (CGPoint)convertPointToBottomLeft:(CGPoint)point;

/// Convert rect from top-left to bottom-left coordinate
+ (CGRect)convertRectToBottomLeft:(CGRect)rect;

///// Convert point from bottom-left coordinate to top-left coordinate
//+ (CGPoint)convertPointToTopLeft:(CGPoint)point;
//
///// Convert rect from bottom-left coordinate to top-left coordinate
//+ (CGRect)convertRectToTopLeft:(CGRect)rect;

#pragma mark -

/// Get frame Top-Left point, default frame origin is Bottom-Left.
/// !!!: Coordinate system is still Bottom-Left, not changed.
+ (CGPoint)getFrameTopLeftPoint:(CGRect)frame;

+ (NSScreen *)screenForPoint:(CGPoint)point;

+ (NSScreen *)screenOfMousePosition;

@end

NS_ASSUME_NONNULL_END
