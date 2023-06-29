//
//  EDQueryView.m
//  Easydict
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryView.h"
#import "NSTextView+Height.h"
#import "EZWindowManager.h"
#import "NSView+EZGetViewController.h"
#import "NSImage+EZResize.h"
#include <Carbon/Carbon.h>
#import "NSView+EZAnimatedHidden.h"
#import "EZDetectLanguageButton.h"
#import "EZSchemeParser.h"
#import "EZCopyButton.h"
#import "EZConfiguration.h"

@interface EZQueryView () <NSTextViewDelegate, NSTextStorageDelegate>

@property (nonatomic, strong) EZHoverButton *textCopyButton;

@property (nonatomic, strong) EZDetectLanguageButton *detectButton;
@property (nonatomic, strong) EZHoverButton *clearButton;
@property (nonatomic, strong) NSTextField *alertTextField;

@property (nonatomic, assign) CGFloat textViewMinHeight;
@property (nonatomic, assign) CGFloat textViewMaxHeight;

@property (nonatomic, copy) NSString *lastRecordText;
@property (nonatomic, assign) NSTimeInterval lastRecordTimestamp;

@property (nonatomic, strong) EZSchemeParser *schemeParser;

@end

@implementation EZQueryView

#pragma mark - NSTextViewDelegate

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.wantsLayer = YES;
    self.layer.cornerRadius = EZCornerRadius_8;
    [self.layer excuteLight:^(id _Nonnull x) {
        [x setBackgroundColor:[NSColor ez_queryViewBgLightColor].CGColor];
    } dark:^(id _Nonnull x) {
        [x setBackgroundColor:[NSColor ez_queryViewBgDarkColor].CGColor];
    }];
    
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
    self.scrollView = scrollView;
    [self addSubview:scrollView];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    scrollView.autohidesScrollers = YES;
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    EZTextView *textView = [[EZTextView alloc] initWithFrame:scrollView.bounds];
    textView.allowsUndo = YES;
    self.textView = textView;
    self.scrollView.documentView = textView;
    [textView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    textView.delegate = self;
    textView.textStorage.delegate = self;
    textView.textContainerInset = CGSizeMake(6, 8);
    
    mm_weakify(self);
    [textView setPasteTextBlock:^(NSString *_Nonnull text) {
        [self highlightAllLinks];
        
        if (self.pasteTextBlock) {
            self.pasteTextBlock(text);
        }
    }];
    
    // When programatically setting the text, like auto select text, or OCR text.
    [textView setUpdateTextBlock:^(NSString * _Nonnull text) {
        [self updateQueryText:text];
    }];
    
    EZLoadingAnimationView *loadingAnimationView = [[EZLoadingAnimationView alloc] init];
    [self addSubview:loadingAnimationView];
    self.loadingAnimationView = loadingAnimationView;
    
    [self.loadingAnimationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(textView).offset(5);
        make.left.equalTo(textView).offset(10);
        make.height.mas_equalTo(30);
    }];
    
    EZAudioButton *audioButton = [[EZAudioButton alloc] init];
    [self addSubview:audioButton];
    self.audioButton = audioButton;

    [audioButton setPlayStatus:^(BOOL isPlaying, EZAudioButton *audioButton) {
        NSString *action = isPlaying ? NSLocalizedString(@"stop_play_audio", nil) : NSLocalizedString(@"play_audio", nil);
        NSString *shortcut = @"⌘+S";
        audioButton.toolTip = [NSString stringWithFormat:@"%@, %@", action, shortcut];
    }];

    [audioButton setPlayAudioBlock:^{
        mm_strongify(self);
        if (self.playAudioBlock) {
            self.playAudioBlock(self.copiedText);
        }
    }];
    audioButton.mas_key = @"queryView_audioButton";
    
    EZCopyButton *textCopyButton = [[EZCopyButton alloc] init];
    [self addSubview:textCopyButton];
    self.textCopyButton = textCopyButton;
    
    NSString *copyAction = NSLocalizedString(@"copy_text", nil);
    NSString *copyShortcut = @"⌘+⇧+C";
    textCopyButton.toolTip = [NSString stringWithFormat:@"%@, %@",  copyAction, copyShortcut];
    
    [textCopyButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"copyActionBlock");
        mm_strongify(self);
        if (self.copyTextBlock) {
            self.copyTextBlock(self.copiedText);
        }
    }];
    textCopyButton.mas_key = @"queryView_copyButton";
    
    
    EZDetectLanguageButton *detectButton = [[EZDetectLanguageButton alloc] initWithFrame:self.bounds];
    [self addSubview:detectButton];
    self.detectButton = detectButton;
    
    [detectButton setMenuItemSeletedBlock:^(EZLanguage language) {
        mm_strongify(self);
        self.queryModel.needDetectLanguage = NO;
        NSString *text = [[self copiedText] trim];
        self.queryModel.specifiedTextLanguageDict[text] = language;
        if (self.selectedLanguageBlock) {
            self.selectedLanguageBlock(language);
        }
    }];
    
    detectButton.mas_key = @"detectButton";
    
    EZHoverButton *clearButton = [[EZHoverButton alloc] init];
    [self addSubview:clearButton];
    self.clearButton = clearButton;
    
    NSImage *clearImage = [NSImage imageWithSystemSymbolName:@"xmark.circle.fill" accessibilityDescription:nil];
    clearImage = [clearImage imageWithTintColor:[NSColor mm_colorWithHexString:@"#868686"]];
    clearImage = [clearImage resizeToSize:CGSizeMake(EZAudioButtonImageWidth_16, EZAudioButtonImageWidth_16)];
    clearButton.image = clearImage;
    
    NSString *clearAction = NSLocalizedString(@"clear_all", nil);
    NSString *clearShortcut = @"⌘+⇧+K";
    clearButton.toolTip = [NSString stringWithFormat:@"%@, %@", clearAction, clearShortcut];
    
    [clearButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"clearButton");
        mm_strongify(self);
        if (self.clearBlock) {
            self.clearBlock(self.copiedText);
        }
    }];
}

