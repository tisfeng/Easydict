//
//  TextView.m
//  Bob
//
//  Created by ripper on 2019/12/11.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "TextView.h"

@implementation TextView

DefineMethodMMMake_m(TextView)

- (instancetype)init {
    self = [super init];
    if (self) {
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Rulers/Concepts/AboutParaStyles.html#//apple_ref/doc/uid/20000879-CJBBEHJA
        [self setDefaultParagraphStyle:[NSMutableParagraphStyle mm_make:^(NSMutableParagraphStyle *  _Nonnull style) {
            style.lineHeightMultiple = 1.2;
            style.paragraphSpacing = 5;
        }]];
        self.font = [NSFont systemFontOfSize:14];
        [self excuteLight:^(id  _Nonnull x) {
            [x setTextColor:[NSColor mm_colorWithHexString:@"#333333"]];
        } drak:^(id  _Nonnull x) {
            [x setTextColor:[NSColor whiteColor]];
        }];
        self.alignment = NSTextAlignmentLeft;
        self.textContainerInset  = CGSizeMake(8, 12);
    }
    return self;
}

// 重写父类方法，无格式粘贴
// https://stackoverflow.com/questions/8198767/how-can-you-intercept-pasting-into-a-nstextview-to-remove-unsupported-formatting
- (void)paste:(id)sender {
    [self pasteAsPlainText:sender];
}

@end
