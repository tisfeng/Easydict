//
//  TextView.m
//  Bob
//
//  Created by ripper on 2019/12/11.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "TextView.h"
#import "NSColor+MyColors.h"

@implementation TextView

DefineMethodMMMake_m(TextView);

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Rulers/Concepts/AboutParaStyles.html#//apple_ref/doc/uid/20000879-CJBBEHJA
        [self setDefaultParagraphStyle:[NSMutableParagraphStyle mm_make:^(NSMutableParagraphStyle *_Nonnull style) {
                  style.lineHeightMultiple = 1.2;
                  style.paragraphSpacing = 0;
              }]];
        self.font = [NSFont systemFontOfSize:14];

        [self excuteLight:^(TextView *textView) {
            textView.backgroundColor = NSColor.queryViewBgLightColor;
            [textView setTextColor:NSColor.queryTextLightColor];
        } drak:^(TextView *textView) {
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
}

@end
