//
//  EDTextField.m
//  Bob
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZLabel.h"

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
    
    [self setDefaultParagraphStyle:[NSMutableParagraphStyle mm_make:^(NSMutableParagraphStyle *_Nonnull style) {
        style.lineHeightMultiple = 1.2;
        //        style.lineSpacing = 5;
        style.paragraphSpacing = 5;
    }]];
    self.font = [NSFont systemFontOfSize:14];
    [self setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    
    //    self.textContainerInset = CGSizeMake(8, 12);
}

- (void)setText:(NSString *)text {
    _text = text;
    
    self.string = text;
    NSRange range = NSMakeRange(0, text.length);
    
    // Character spacing
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSKernAttributeName : @(0.5)}];
    
    // Line spacing
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:3];
    
    [attributedString addAttributes:@{
        NSParagraphStyleAttributeName : paragraphStyle,
        NSFontAttributeName : [NSFont systemFontOfSize:14],
    }
                              range:range];
    
    [self excuteLight:^(NSTextView *textView) {
        [attributedString addAttributes:@{
            NSForegroundColorAttributeName : NSColor.resultTextLightColor,
        }
                                  range:range];
        [textView.textStorage setAttributedString:attributedString];
    } drak:^(NSTextView *textView) {
        [textView.textStorage deleteCharactersInRange:NSMakeRange(0, textView.textStorage.length)];
        
        [attributedString addAttributes:@{
            NSForegroundColorAttributeName : NSColor.resultTextDarkColor,
        }
                                  range:range];
        [textView.textStorage setAttributedString:attributedString];
    }];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
