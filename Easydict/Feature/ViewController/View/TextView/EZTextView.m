//
//  EZTextView.m
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTextView.h"

@interface EZTextView () <NSTextViewDelegate>

@property (nonatomic, strong) NSTextField *placeholderTextField;

@property (nonatomic, strong) NSColor *placeholderColor;
@property (nonatomic, strong) NSFont *placeholderFont;

@end

@implementation EZTextView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Rulers/Concepts/AboutParaStyles.html#//apple_ref/doc/uid/20000879-CJBBEHJA
        [self setDefaultParagraphStyle:[NSMutableParagraphStyle mm_make:^(NSMutableParagraphStyle *_Nonnull style) {
            style.lineSpacing = 4;
            style.paragraphSpacing = 12;
            style.lineHeightMultiple = 1.0;
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
            | NSTextCheckingTypeGrammar | NSTextCheckingTypeDate | NSTextCheckingTypeAddress | NSTextCheckingTypeLink | NSTextCheckingTypeQuote
            //        | NSTextCheckingTypeDash // replace "..." with "…"
            | NSTextCheckingTypeReplacement | NSTextCheckingTypeCorrection
            //        | NSTextCheckingTypeRegularExpression
            | NSTextCheckingTypePhoneNumber | NSTextCheckingTypeTransitInformation;

        [self excuteLight:^(EZTextView *textView) {
            textView.backgroundColor = NSColor.queryViewBgLightColor;
            [textView setTextColor:NSColor.queryTextLightColor];
        } dark:^(EZTextView *textView) {
            textView.backgroundColor = NSColor.queryViewBgDarkColor;
            [textView setTextColor:NSColor.queryTextDarkColor];
        }];
        self.alignment = NSTextAlignmentLeft;
        self.textContainerInset = CGSizeMake(0, 0);
        self.automaticLinkDetectionEnabled = YES;

        _placeholderText = @"placeholder";
        _placeholderColor = [NSColor colorWithCalibratedRed:128.0 / 255.0 green:128.0 / 255.0 blue:128.0 / 255.0 alpha:0.5];

//        [self setupPlaceHolderTextView];
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

/// Rewrite the parent method, paste without format. Supported by ChatGPT 😌
- (void)pasteAsPlainText:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSPasteboardType stringType = [pasteboard availableTypeFromArray:@[NSPasteboardTypeString, NSPasteboardTypeRTF, NSPasteboardTypeRTFD]];
    
    // Trim pasteboard string.
    NSString *pasteboardString = [[pasteboard stringForType:stringType] trim];
    
    if (self.selectedRange.length > 0) {
        NSRange selectedRange = self.selectedRange;
        NSUInteger newLocation = selectedRange.location + pasteboardString.length;
        NSRange modifiedRange = NSMakeRange(selectedRange.location, pasteboardString.length);
        NSString *modifiedString = [self.string stringByReplacingCharactersInRange:selectedRange withString:pasteboardString];
        [self setString:modifiedString];
        [self setSelectedRange:NSMakeRange(newLocation, 0)];
        [self didChangeText];
        [self scrollRangeToVisible:modifiedRange];
    } else {
        [self insertText:pasteboardString replacementRange:NSMakeRange(self.selectedRange.location, 0)];
    }
}


#pragma mark -

- (void)setupPlaceHolderTextView {
    self.placeholderTextField = [[NSTextField alloc] initWithFrame:self.bounds];
    
    
    self.placeholderTextField.height = 100;
    self.placeholderTextField.font = self.font;
    self.placeholderTextField.editable = NO;
    self.placeholderTextField.selectable = NO;
//    self.placeholderTextView.backgroundColor = [NSColor clearColor];
    
    [self.placeholderTextField excuteLight:^(NSTextView *placeholderTextView) {
        [placeholderTextView setBackgroundColor:NSColor.queryViewBgLightColor];
    } dark:^(NSTextView *placeholderTextView) {
        [placeholderTextView setBackgroundColor:NSColor.queryViewBgDarkColor];
    }];
    
    [self addSubview:self.placeholderTextField];
    
    [self.placeholderTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self).insets(NSEdgeInsetsMake(20, 20, 15, 20));
    }];

    NSDictionary *attributes = @{
        NSFontAttributeName : self.font,
        NSForegroundColorAttributeName : self.placeholderColor,
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:self.placeholderText attributes:attributes];
    self.placeholderTextField.attributedStringValue = attributedString;
    _placeholderAttributedString = attributedString;

    [self updatePlaceholderVisibility];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextViewDidChangeSelectionNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextStorageDidProcessEditingNotification object:self.textStorage];
}

- (void)updatePlaceholderVisibility {
    BOOL shouldShowPlaceholder = self.string.length == 0 && self.placeholderText.length > 0;
    self.placeholderTextField.hidden = !shouldShowPlaceholder;
}

- (void)setString:(NSString *)string {
    [super setString:string];
    [self updatePlaceholderVisibility];
}

- (void)setAttributedString:(NSAttributedString *)attrString {
    [[super textStorage] setAttributedString:attrString];
    [self updatePlaceholderVisibility];
}

- (void)textDidChange:(NSNotification *)notification {
    [self updatePlaceholderVisibility];
}

- (void)setPlaceholderColor:(NSColor *)placeholderColor {
    _placeholderColor = placeholderColor;
    
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [self.placeholderAttributedString attributesAtIndex:0 effectiveRange:nil].mutableCopy;

    attributes[NSForegroundColorAttributeName] = self.placeholderColor;

    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:self.placeholderText attributes:attributes];

    self.placeholderTextField.attributedStringValue = attributedString;
}

- (void)setPlaceholderText:(NSString *)placeholderText {
    _placeholderText = placeholderText;

    NSDictionary<NSAttributedStringKey, id> *attributes = [self.placeholderAttributedString attributesAtIndex:0 longestEffectiveRange:NULL inRange:NSMakeRange(0, [self.placeholderAttributedString length])];
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:self.placeholderText attributes:attributes];
    self.placeholderTextField.attributedStringValue = attributedString;
}

- (void)setPlaceholderAttributedString:(NSAttributedString *)placeholderAttributedString {
    _placeholderAttributedString = placeholderAttributedString;

    NSRange range = NSMakeRange(0, self.placeholderText.length);
    if (range.length == 0) {
        return;
    }
    
    self.placeholderTextField.attributedStringValue = placeholderAttributedString;
}


@end