- (NSTextField *)alertTextField {
    if (!_alertTextField) {
        NSTextField *alertTextField = [[NSTextField alloc] init];
        alertTextField.hidden = YES;
        alertTextField.bordered = NO;
        alertTextField.editable = NO;
        alertTextField.enabled = NO;
        // ???: Why does this not work?
    //    alertTextField.refusesFirstResponder = YES;
        alertTextField.backgroundColor = NSColor.clearColor;
        alertTextField.font = self.textView.font;
        [self addSubview:alertTextField];
        _alertTextField = alertTextField;
        [alertTextField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.inset(10);
        }];
    }
    return _alertTextField;
}

#pragma mark - Public Methods

- (CGFloat)heightOfQueryView {
    return [self heightOfTextView] + EZQueryViewExceptInputViewHeight;
}

- (void)setClearButtonHidden:(BOOL)hidden {
    _clearButtonHidden = hidden;
    
    [self.clearButton setAnimatedHidden:hidden];
}

- (void)initializeAimatedButtonAlphaValue:(EZQueryModel *)queryModel {
    // !!!: Cannot setHidden to YES, otherwise button won't accept animation.
    
    self.clearButton.alphaValue = queryModel.inputText.length ? 1.0 : 0;
    self.detectButton.alphaValue = [queryModel.detectedLanguage isEqualToString:EZLanguageAuto] ? 0 : 1.0;
}

- (void)startLoadingAnimation:(BOOL)isLoading {
    if (isLoading) {
        // Avoid to show placeholder.
        self.textView.string = @" ";
    }
    [self setAlertTextHidden:YES];
    self.textView.editable = !isLoading;
    [self.loadingAnimationView startLoading:isLoading];
}

- (void)setAlertTextHidden:(BOOL)hidden {
    if (hidden) {
        self.alertText = @"";
        
    }
    self.alertTextField.hidden = hidden;
    self.textView.editable = hidden;
    self.detectButton.showAutoLanguage = NO;
    [self updateDetectButton];
}

#pragma mark - Rewrite

