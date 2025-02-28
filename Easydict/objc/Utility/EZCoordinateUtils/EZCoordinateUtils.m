//
//  EZCoordinateUtils.m
//  Easydict
//
//  Created by tisfeng on 2022/11/23.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZCoordinateUtils.h"

@implementation EZCoordinateUtils

/// left-bottom safe postion.
+ (CGPoint)getFrameSafePoint:(CGRect)frame moveToPoint:(CGPoint)point inScreenVisibleFrame:(CGRect)screenVisibleFrame {
    CGRect newFrame = CGRectMake(point.x, point.y, frame.size.width, frame.size.height);
    return [self getSafeLocation:newFrame inScreenVisibleFrame:screenVisibleFrame];
}

+ (CGRect)getSafeFrame:(CGRect)frame moveToPoint:(CGPoint)point inScreenVisibleFrame:(CGRect)screenVisibleFrame {
    CGRect newFrame = CGRectMake(point.x, point.y, frame.size.width, frame.size.height);
    return [self getSafeAreaFrame:newFrame inScreenVisibleFrame:screenVisibleFrame];
}

/// left-bottom safe postion.
+ (CGPoint)getSafeLocation:(CGRect)frame inScreenVisibleFrame:(CGRect)screenVisibleFrame {
    CGRect safeFrame = [self getSafeAreaFrame:frame inScreenVisibleFrame:screenVisibleFrame];
    return safeFrame.origin;
}

/// Make sure frame show in screen visible frame, return left-bottom postion frame.
+ (CGRect)getSafeAreaFrame:(CGRect)frame inScreenVisibleFrame:(CGRect)screenVisibleFrame {
    if (CGRectContainsRect(screenVisibleFrame, frame)) {
        return frame;
    }

    CGFloat x = frame.origin.x;
    CGFloat y = frame.origin.y;
    CGFloat width = frame.size.width;
    CGFloat height = frame.size.height;

    // left safe
    if (x < screenVisibleFrame.origin.x) {
        x = screenVisibleFrame.origin.x;
    }
    // right safe
    if (x + width > screenVisibleFrame.origin.x + screenVisibleFrame.size.width) {
        x = screenVisibleFrame.origin.x + screenVisibleFrame.size.width - width;
    }

    // top safe
    if (y > screenVisibleFrame.origin.y + screenVisibleFrame.size.height) {
        y = screenVisibleFrame.origin.y + screenVisibleFrame.size.height;
    }
    // keep bottom safe, if frame bottom beyond visibleFrame bottom and frame height <= visibleFrame height , try to move it up.
    if (y < screenVisibleFrame.origin.y && height <= screenVisibleFrame.size.height) {
        y = screenVisibleFrame.origin.y;
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

+ (CGPoint)getTopLeftPoint:(CGPoint)point inScreen:(nullable NSScreen *)screen {
    CGPoint position = CGPointZero;
    
    if (!screen) {
        screen = [self screenOfMousePosition];
    }
    NSRect screenRect = [screen visibleFrame];

    // top-left point
    CGFloat x = screenRect.origin.x + point.x;
    CGFloat y = screenRect.origin.y + point.y;
    position = CGPointMake(x, y);

    return position;
}

@end
