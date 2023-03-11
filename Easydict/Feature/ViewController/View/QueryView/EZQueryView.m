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

@interface EZQueryView () <NSTextViewDelegate, NSTextStorageDelegate>

@property (nonatomic, strong) NSButton *audioButton;
@property (nonatomic, strong) NSButton *textCopyButton;
@property (nonatomic, strong) EZDetectLanguageButton *detectButton;
@property (nonatomic, strong) EZHoverButton *clearButton;

@property (nonatomic, assign) CGFloat textViewMinHeight;
@property (nonatomic, assign) CGFloat textViewMaxHeight;

@property (nonatomic, copy) NSString *lastRecordText;
@property (nonatomic, assign) NSTimeInterval lastRecordTimestamp;

@property (nonatomic, assign) BOOL isTypingChinese;

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
        [x setBackgroundColor:NSColor.queryViewBgLightColor.CGColor];
    } drak:^(id _Nonnull x) {
        [x setBackgroundColor:NSColor.queryViewBgDarkColor.CGColor];
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
    
    mm_weakify(self);
    [textView setPasteTextBlock:^(NSString *_Nonnull text) {
        [self highlightAllLinks];
    }];
    
    EZLoadingAnimationView *loadingAnimationView = [[EZLoadingAnimationView alloc] init];
    [self addSubview:loadingAnimationView];
    self.loadingAnimationView = loadingAnimationView;
    
    [self.loadingAnimationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(textView).offset(5);
        make.left.equalTo(textView).offset(10);
        make.height.mas_equalTo(30);
    }];
    
    NSTextField *alertTextField = [[NSTextField alloc] init];
    alertTextField.hidden = YES;
    alertTextField.bordered = NO;
    alertTextField.editable = NO;
    alertTextField.backgroundColor = NSColor.clearColor;
    alertTextField.font = [NSFont systemFontOfSize:14];
    alertTextField.textColor = [NSColor redColor];
    [self addSubview:alertTextField];
    self.alertTextField = alertTextField;
    [alertTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.inset(10);
    }];
    
    EZHoverButton *audioButton = [[EZHoverButton alloc] init];
    [self addSubview:audioButton];
    self.audioButton = audioButton;
    audioButton.image = [NSImage imageNamed:@"audio"];
    audioButton.toolTip = @"Play";
    
    [audioButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"audioActionBlock");
        mm_strongify(self);
        if (self.playAudioBlock) {
            self.playAudioBlock(self.copiedText);
        }
    }];
    audioButton.mas_key = @"audioButton";
    
    EZHoverButton *textCopyButton = [[EZHoverButton alloc] init];
    [self addSubview:textCopyButton];
    self.textCopyButton = textCopyButton;
    
    textCopyButton.image = [NSImage imageNamed:@"copy"];
    textCopyButton.toolTip = @"Copy";
    
    [textCopyButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"copyActionBlock");
        mm_strongify(self);
        if (self.copyTextBlock) {
            self.copyTextBlock(self.copiedText);
        }
    }];
    textCopyButton.mas_key = @"copyButton";
    
    
    EZDetectLanguageButton *detectButton = [[EZDetectLanguageButton alloc] initWithFrame:self.bounds];
    [self addSubview:detectButton];
    self.detectButton = detectButton;
    
    [detectButton setMenuItemSeletedBlock:^(EZLanguage language) {
        mm_strongify(self);
        self.enableAutoDetect = NO;
        if (self.selectedLanguageBlock) {
            self.selectedLanguageBlock(language);
        }
    }];
    
    detectButton.mas_key = @"detectButton";
    
    EZHoverButton *clearButton = [[EZHoverButton alloc] init];
    [self addSubview:clearButton];
    self.clearButton = clearButton;
    
    NSImage *clearImage = [NSImage imageWithSystemSymbolName:@"xmark.circle.fill" accessibilityDescription:nil];
    clearImage = [clearImage imageWithTintColor:[NSColor mm_colorWithHexString:@"#707070"]];
    clearImage = [clearImage resizeToSize:CGSizeMake(EZAudioButtonImageWidth_15, EZAudioButtonImageWidth_15)];
    clearButton.image = clearImage;
    clearButton.toolTip = @"Clear";
    
    [clearButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"clearButton");
        mm_strongify(self);
        [self setAlertMessageHidden:YES];
        if (self.clearBlock) {
            self.clearBlock(self.copiedText);
        }
    }];
}

