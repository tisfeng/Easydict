//
//  EZTool.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/23.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZCoordinateTool.h"

@implementation EZCoordinateTool

/// left-bottom safe postion.
+ (CGPoint)getSafeLocation:(CGRect)frame {
    CGRect safeFrame = [self getSafeAreaFrame:frame];
    return safeFrame.origin;
}

// Make sure frame show in screen visible frame, return left-bottom postion frame.
+ (CGRect)getSafeAreaFrame:(CGRect)frame {
    NSScreen *screen = [NSScreen mainScreen];
    if (!screen) {
        return frame;
    }
    
    CGRect visibleFrame = screen.visibleFrame;
    if (CGRectContainsRect(visibleFrame, frame)) {
        return frame;
    }
    
    CGFloat x = frame.origin.x;
    CGFloat y = frame.origin.y;
    CGFloat width = frame.size.width;
    CGFloat height = frame.size.height;
    
    // left safe
    if (x < visibleFrame.origin.x) {
        x = visibleFrame.origin.x;
    }
    // right safe
    if (x + width > visibleFrame.origin.x + visibleFrame.size.width) {
        x = visibleFrame.origin.x + visibleFrame.size.width - width;
    }
    
    
    // top safe
    if (y > visibleFrame.origin.y + visibleFrame.size.height) {
        y = visibleFrame.origin.y + visibleFrame.size.height;
    }
    // bottom safe
    if (y < visibleFrame.origin.y) {
        y = visibleFrame.origin.y;
    }
    
    return CGRectMake(x, y, width, height);
}

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
