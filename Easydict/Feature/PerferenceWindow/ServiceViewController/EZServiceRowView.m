//
//  EZServiceTableRowView.m
//  Easydict
//
//  Created by tisfeng on 2022/12/25.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZServiceRowView.h"

@implementation EZServiceRowView

/// Rewirte select row view color.
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
        NSRect selectionRect = self.bounds;
        [self excuteLight:^(NSTextField *nameLabel) {
            [[NSColor mm_colorWithHexString:@"#DDDDDD"] setFill];
            NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRect:selectionRect];
            [selectionPath fill];
        } drak:^(NSTextField *nameLabel) {
            [[NSColor mm_colorWithHexString:@"#464646"] setFill];
            NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRect:selectionRect];
            [selectionPath fill];
        }];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [self excuteLight:^(id _Nonnull x) {
        [[NSColor whiteColor] setFill];
        NSRectFill(dirtyRect);
    } drak:^(id _Nonnull x) {
        [[NSColor resultViewBgDarkColor] setFill];
        NSRectFill(dirtyRect);
    }];
    
    // The super method must be called only at the end, otherwise it will overwrite the selected background color.
    [super drawRect:dirtyRect];
}

@end
