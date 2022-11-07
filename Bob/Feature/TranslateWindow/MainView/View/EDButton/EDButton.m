//
//  HoverButton.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EDButton.h"

@implementation EDButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.wantsLayer = YES;
        self.cornerRadius = 5;
    }
    return self;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    
    self.layer.cornerRadius = cornerRadius;
}

- (void)setActionBlock:(void (^)(EDButton *_Nonnull))actionBlock {
    _actionBlock = actionBlock;
    
    mm_weakify(self)
    [self setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
        mm_strongify(self) if (self.actionBlock) {
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
