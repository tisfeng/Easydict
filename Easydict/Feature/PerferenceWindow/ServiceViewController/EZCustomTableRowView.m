//
//  EZServiceTableRowView.m
//  Easydict
//
//  Created by tisfeng on 2022/12/25.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZCustomTableRowView.h"

@implementation EZCustomTableRowView

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [NSColor.ez_tableRowViewBgColor setFill];
    NSRectFill(dirtyRect);
}

/// Rewirte select row view color.
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
        NSRect selectionRect = self.bounds;
        NSColor *color = [NSColor ez_dynamicColorLight:[NSColor mm_colorWithHexString:@"#404040"] dark:[NSColor mm_colorWithHexString:@"#404040"]];
        [color setFill];
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRect:selectionRect];
        [selectionPath fill];
    }
}

@end
