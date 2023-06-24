//
//  EZCoordinateUtils.m
//  Easydict
//
//  Created by tisfeng on 2022/11/23.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZCoordinateUtils.h"

@implementation EZCoordinateUtils

+ (CGPoint)getFrameSafePoint:(CGRect)frame moveToPoint:(CGPoint)point inScreen:(NSScreen *)screen {
    CGRect newFrame = CGRectMake(point.x, point.y, frame.size.width, frame.size.height);
    return [self getSafeLocation:newFrame inScreen:screen];
}

+ (CGRect)getSafeFrame:(CGRect)frame moveToPoint:(CGPoint)point inScreen:(NSScreen *)screen {
    CGRect newFrame = CGRectMake(point.x, point.y, frame.size.width, frame.size.height);
    return [self getSafeAreaFrame:newFrame inScreen:screen];
}


/// left-bottom safe postion.
+ (CGPoint)getSafeLocation:(CGRect)frame inScreen:(NSScreen *)screen {
    CGRect safeFrame = [self getSafeAreaFrame:frame inScreen:screen];
    return safeFrame.origin;
}

/// Make sure frame show in screen visible frame, return left-bottom postion frame.
+ (CGRect)getSafeAreaFrame:(CGRect)frame inScreen:(nullable NSScreen *)screen {
    if (!screen) {
        screen = [self screenOfMousePosition];
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
    // keep bottom safe, if frame bottom beyond visibleFrame bottom and frame height <= visibleFrame height , try to move it up.
    if (y < visibleFrame.origin.y && height <= visibleFrame.size.height) {
        y = visibleFrame.origin.y;
    }
    
    // !!!: If mouse position is not in screen that the "frame" located, we need to move frame to mouse position screen.
    CGPoint mousePosition = [NSEvent mouseLocation];
    NSScreen *mouseInScreen = [self screenForPoint:mousePosition];
    NSScreen *frameInScreen = [self screenForRect:frame];
    if (mouseInScreen != frameInScreen) {
        x = mousePosition.x + 10;
        y = mousePosition.y - height;
    }
    
    return CGRectMake(x, y, width, height);
}

+ (NSScreen *)screenForPoint:(CGPoint)point {
    NSScreen *mouseInScreen = NSScreen.mainScreen;
    for (NSScreen *screen in [NSScreen screens]) {
        NSRect screenFrame = [screen frame];
        if (NSPointInRect(point, screenFrame)) {
            mouseInScreen = screen;
            break;
        }
    }
    return mouseInScreen;
}

+ (NSScreen *)screenForRect:(CGRect)rect {
    NSScreen *mouseInScreen = NSScreen.mainScreen;
    for (NSScreen *screen in [NSScreen screens]) {
        NSRect screenFrame = [screen frame];
        if (CGRectIntersectsRect(rect, screenFrame)) {
            mouseInScreen = screen;
            break;
        }
    }
    return mouseInScreen;
}


+ (NSScreen *)screenOfMousePosition {
    CGPoint mousePosition = [NSEvent mouseLocation];
    return [self screenForPoint:mousePosition];
}


#pragma mark - Convert Coordinate

/// Convert rect from top-left coordinate to left-bottom coordinate
+ (CGRect)convertRectToBottomLeft:(CGRect)rect {
    CGFloat screenHeight = 0;
    CGFloat screenOriginY = 0;

    // 获取屏幕列表
    NSArray *screens = [NSScreen screens];

    // 获取当前屏幕
    NSScreen *mainScreen = [NSScreen mainScreen];
    for (NSScreen *screen in screens) {
        if (CGRectEqualToRect([screen frame], [mainScreen frame])) {
            // 如果是主屏幕
            screenOriginY = 0;
            screenHeight = [screen visibleFrame].size.height;
            break;
        } else if (CGRectIntersectsRect([screen frame], [mainScreen frame])) {
            // 如果是外接显示器
            screenOriginY = [screen frame].size.height - [screen visibleFrame].origin.y - [screen visibleFrame].size.height;
            screenHeight = [screen visibleFrame].size.height;
            break;
        }
    }

    // 转换坐标
    CGRect bottomLeftRect = CGRectMake(rect.origin.x,
                                        screenHeight - (rect.origin.y + rect.size.height) + screenOriginY,
                                        rect.size.width,
                                        rect.size.height);

    return bottomLeftRect;
}

/// Convert point from top-left to left-bottom coordinate system
+ (CGPoint)convertPointToBottomLeft:(CGPoint)point {
    // 获取主屏幕的坐标系信息
    NSScreen *mainScreen = [NSScreen mainScreen];
    NSRect mainFrame = [mainScreen frame];
    CGFloat mainHeight = NSHeight(mainFrame);
//    CGFloat mainWidth = NSWidth(mainFrame);
    
    // 得到左下角坐标下的点
    CGPoint bottomLeftPoint = CGPointMake(point.x, mainHeight - point.y);
    
    // 如果有一个外接显示器，则需要在外接显示器下的坐标系进行转换
    NSArray<NSScreen *> *screens = [NSScreen screens];
    if (screens.count > 1) {
        // 获取主屏幕外的所有外接的屏幕
        NSArray<NSScreen *> *externalScreens = [screens filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSScreen *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ![evaluatedObject isEqual:mainScreen];
        }]];
        
        // 依次计算每一个屏幕下的坐标系转换后对应的 CGPoint
        for (NSScreen *screen in externalScreens) {
            NSRect externalFrame = [screen frame];
            CGFloat externalHeight = NSHeight(externalFrame);
            CGFloat externalWidth = NSWidth(externalFrame);
            
            // 如果 point 在该屏幕中，就需要对 point 进行转换
            if (point.x >= externalFrame.origin.x
                && point.y >= externalFrame.origin.y
                && point.x <= externalFrame.origin.x + externalWidth
                && point.y <= externalFrame.origin.x + externalHeight) {
                bottomLeftPoint = CGPointMake(point.x - externalFrame.origin.x,
                                              externalHeight - point.y + externalFrame.origin.y + mainHeight - externalHeight);
                break;
            }
        }
    }
    
    return bottomLeftPoint;
}


#pragma mark -

/// Get frame Top-Left point, default frame origin is Bottom-Left.
/// !!!: Coordinate system is still Bottom-Left, not changed.
+ (CGPoint)getFrameTopLeftPoint:(CGRect)frame {
    CGPoint origin = frame.origin;
    CGPoint position = CGPointMake(origin.x, frame.size.height + origin.y);
    return position;
}

@end
