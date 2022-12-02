//
//  EZTextView.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTextView.h"

@implementation EZTextView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Rulers/Concepts/AboutParaStyles.html#//apple_ref/doc/uid/20000879-CJBBEHJA
        [self setDefaultParagraphStyle:[NSMutableParagraphStyle mm_make:^(NSMutableParagraphStyle *_Nonnull style) {
            style.lineHeightMultiple = 1.2;
            style.paragraphSpacing = 0;
            style.lineBreakMode = NSLineBreakByWordWrapping;
        }]];
        self.font = [NSFont systemFontOfSize:14];
        
        [self excuteLight:^(EZTextView *textView) {
            textView.backgroundColor = NSColor.queryViewBgLightColor;
            [textView setTextColor:NSColor.queryTextLightColor];
        } drak:^(EZTextView *textView) {
            textView.backgroundColor = NSColor.queryViewBgDarkColor;
            [textView setTextColor:NSColor.queryTextDarkColor];
        }];
        self.alignment = NSTextAlignmentLeft;
        self.textContainerInset = CGSizeMake(8, 8);
    }
    return self;
}

// 重写父类方法，无格式粘贴  https://stackoverflow.com/questions/8198767/how-can-you-intercept-pasting-into-a-nstextview-to-remove-unsupported-formatting
- (void)paste:(id)sender {
    [self pasteAsPlainText:sender];
    
    // TODO: need to handle select all text and paste condition!
}

@end