#pragma mark - Public Methods

- (CGFloat)heightOfQueryView {
    return [self heightOfTextView] + EZExceptInputViewHeight;
}

- (void)setClearButtonHidden:(BOOL)hidden {
    _clearButtonHidden = hidden;
    
    [self.clearButton setAnimatedHidden:hidden];
}

- (void)initializeAimatedButtonAlphaValue:(EZQueryModel *)queryModel {
    // !!!: Cannot setHidden to YES, otherwise button won't accept animation.
    
    self.clearButton.alphaValue = queryModel.queryText.length ? 1.0 : 0;
    self.detectButton.alphaValue = [queryModel.detectedLanguage isEqualToString:EZLanguageAuto] ? 0 : 1.0;
}

- (void)startLoadingAnimation:(BOOL)isLoading {
    if (isLoading) {
        self.textView.string = @"";
    }
    [self setAlertMessageHidden:YES];
    self.textView.editable = !isLoading;
    [self.loadingAnimationView startLoading:isLoading];
}

- (void)showAlertMessage:(NSString *)message {
    if (message.length) {
        [self setAlertMessageHidden:NO];
        self.alertTextField.stringValue = message;
        [self.clearButton setAnimatedHidden:NO];
        
        self.detectButton.showAutoLanguage = YES;
        [self updateDetectButton];
    }
}

- (void)setAlertMessageHidden:(BOOL)hidden {
    self.alertTextField.hidden = hidden;
    self.textView.editable = hidden;
    self.detectButton.showAutoLanguage = NO;
    [self updateDetectButton];
}

- (void)showAutoDetectLanguage:(BOOL)showFlag {
    self.detectButton.showAutoLanguage = self.queryModel.queryText.length;
}

#pragma mark - Rewrite

- (void)viewDidMoveToWindow {
    // Since we have reused queryView, we don't need to scroll to bottom when updating view.
    //    [self scrollToTextViewBottom];
    
    [super viewDidMoveToWindow];
}

- (void)updateConstraints {
    [self updateCustomLayout];
    
    [self.audioButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-5);
        make.left.offset(8);
        make.width.height.mas_equalTo(EZAudioButtonWidth_25);
    }];
    
    [self.textCopyButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.audioButton.mas_right).offset(1);
        make.width.height.bottom.equalTo(self.audioButton);
    }];
    
    [self updateDetectButton];
    
    
    [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.inset(0);
        make.bottom.equalTo(self.audioButton.mas_top).offset(0);
        
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
    _queryModel = model;
    
    NSString *queryText = model.queryText;
    
    // Avoid unnecessary calls to NSTextStorageDelegate methods.
    // !!!: do not update textView while user is typing (like Chinese input)
    if (queryText && ![queryText isEqualToString:self.copiedText] && !self.isTypingChinese) {
        // !!!: Be careful, set `self.textView.string` will call -heightOfTextView to update textView height.
        self.textView.string = queryText; // ???: need to check
        
        // !!!: We need to trigger `-textDidChange:` manually, since it can be only invoked by user input automatically.
        [self.textView didChangeText];
        
        [self setAlertMessageHidden:YES];
    }
    
    [self updateButtonsDisplayState:queryText];
}

- (void)setWindowType:(EZWindowType)windowType {
    [super setWindowType:windowType];
    
    [self updateCustomLayout];
}


