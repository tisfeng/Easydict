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
+ (CGPoint)convertPointToBottom:(CGPoint)point;

// Convert rect from left-top coordinate to left-bottom coordinate
+ (CGRect)convertRectToBottom:(CGRect)rect;

// Convert point from left-bottom coordinate to left-top coordinate
+ (CGPoint)convertPointToTop:(CGPoint)point;

// Convert rect from left-bottom coordinate to left-top coordinate
+ (CGRect)convertRectToTop:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
