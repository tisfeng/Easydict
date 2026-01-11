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
    if (!text) {
        text = @"";
    }

    _text = text;
    self.string = text;

    // Create attributed string and set range
    NSRange range = NSMakeRange(0, text.length);
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];

    // Use static or cached paragraph style object
    static NSMutableParagraphStyle *paragraphStyle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    });

    paragraphStyle.lineSpacing = self.lineSpacing;
    paragraphStyle.paragraphSpacing = self.paragraphSpacing;

    // Set common attributes
    NSDictionary *attributes = @{
        NSParagraphStyleAttributeName : paragraphStyle,
        NSKernAttributeName : @(0.2),
        NSFontAttributeName : self.font,
    };
    [attributedString addAttributes:attributes range:range];

    // Handle color for light/dark mode
    [self executeLight:^(NSTextView *textView) {
        NSColor *color = self.textForegroundColor ?: [NSColor ez_resultTextLightColor];
        [self updateTextView:textView withAttributedString:attributedString color:color range:range];
    } dark:^(NSTextView *textView) {
        NSColor *color = self.textForegroundColor ?: [NSColor ez_resultTextDarkColor];
        [self updateTextView:textView withAttributedString:attributedString color:color range:range];
    }];
}

// Helper method to update text view with color
- (void)updateTextView:(NSTextView *)textView
    withAttributedString:(NSMutableAttributedString *)attributedString
                   color:(NSColor *)color
                   range:(NSRange)range {
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:range];
    textView.textStorage.attributedString = attributedString;
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
