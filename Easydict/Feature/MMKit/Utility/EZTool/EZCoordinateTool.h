//
//  EZTool.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/23.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZCoordinateTool : NSObject

// window frame is frame, move window to point, adjust window frame to make sure window is in screen visible frame.
+ (CGRect)getSafeFrame:(CGRect)frame moveToPoint:(CGPoint)point;
+ (CGPoint)getFrameSafePoint:(CGRect)frame moveToPoint:(CGPoint)point;

// Make sure frame is in screen visible frame, return left-bottom postion frame.
+ (CGRect)getSafeAreaFrame:(CGRect)frame;
+ (CGPoint)getSafeLocation:(CGRect)frame;


// Convert point from left-top to left-bottom coordinate system
+ (CGPoint)convertPointToBottomLeft:(CGPoint)point;

// Convert rect from left-top coordinate to left-bottom coordinate
+ (CGRect)convertRectToBottomLeft:(CGRect)rect;

// Convert point from left-bottom coordinate to left-top coordinate
+ (CGPoint)convertPointToTopLeft:(CGPoint)point;

// Convert rect from left-bottom coordinate to left-top coordinate
+ (CGRect)convertRectToTopLeft:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
