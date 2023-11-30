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
        self.expandValue = 5;
        self.fontSize = 14;
    }
    return self;
}

- (void)setTitle:(NSString *)title {    
    NSFont *textFont = [NSFont systemFontOfSize:self.fontSize];
    self.attributedTitle = [NSAttributedString mm_attributedStringWithString:title font:textFont color:[NSColor ez_blueTitleColor]];
    
    [self sizeToFit];
    CGSize size = self.size;
    CGSize expandSize = CGSizeMake(size.width + self.expandValue, size.height + self.expandValue);
    self.size = expandSize;
    
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(expandSize);
    }];
}

- (void)setOpenURL:(NSString *)openURL {
    _openURL = openURL;
    
    if ([openURL isURL]) {
        mm_weakify(self);
        [self setClickBlock:^(EZButton * _Nonnull button) {
            mm_strongify(self);
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:openURL]];
            
            if (self.closeWindowAfterOpeningURL) {
                [self.window close];
            }
        }];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
