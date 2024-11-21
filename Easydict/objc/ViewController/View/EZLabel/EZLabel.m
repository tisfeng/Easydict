//
//  EDTextField.m
//  Easydict
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLabel.h"
#import "NSTextView+Height.h"

@implementation EZLabel

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.editable = NO;
    self.backgroundColor = NSColor.clearColor;
    [self setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];

    self.lineSpacing = 4;
    self.paragraphSpacing = 0;
    self.font = [NSFont systemFontOfSize:14];
    self.textContainer.lineFragmentPadding = 2; // Default value: 5.0
}

- (void)setText:(NSString *)text {
    _text = text;
    self.string = text;

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange range = NSMakeRange(0, text.length);

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = self.lineSpacing;
    paragraphStyle.paragraphSpacing = self.paragraphSpacing;

    [attributedString addAttributes:@{
        NSParagraphStyleAttributeName : paragraphStyle,
        NSKernAttributeName : @(0.2),
        NSFontAttributeName : self.font,
    }
                              range:range];

    __block NSColor *textColor = self.textForegroundColor ?: nil;
    [self excuteLight:^(NSTextView *textView) {
        textColor = textColor ?: [NSColor ez_resultTextLightColor];
        [attributedString addAttribute:NSForegroundColorAttributeName value:textColor range:range];
        textView.textStorage.attributedString = attributedString;
    } dark:^(NSTextView *textView) {
        textColor = textColor ?: [NSColor ez_resultTextDarkColor];
        [attributedString addAttribute:NSForegroundColorAttributeName value:textColor range:range];
        textView.textStorage.attributedString = attributedString;
    }];
}


#pragma mark -

- (CGSize)oneLineSize {
    CGSize size = [self ez_getTextViewSize];
    return size;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Drawing code here.
}

@end