- (void)viewDidMoveToWindow {
    [self scrollToTextViewBottom];
    
    [super viewDidMoveToWindow];
}

- (void)updateConstraints {
    [self updateCustomLayout];
    
    [self.audioButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-EZAudioButtonBottomMargin_4);
        make.left.offset(EZAudioButtonLeftMargin_6);
        make.width.height.mas_equalTo(EZAudioButtonWidthHeight_24);
    }];
    
    [self.textCopyButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.audioButton.mas_right).offset(EZAudioButtonRightPadding_1);
        make.width.height.bottom.equalTo(self.audioButton);
    }];
    
    [self updateDetectButton];
    
    
    [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.inset(0);
        // Add a padding to audio button, avoid making users feel that there is still text below that has not been fully displayed.
        make.bottom.equalTo(self.audioButton.mas_top).offset(-EZAudioButtonInputViewTopPadding_4);
        
        CGFloat textViewHeight = [self heightOfTextView];
        make.height.mas_greaterThanOrEqualTo(textViewHeight);
    }];
    
    [self.clearButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(self).offset(-4);
        make.width.height.mas_equalTo(24);
    }];
    
    [super updateConstraints];
}

#pragma mark - Setter

- (void)setQueryModel:(EZQueryModel *)model {
    NSString *queryText = model.inputText;
    _queryModel = model;
    
    // !!!: Set queryModel may trigger didChangeText.
    
    // Avoid unnecessary calls to NSTextStorageDelegate methods.
    // !!!: do not update textView while user is typing (like Chinese input)
    if (queryText && ![queryText isEqualToString:self.textView.string] && !self.isTypingChinese) {
//        // !!!: Be careful, set `self.textView.string` will call -heightOfTextView to update textView height.
//        self.textView.string = queryText; // ???: need to check
//
//        // !!!: We need to trigger `-textDidChange:` manually, since it can be only invoked by user input automatically.
//        [self.textView didChangeText];
        
        [self updateQueryText:queryText];
        
        [self setAlertTextHidden:YES];
    }
    
    [self updateButtonsDisplayState:queryText];
}

- (void)setWindowType:(EZWindowType)windowType {
    [super setWindowType:windowType];
    
    if (windowType == EZWindowTypeMini) {
        self.textView.customParagraphSpacing = FLT_MIN; // minimum positive float value.
    }
    
    [self updateCustomLayout];
}

- (void)setPlaceholderText:(NSString *)placeholderText {
    _placeholderText = placeholderText;
    
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: NSColor.placeholderTextColor,
        NSFontAttributeName: self.textView.font,
    };
    
    // Ref: https://stackoverflow.com/questions/29428594/set-the-placeholder-string-for-nstextview
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:placeholderText attributes:attributes];
//    self.textView.placeholderAttributedString = attributedString;
    
    @try {
        [self.textView setValue:attributedString forKey:@"placeholderAttributedString"];
    }
    @catch (NSException *exception) {
        NSLog(@"setValue:forUndefinedKey: exception: %@", exception);
    }
}

- (void)setAlertText:(NSString *)alertText {
    _alertText = alertText;
    
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: NSColor.redColor,
        NSFontAttributeName: self.textView.font,
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:alertText attributes:attributes];
    self.alertTextField.attributedStringValue = attributedString;

    if (alertText.length) {
        // Avoid to show placeholder text when alert text is not empty.
        self.textView.string = @" ";
        [self setAlertTextHidden:NO];
        [self.clearButton setAnimatedHidden:NO];
        
        self.detectButton.showAutoLanguage = YES;
        [self updateDetectButton];
    }
}


#pragma mark - Getter

- (NSString *)copiedText {
    return [self.textView.string copy];
}

