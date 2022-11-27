//
//  EZTool.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/23.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZCoordinateTool.h"

@implementation EZCoordinateTool

+ (CGPoint)getFrameSafePoint:(CGRect)frame moveToPoint:(CGPoint)point {
    CGRect newFrame = CGRectMake(point.x, point.y, frame.size.width, frame.size.height);
    return [self getSafeLocation:newFrame];
}

+ (CGRect)getSafeFrame:(CGRect)frame moveToPoint:(CGPoint)point {
    CGRect newFrame = CGRectMake(point.x, point.y, frame.size.width, frame.size.height);
    return [self getSafeAreaFrame:newFrame];
}


/// left-bottom safe postion.
+ (CGPoint)getSafeLocation:(CGRect)frame {
    CGRect safeFrame = [self getSafeAreaFrame:frame];
    return safeFrame.origin;
}

// Make sure frame show in screen visible frame, return left-bottom postion frame.
+ (CGRect)getSafeAreaFrame:(CGRect)frame {
    NSScreen *screen = [NSScreen mainScreen];
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


#pragma mark - Convert Coordinate

// Convert point from top-left to left-bottom coordinate system
+ (CGPoint)convertPointToBottomLeft:(CGPoint)point {
    return CGPointMake(point.x, [NSScreen mainScreen].frame.size.height - point.y);
}

// Convert rect from top-left coordinate to left-bottom coordinate
+ (CGRect)convertRectToBottomLeft:(CGRect)rect {
    CGRect screenRect = NSScreen.mainScreen.frame;
    CGFloat height = screenRect.size.height;
    rect.origin.y = height - rect.origin.y - rect.size.height;
    return rect;
}


// Convert point from bottom-left coordinate to left-top coordinate
+ (CGPoint)convertPointToTopLeft:(CGPoint)point {
    return CGPointMake(point.x, [NSScreen mainScreen].frame.size.height - point.y);
}

// Convert rect from bottom-left coordinate to left-top coordinate
+ (CGRect)convertRectToTopLeft:(CGRect)rect {
    CGRect screenRect = NSScreen.mainScreen.frame;
    CGFloat height = screenRect.size.height;
    rect.origin.y = height - rect.origin.y - rect.size.height;
    return rect;
}

@end
