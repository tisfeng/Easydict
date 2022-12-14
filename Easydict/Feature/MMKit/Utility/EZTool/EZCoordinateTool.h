//
//  EZTool.h
//  Easydict
//
//  Created by tisfeng on 2022/11/23.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZCoordinateTool : NSObject


/// Get safe point, bottom-left coordinate
+ (CGPoint)getFrameSafePoint:(CGRect)frame moveToPoint:(CGPoint)point;
+ (CGRect)getSafeFrame:(CGRect)frame moveToPoint:(CGPoint)point;

/// Make sure frame is in screen visible frame, return left-bottom postion frame.
+ (CGRect)getSafeAreaFrame:(CGRect)frame;
+ (CGPoint)getSafeLocation:(CGRect)frame;


/// Convert point from top-left to bottom-left coordinate system
+ (CGPoint)convertPointToBottomLeft:(CGPoint)point;

// Convert rect from top-left to bottom-left coordinate
+ (CGRect)convertRectToBottomLeft:(CGRect)rect;

// Convert point from bottom-left coordinate to top-left coordinate
+ (CGPoint)convertPointToTopLeft:(CGPoint)point;

// Convert rect from bottom-left coordinate to top-left coordinate
+ (CGRect)convertRectToTopLeft:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