#pragma mark - Getter

- (NSString *)copiedText {
    return [self.textView.string copy];
}


#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    NSEvent *currentEvent = NSApplication.sharedApplication.currentEvent;
    NSEventModifierFlags flags = currentEvent.modifierFlags;
    NSInteger keyCode = currentEvent.keyCode;
    EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
    
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
    
    if (commandSelector == @selector(insertNewlineIgnoringFieldEditor:)) {
        // Option + Enter
        if (flags & NSEventModifierFlagOption) {
            [window.titleBar.eudicButton openLink];
            return YES;
        }
    }
    
    // Escape key
    if (commandSelector == @selector(cancelOperation:)) {
        //        NSLog(@"escape: %@", textView);
        [[EZWindowManager shared] closeFloatingWindow];
        
        return YES;
    }
    
    // No operation
    if (commandSelector == NSSelectorFromString(@"noop:")) {
        // Cmd + Enter
        if (flags & NSEventModifierFlagCommand && keyCode == kVK_Return) {
            [window.titleBar.googleButton openLink];
            return YES;
        }
    }
    
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

- (void)textDidChange:(NSNotification *)notification {
    NSString *text = [self copiedText];
    //    NSLog(@"textDidChange: %@", text);
    
    // Set `self.isTypingChinese` to NO when textView string is changed.
    self.isTypingChinese = NO;
    
    self.enableAutoDetect = YES;
    [self updateButtonsDisplayState:text];
    
    // cannot layout this, otherwise will crash
    //    [self layoutSubtreeIfNeeded];
    //    NSLog(@"self.frame: %@", @(self.frame));
    
    
    if (self.updateQueryTextBlock) {
        CGFloat textViewHeight = [self heightOfTextView];
        self.updateQueryTextBlock(text, textViewHeight + EZExceptInputViewHeight);
    }
}


#pragma mark - Other

- (CGFloat)heightOfTextView {
    CGFloat height = [self.textView getHeightWithWidth:self.width];
    //    NSLog(@"text: %@, height: %@", self.textView.string, @(height));
    
    height = MAX(height, self.textViewMinHeight);
    height = MIN(height, self.textViewMaxHeight);
    
    height = ceil(height);
    //    NSLog(@"final height: %.1f", height);
    
    return height;
}

- (void)updateCustomLayout {
    EZWindowType windowType = self.windowType;
    
    self.textView.textContainerInset = [EZLayoutManager.shared textContainerInset:windowType];
    self.textViewMinHeight = [EZLayoutManager.shared inputViewMinHeight:windowType];
    self.textViewMaxHeight = [EZLayoutManager.shared inputViewMaxHeight:windowType];
}

- (void)updateButtonsDisplayState:(NSString *)text {
    BOOL isEmpty = text.length == 0;
    if (!self.alertTextField.hidden) {
        isEmpty = NO;
    }
    
    if (self.clearButtonHidden) {
        [self.clearButton setAnimatedHidden:isEmpty];
    }
    
    [self updateDetectButton];
}

- (void)updateDetectButton {
    self.detectButton.detectedLanguage = self.queryModel.detectedLanguage;
    
    CGFloat height = 20;
    self.detectButton.cornerRadius = height / 2;
    [self.detectButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textCopyButton.mas_right).offset(6);
        make.centerY.equalTo(self.textCopyButton);
        make.height.mas_equalTo(height);
    }];
}

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
    NSTextStorage *textStorage = self.textView.textStorage;
    [textStorage beginEditing];
    [textStorage removeAttribute:NSLinkAttributeName range:NSMakeRange(0, textStorage.length)];
    [textStorage endEditing];
    
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    [detector enumerateMatchesInString:textStorage.string
                               options:0
                                 range:NSMakeRange(0, textStorage.length)
                            usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [textStorage addAttributes:@{NSLinkAttributeName : result.URL}
                             range:result.range];
    }];
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
