//
//  EDTextField.m
//  Easydict
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLabel.h"
#import "NSTextView+Height.h"
#import "NSObject+EZDarkMode.h"
#import "Easydict-Swift.h"

@interface EZLabel ()

@property (nonatomic, strong) NSFont *configuredFont;

@end

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

    [self executeOnAppearanceChange:^(EZLabel *label, BOOL isDarkMode) {
        [label updateDisplayedText];
    }];
}

- (void)setText:(NSString *)text {
    NSString *displayText = text ?: @"";
    _text = [displayText copy];
    self.string = displayText;
    [self updateDisplayedText];
}

- (void)setTextForegroundColor:(NSColor *)textForegroundColor {
    _textForegroundColor = textForegroundColor;
    [self updateDisplayedText];
}

- (void)setLineSpacing:(CGFloat)lineSpacing {
    _lineSpacing = lineSpacing;
    [self updateDisplayedText];
}

- (void)setParagraphSpacing:(CGFloat)paragraphSpacing {
    _paragraphSpacing = paragraphSpacing;
    [self updateDisplayedText];
}

- (void)setFont:(NSFont *)font {
    self.configuredFont = font;
    [super setFont:font];
    [self updateDisplayedText];
}

- (NSFont *)font {
    // A fallback font for the first glyph must not become the font of the whole label.
    return self.configuredFont ?: [super font];
}

- (void)updateDisplayedText {
    NSString *displayText = self.text ?: @"";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:displayText];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = self.lineSpacing;
    paragraphStyle.paragraphSpacing = self.paragraphSpacing;

    NSColor *textColor = self.textForegroundColor ?: (self.isDarkMode ? [NSColor ez_resultTextDarkColor] : [NSColor ez_resultTextLightColor]);
    if (displayText.length > 0) {
        NSDictionary *attributes = @{
            NSParagraphStyleAttributeName : paragraphStyle,
            NSFontAttributeName : self.font,
            NSForegroundColorAttributeName : textColor,
        };
        [attributedString addAttributes:attributes range:NSMakeRange(0, displayText.length)];
        // Tracking is a Latin typographic adjustment; Core Text fills it on
        // cursive scripts with tatweel glyphs and breaks Arabic shaping.
        [attributedString mm_applyKernExcludingCursiveScripts:0.2];
    }

    self.textStorage.attributedString = attributedString;
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
