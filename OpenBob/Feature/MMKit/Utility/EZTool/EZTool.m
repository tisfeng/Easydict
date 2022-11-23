//
//  EZTool.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/23.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTool.h"

@implementation EZTool

// Convert point from left-top to left-bottom coordinate system
+ (CGPoint)convertPointToBottom:(CGPoint)point {
    return CGPointMake(point.x, [NSScreen mainScreen].frame.size.height - point.y);
}

// Convert rect from left-top coordinate to left-bottom coordinate
+ (CGRect)convertRectToBottom:(CGRect)rect {
    CGRect screenRect = NSScreen.mainScreen.frame;
    CGFloat height = screenRect.size.height;
    rect.origin.y = height - rect.origin.y - rect.size.height;
    return rect;
}


// Convert point from left-bottom coordinate to left-top coordinate
+ (CGPoint)convertPointToTop:(CGPoint)point {
    return CGPointMake(point.x, [NSScreen mainScreen].frame.size.height - point.y);
}

// Convert rect from left-bottom coordinate to left-top coordinate
+ (CGRect)convertRectToTop:(CGRect)rect {
    CGRect screenRect = NSScreen.mainScreen.frame;
    CGFloat height = screenRect.size.height;
    rect.origin.y = height - rect.origin.y - rect.size.height;
    return rect;
}

@end