- (EZSchemeParser *)schemeParser {
    if (!_schemeParser) {
        _schemeParser = [[EZSchemeParser alloc] init];
    }
    return _schemeParser;
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    NSEvent *currentEvent = NSApplication.sharedApplication.currentEvent;
    NSEventModifierFlags flags = currentEvent.modifierFlags;
//    NSInteger keyCode = currentEvent.keyCode;
//    EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
    
    if (commandSelector == @selector(insertNewline:)) {
        // Shift + Enter
        if (flags & NSEventModifierFlagShift) {
            return NO;
        } else {
            if (self.enterActionBlock) {
                NSLog(@"enterActionBlock");
                self.enterActionBlock(self.copiedText);
            }
            return YES;
        }
    }
    
    // Escape key
    if (commandSelector == @selector(cancelOperation:)) {
        //        NSLog(@"escape: %@", textView);
        [[EZWindowManager shared] closeWindowOrExitSreenshot];
        
        return YES;
    }
    
    // No operation
    
    // Moved to EZStatusItem: googleItem, eudicItem
//    if (commandSelector == NSSelectorFromString(@"noop:")) {
//        // Cmd
//        if (flags & NSEventModifierFlagCommand) {
//            // Enter
//            if (keyCode == kVK_Return) {
//                // Cmd + Shift + Enter
//                if (flags & NSEventModifierFlagShift) {
//                    [window.titleBar.eudicButton openLink];
//                    return YES;
//                } else {
//                    // Cmd + Enter
//                    [window.titleBar.googleButton openLink];
//                    return YES;
//                }
//            }
//        }
//    }
    
    return NO;
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
    BOOL hasMarkedText = [textView hasMarkedText];
    BOOL isInputting = hasMarkedText && textView.markedRange.length == 0;
    if (!hasMarkedText || isInputting) {
        self.lastRecordText = [self copiedText];
        [self tryRecordUndoText];
    }
    
    // !!!: Be careful, when user finish inputting Chinese, hasMarkedText still returns YES, so we need to set isTypingChinese to NO in `textDidChange:` method.
    self.isTypingChinese = hasMarkedText;
    //    if (self.isTypingChinese) {
    //        NSLog(@"---> isTypingChinese");
    //        NSLog(@"text: %@", textView.string);
    //        NSLog(@"shouldChangeTextInRange: %@, %@", NSStringFromRange(affectedCharRange), replacementString);
    //        NSLog(@"hasMarkedText: %d, markedRange: %@", [textView hasMarkedText], NSStringFromRange(textView.markedRange));
    //    }
    
    return YES;
}

- (void)textStorage:(NSTextStorage *)textStorage willProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta {
    //        NSLog(@"willProcessEditing: %@", [self copiedText]);
}

/// !!!: set self.textView.string will invoke this method.
- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta {
    //    NSLog(@"didProcessEditing: %@", [self copiedText]);
    
    // Handle the special case of inputting text, such as when inputting Chinese, the candidate word is being selected, at this time the textView cannot be updated, otherwise the candidate word will be cleared.
}


#pragma mark - NSTextDelegate

// !!!: This delegate can be only invoked by user input automatically, Or call didChangeText manually.
- (void)textDidChange:(NSNotification *)notification {
//    NSString *text = [self copiedText];
//    NSLog(@"textDidChange: %@", text);
    
    self.queryModel.actionType = EZActionTypeInputQuery;
    self.queryModel.needDetectLanguage = YES;
    
    // textView.string has been changed, we don't need to update it again.
    [self updateQueryText:nil];
}


#pragma mark - Other

/// Must call this method when updating query text, whether user input or program update.
- (void)updateQueryText:(nullable NSString *)text {
    // !!!: set string will change selectedRange, means it will change cursor position.
    if (text) {
        self.textView.string = text;
    } else {
        text = [self copiedText];
    }
    
    // Set `self.isTypingChinese` to NO when textView string is changed.
    self.isTypingChinese = NO;
    
    [self updateButtonsDisplayState:text];
    
    if (self.updateQueryTextBlock) {
        CGFloat textViewHeight = [self heightOfTextView];
        self.updateQueryTextBlock(text, textViewHeight + EZQueryViewExceptInputViewHeight);
    }
}

