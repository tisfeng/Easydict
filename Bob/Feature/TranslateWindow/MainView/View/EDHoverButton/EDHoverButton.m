//
//  HoverButton.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EDHoverButton.h"

@implementation EDHoverButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.hasBorder = YES;
    self.canSelected = NO;

    CGFloat borderWidth = 0;
    self.borderNormalWidth = borderWidth;
    self.borderHoverWidth = borderWidth;
    self.borderHighlightWidth = borderWidth;
    
    CGFloat cornerRadius = 5;
    self.cornerNormalRadius = cornerRadius;
    self.cornerHoverRadius = cornerRadius;
    self.cornerHighlightRadius = cornerRadius;
    
    self.backgroundNormalColor = NSColor.clearColor;
    
    [self excuteLight:^(SWSTAnswerButton *button) {
        button.contentTintColor = NSColor.blackColor;
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#E6E6E6"];
        button.backgroundHighlightColor = NSColor.lightGrayColor;
    } drak:^(SWSTAnswerButton *button) {
        button.contentTintColor = NSColor.whiteColor;
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#353535"];
        button.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#454545"];
    }];
}

- (void)setActionBlock:(void (^)(EDHoverButton *_Nonnull))actionBlock {
    _actionBlock = actionBlock;
    
    mm_weakify(self)
    [self setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
        NSLog(@"Click EDHoverButton");
        
        mm_strongify(self)
        if (self.actionBlock) {
            self.actionBlock(self);
        }
        return RACSignal.empty;
    }]];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
