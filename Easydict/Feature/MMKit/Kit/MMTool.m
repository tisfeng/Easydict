//
//  MMTool.m
//  Bob
//
//  Created by ripper on 2019/12/19.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "MMTool.h"

BOOL MMPointInRect(NSPoint aPoint, NSRect aRect) {
    if (aPoint.x >= aRect.origin.x &&
        aPoint.y >= aRect.origin.y &&
        aPoint.x <= aRect.origin.x + aRect.size.width &&
        aPoint.y <= aRect.origin.y + aRect.size.height) {
        return YES;
    }
    return NO;
}
