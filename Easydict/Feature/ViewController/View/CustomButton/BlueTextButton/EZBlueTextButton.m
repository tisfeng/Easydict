//
//  EZBlueTextButton.m
//  Easydict
//
//  Created by tisfeng on 2022/12/13.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZBlueTextButton.h"

@implementation EZBlueTextButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.expandValue = 6;
    }
    return self;
}

- (void)setTitle:(NSString *)title {    
    NSFont *textFont = [NSFont systemFontOfSize:14];
    self.attributedTitle = [NSAttributedString mm_attributedStringWithString:title font:textFont color:[NSColor mm_colorWithHexString:@"#007AFF"]];
    
    [self sizeToFit];
    CGSize size = self.size;
    CGSize expandSize = CGSizeMake(size.width + self.expandValue, size.height + self.expandValue);
    self.size = expandSize;
    
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(expandSize);
    }];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
