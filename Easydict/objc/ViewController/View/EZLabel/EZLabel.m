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
    NSRange range = NSMakeRange(0, text.length);
    
    // Character spacing
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    
    // Line spacing
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = self.lineSpacing;
    paragraphStyle.paragraphSpacing = self.paragraphSpacing;
    
    [attributedString addAttributes:@{
        NSParagraphStyleAttributeName : paragraphStyle,
        NSKernAttributeName : @(0.2),
        NSFontAttributeName : self.font,
    }
                              range:range];
    
    [self excuteLight:^(NSTextView *textView) {
        [attributedString addAttributes:@{
            NSForegroundColorAttributeName : self.textForegroundColor ?: [NSColor ez_resultTextLightColor],
        }
                                  range:range];
        [textView.textStorage setAttributedString:attributedString];
    } dark:^(NSTextView *textView) {
        [attributedString addAttributes:@{
            NSForegroundColorAttributeName : self.textForegroundColor ?: [NSColor ez_resultTextDarkColor],
        }
                                  range:range];
        [textView.textStorage setAttributedString:attributedString];
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
