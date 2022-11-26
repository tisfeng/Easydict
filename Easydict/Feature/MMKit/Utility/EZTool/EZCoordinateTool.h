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

+ (CGPoint)getSafeLocation:(CGRect)frame;

// Make sure frame is in screen visible frame, return left-bottom postion frame.
+ (CGRect)getSafeAreaFrame:(CGRect)frame;


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
