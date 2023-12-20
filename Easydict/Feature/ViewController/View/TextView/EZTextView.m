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

@property (nonatomic, assign) CGFloat defaultParagraphSpacing; // 15
@property (nonatomic, assign) CGFloat miniParagraphSpacing; // 0

/// paragraphSpacing
@property (nonatomic, assign) CGFloat paragraphSpacing;

@end

@implementation EZTextView

// TODO: EZTextView is similar to EZLabel, we need to refactor them.
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        CGFloat defaultParagraphSpacing = 15;
        CGFloat miniParagraphSpacing = 0;
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Rulers/Concepts/AboutParaStyles.html#//apple_ref/doc/uid/20000879-CJBBEHJA
        [self setDefaultParagraphStyle:[NSMutableParagraphStyle mm_make:^(NSMutableParagraphStyle *_Nonnull style) {
            style.lineSpacing = 4;
            style.paragraphSpacing = defaultParagraphSpacing;
            style.lineHeightMultiple = 1.0;
            style.lineBreakMode = NSLineBreakByWordWrapping;
        }]];
        
        self.font = [NSFont systemFontOfSize:14];
        self.defaultParagraphSpacing = defaultParagraphSpacing;
        self.miniParagraphSpacing = miniParagraphSpacing;

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
            textView.backgroundColor = [NSColor ez_queryViewBgLightColor];
            [textView setTextColor:[NSColor ez_queryTextLightColor]];
        } dark:^(EZTextView *textView) {
            textView.backgroundColor = [NSColor ez_queryViewBgDarkColor];
            [textView setTextColor:[NSColor ez_queryTextDarkColor]];
        }];
        self.alignment = NSTextAlignmentLeft;
        self.textContainerInset = CGSizeMake(0, 0);
        self.automaticLinkDetectionEnabled = YES;

        _placeholderText = @"placeholder";
        _placeholderColor = NSColor.placeholderTextColor;

        //  [self setupPlaceHolderTextView];
    }
    return self;
}

// 重写粘贴方法，纯文本粘贴  https://stackoverflow.com/questions/8198767/how-can-you-intercept-pasting-into-a-nstextview-to-remove-unsupported-formatting
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
    NSPasteboardType stringType = [pasteboard availableTypeFromArray:@[
        NSPasteboardTypeString,
        NSPasteboardTypeRTF,
        NSPasteboardTypeRTFD
    ]];
    NSString *pasteboardString = [pasteboard stringForType:stringType];
    pasteboardString = [pasteboardString trim];
    
    // pasteboardString may be nil
    if (!pasteboardString) {
        return;
    }
    
    BOOL enableModifyParagraphSpacing = NO;
    
    // Empty text.
    if (self.textStorage.length == 0) {
        enableModifyParagraphSpacing = YES;
    }

    if (self.selectedRange.length > 0) {
        // Select all text.
        if (self.selectedRange.length == self.textStorage.length) {
            enableModifyParagraphSpacing = YES;
        }
        
        NSRange selectedRange = self.selectedRange;
        NSUInteger newLocation = selectedRange.location + pasteboardString.length;
        NSRange modifiedRange = NSMakeRange(selectedRange.location, pasteboardString.length);
        NSString *modifiedString = [self.string stringByReplacingCharactersInRange:selectedRange withString:pasteboardString];
        [self setString:modifiedString];
        [self setSelectedRange:NSMakeRange(newLocation, 0)];
        [self didChangeText];
        [self scrollRangeToVisible:modifiedRange];
    } else {
        // !!!: We need to use NSAttributedString to paste text, otherwise the text will be displayed in the wrong ParagraphStyle.
        NSDictionary *attributes = @{NSParagraphStyleAttributeName: self.defaultParagraphStyle};
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:pasteboardString attributes:attributes];
        
        // This method will call textDidChange
        [self insertText:attributedString replacementRange:NSMakeRange(self.selectedRange.location, 0)];
    }
    
    if (enableModifyParagraphSpacing) {
        [self updateTextAndParagraphStyle:pasteboardString];
    }
}

#pragma mark - Setter

- (void)setCustomParagraphSpacing:(CGFloat)customParagraphSpacing {
    _customParagraphSpacing = customParagraphSpacing;
    
    [self setParagraphSpacing:customParagraphSpacing];
}

- (void)setParagraphSpacing:(CGFloat)paragraphSpacing {
    _paragraphSpacing = paragraphSpacing;
        
    // 获取默认段落样式，创建新的段落样式并设置新的 paragraphSpacing
    NSParagraphStyle *defaultParagraphStyle = [self defaultParagraphStyle];
    NSMutableParagraphStyle *newParagraphStyle = [defaultParagraphStyle mutableCopy];
    [newParagraphStyle setParagraphSpacing:paragraphSpacing];

    [self setDefaultParagraphStyle:newParagraphStyle];
    
    
    // Update all textStorage style.
    NSRange effectiveRange = NSMakeRange(0, self.textStorage.length);
    [self.textStorage addAttribute:NSParagraphStyleAttributeName value:newParagraphStyle range:effectiveRange];
    
    // Need to notify, to update textView height.
//    [self didChangeText];
    
    [self setNeedsDisplay:YES];
}

/// Update text, paragraphStyle.
- (void)updateTextAndParagraphStyle:(NSString *)text {
    self.string = text;
    
    NSString *newText = [text removeExtraLineBreaks];
    
    // If the text has extra Line Breaks, then we don't need to add paragraph spacing.
    BOOL hasExtraLineBreaks = ![newText isEqualToString:text];
    
    CGFloat paragraphSpacing = hasExtraLineBreaks ? self.miniParagraphSpacing : self.defaultParagraphSpacing;
    // If has custom paragraphSpacing, use it.
    if (self.customParagraphSpacing > 0) {
        paragraphSpacing = self.customParagraphSpacing;
    }
    self.paragraphSpacing = paragraphSpacing;
    
    // Callback shoud after updating paragraphSpacing, to update textView height.
    if (self.updateTextBlock) {
        self.updateTextBlock(text);
    }
}

#pragma mark -

- (void)setupPlaceHolderTextView {
    self.placeholderTextField = [[NSTextField alloc] initWithFrame:self.bounds];

    self.placeholderTextField.height = 100;
    self.placeholderTextField.font = self.font;
    self.placeholderTextField.editable = NO;
    self.placeholderTextField.selectable = NO;

    [self.placeholderTextField excuteLight:^(NSTextView *placeholderTextView) {
        [placeholderTextView setBackgroundColor:[NSColor ez_queryViewBgLightColor]];
    } dark:^(NSTextView *placeholderTextView) {
        [placeholderTextView setBackgroundColor:[NSColor ez_queryViewBgDarkColor]];
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
