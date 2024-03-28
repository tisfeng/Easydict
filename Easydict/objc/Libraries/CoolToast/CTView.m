//
//  CTView.m
//  CoolToast
//
//  Created by Socoolby on 2019/7/5.
//  Copyright © 2019 Socoolby. All rights reserved.
//

#import "CTView.h"

@implementation CTView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

// Overrite for tap event.
- (BOOL)acceptsFirstMouse:(nullable NSEvent *)event {
    return YES;
}
@end
