//
//  EZServiceTableRowView.m
//  Easydict
//
//  Created by tisfeng on 2022/12/25.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZServiceRowView.h"

@implementation EZServiceRowView

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
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