- (CGFloat)heightOfTextView {
    CGFloat height = [self.textView ez_getTextViewHeightDesignatedWidth:self.width];
    //    NSLog(@"text: %@, height: %@", self.textView.string, @(height));
    
    height = MAX(height, self.textViewMinHeight);
    height = MIN(height, self.textViewMaxHeight);
    
    height = ceil(height);
    //    NSLog(@"final height: %.1f", height);
    
    return height;
}

- (void)updateCustomLayout {
    EZWindowType windowType = self.windowType;
    
    self.textViewMinHeight = [EZLayoutManager.shared inputViewMinHeight:windowType];
    self.textViewMaxHeight = [EZLayoutManager.shared inputViewMaxHeight:windowType];
}

- (void)updateButtonsDisplayState:(NSString *)text {    
    if (self.clearButtonHidden && self.alertText.length) {
        [self.clearButton setAnimatedHidden:NO];
    }
    
    [self updateDetectButton];
}

- (void)updatePlaceholderTextField {
    BOOL hidden = YES;
    if (self.alertText.length) {
        hidden = NO;
    }
    
    if (self.textView.string.length == 0) {
        if (self.placeholderText.length) {
            hidden = NO;
            [self setPlaceholderText:self.placeholderText];
        }
    }
    
    self.alertTextField.hidden = hidden;
}

- (void)updateDetectButton {
    // If user has designated source language, there is no meaning to detect language.
    self.detectButton.enabled = !self.queryModel.hasUserSourceLanguage;
    
    self.detectButton.showAutoLanguage = self.queryModel.showAutoLanguage;
    self.detectButton.detectedLanguage = self.queryModel.detectedLanguage;
    
    CGFloat height = 20;
    self.detectButton.cornerRadius = height / 2;
    [self.detectButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textCopyButton.mas_right).offset(6.5);
        make.centerY.equalTo(self.textCopyButton).offset(-0.5);
        make.height.mas_equalTo(height);
    }];
}

/// Focus on textView, and scroll to text view bottom.
- (void)scrollToTextViewBottom {
    // recover input cursor
    [self.window makeFirstResponder:self.textView];
    
    // scroll to input view bottom
    NSScrollView *scrollView = self.scrollView;
    CGFloat height = scrollView.documentView.frame.size.height - scrollView.contentSize.height;
    [scrollView.contentView scrollToPoint:NSMakePoint(0, height)];
}

/// Highlight all links in textstorage
- (void)highlightAllLinks {
    BOOL isEasydictSchema = [self.schemeParser isEasydictScheme:self.textView.string];
    if (isEasydictSchema) {
        return;
    }
    
    NSTextStorage *textStorage = self.textView.textStorage;
    [self removeAllLinks];
    
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    [detector enumerateMatchesInString:textStorage.string
                               options:0
                                 range:NSMakeRange(0, textStorage.length)
                            usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [textStorage addAttributes:@{ NSLinkAttributeName : result.URL }
                             range:result.range];
    }];
}

/// Remove all links in textstorage.
- (void)removeAllLinks {
    NSTextStorage *textStorage = self.textView.textStorage;
    [textStorage beginEditing];
    [textStorage removeAttribute:NSLinkAttributeName range:NSMakeRange(0, textStorage.length)];
    [textStorage endEditing];
}

- (void)scrollToEndOfTextView {
    [self.textView scrollToEndOfDocument:nil];
}

#pragma mark - Undo

- (void)tryRecordUndoText {
    if ([self isTimePassed:EZDelayDetectTextLanguageInterval]) {
        //        NSLog(@"recordText: %@", [self copiedText]);
        //        NSLog(@"lastRecordText: %@", self.lastRecordText);
        
        // !!!: Shouldn't use [self.textView.string copy], since it may be character when inputting Chinese.
        [self.undoManager registerUndoWithTarget:self.textView selector:@selector(setString:) object:self.lastRecordText];
        self.lastRecordTimestamp = [NSDate date].timeIntervalSince1970;
    }
}

/// Check if time has passed > 2 seconds compared to parameter time
- (BOOL)isTimePassed:(NSTimeInterval)timeInterval {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    return currentTime - self.lastRecordTimestamp > timeInterval;
}

@end
