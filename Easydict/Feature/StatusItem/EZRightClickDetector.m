//
//  EZRightClickDetector.m
//  Easydict
//
//  Created by tisfeng on 2023/4/18.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZRightClickDetector.h"

@implementation EZRightClickDetector

- (void)rightMouseUp:(NSEvent *)theEvent {
    if (self.onRightMouseClicked) {
        self.onRightMouseClicked(theEvent);
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Drawing code here.
}

@end
