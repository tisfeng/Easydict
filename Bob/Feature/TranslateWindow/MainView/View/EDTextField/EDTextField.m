//
//  EDTextField.m
//  Bob
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EDTextField.h"


@implementation EDTextField

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.editable = NO;
    self.backgroundColor = NSColor.clearColor;

    [self excuteLight:^(id x) {
        [x setTextColor:NSColor.resultTextLightColor];
    } drak:^(id _Nonnull x) {
        [x setTextColor:NSColor.resultTextDarkColor];
    }];
}

- (void)setText:(NSString *)text {
    _text = text;
    self.stringValue = text;
    
    // Character spacing
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSKernAttributeName : @(0.5)}];
    
    // Line spacing
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:3];

    [attributedString addAttributes:@{
        NSParagraphStyleAttributeName : paragraphStyle,
        NSFontAttributeName : [NSFont systemFontOfSize:14],
    } range:NSMakeRange(0, text.length)];
    
    self.attributedStringValue = attributedString;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
