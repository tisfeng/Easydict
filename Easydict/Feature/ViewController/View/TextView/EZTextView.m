//
//  EZTextView.m
//  Easydict
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
        
        /**
         FIX: Since textView will auto replace some text, such as "..." to "…", so we need to disable it.
         
         Default enabledTextCheckingTypes is 9153 = 0b10001111000001
         means default enabled types are:
         NSTextCheckingTypeOrthography           = 1ULL << 0,            // language identification
         // NSTextCheckingTypeSpelling              = 1ULL << 1,            // spell checking
         // NSTextCheckingTypeGrammar               = 1ULL << 2,            // grammar checking
         // NSTextCheckingTypeDate                  = 1ULL << 3,            // date/time detection
         // NSTextCheckingTypeAddress               = 1ULL << 4,             address detection
         // NSTextCheckingTypeLink                  = 1ULL << 5,            // link detection
         // NSTextCheckingTypeQuote                 = 1ULL << 6,             smart quotes
         NSTextCheckingTypeDash                  = 1ULL << 7,            // smart dashes
         NSTextCheckingTypeReplacement           = 1ULL << 8,            // fixed replacements, such as copyright symbol for (c)
         NSTextCheckingTypeCorrection            = 1ULL << 9,            // autocorrection
         NSTextCheckingTypeRegularExpression     = 1ULL << 10,           // regular expression matches
         // NSTextCheckingTypePhoneNumber         = 1ULL << 11,           // phone number detection
         // NSTextCheckingTypeTransitInformation  = 1ULL << 12           // transit (e.g. flight) info detection
         */
        
        self.enabledTextCheckingTypes =
        NSTextCheckingTypeOrthography
        //        | NSTextCheckingTypeSpelling
        | NSTextCheckingTypeGrammar
        | NSTextCheckingTypeDate
        | NSTextCheckingTypeAddress
        | NSTextCheckingTypeLink
        | NSTextCheckingTypeQuote
        //        | NSTextCheckingTypeDash // replace "..." with "…"
        | NSTextCheckingTypeReplacement
        | NSTextCheckingTypeCorrection
        //        | NSTextCheckingTypeRegularExpression
        | NSTextCheckingTypePhoneNumber
        | NSTextCheckingTypeTransitInformation;
        
        [self excuteLight:^(EZTextView *textView) {
            textView.backgroundColor = NSColor.queryViewBgLightColor;
            [textView setTextColor:NSColor.queryTextLightColor];
        } drak:^(EZTextView *textView) {
            textView.backgroundColor = NSColor.queryViewBgDarkColor;
            [textView setTextColor:NSColor.queryTextDarkColor];
        }];
        self.alignment = NSTextAlignmentLeft;
        self.textContainerInset = CGSizeMake(0, 0);
        self.automaticLinkDetectionEnabled = YES;
    }
    return self;
}

// 重写父类方法，无格式粘贴  https://stackoverflow.com/questions/8198767/how-can-you-intercept-pasting-into-a-nstextview-to-remove-unsupported-formatting
- (void)paste:(id)sender {
    [self pasteAsPlainText:sender];
    
    if (self.pasteTextBlock) {
        self.pasteTextBlock(self.string);
    }
    
    // TODO: need to handle select all text and paste condition!
}

@end
