//
//  CTScreen.m
//  CoolToast
//
//  Created by Socoolby on 2019/7/1.
//  Copyright © 2019 Socoolby. All rights reserved.
//

#import "CTScreen.h"

@implementation CTScreen

+ (CGPoint)mouseLocationInScreen {
    return [NSEvent mouseLocation];
}

+ (NSScreen *)getMainScreen {
    return [NSScreen mainScreen];
}

+ (NSScreen *)getCurrentScreen {
    NSArray *screenArray = [NSScreen screens];
    CGPoint mousePoint = [self mouseLocationInScreen];
    for (NSScreen *screen in screenArray) {
        if (CGRectContainsPoint(screen.frame, mousePoint)) {
            return screen;
        }
    }
    return [self getMainScreen];
}

+ (NSRect)frameForScreen:(NSScreen *)screen {
    NSScreen *baseScreen = [NSScreen screens].firstObject;
    NSRect baseFrame = baseScreen.frame;
    
    NSRect mainFrame = screen.frame;
    NSRect mainVisibleFrame = screen.visibleFrame;
    
    NSRect frame = NSMakeRect(mainVisibleFrame.origin.x,
                              baseFrame.size.height - mainFrame.size.height - mainFrame.origin.y,
                              mainVisibleFrame.size.width,
                              mainVisibleFrame.size.height);
    
    return frame;
}

@end
