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
    [self excuteLight:^(id _Nonnull x) {
        [[NSColor ez_tableRowViewBgLightColor] setFill];
        NSRectFill(dirtyRect);
    } dark:^(id _Nonnull x) {
        [[NSColor ez_tableRowViewBgDarkColor] setFill];
        NSRectFill(dirtyRect);
    }];
}

/// Rewirte select row view color.
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
        NSRect selectionRect = self.bounds;
        [self excuteLight:^(NSTextField *nameLabel) {
            [[NSColor mm_colorWithHexString:@"#B4D8FF"] setFill];
            NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRect:selectionRect];
            [selectionPath fill];
        } dark:^(NSTextField *nameLabel) {
            [[NSColor mm_colorWithHexString:@"#404040"] setFill];
            NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRect:selectionRect];
            [selectionPath fill];
        }];
    }
}

@end
