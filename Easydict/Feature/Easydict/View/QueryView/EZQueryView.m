//
//  EDQueryView.m
//  Bob
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZQueryView.h"
#import "NSTextView+Height.h"
#import "EZWindowManager.h"
#import "NSView+EZGetViewController.h"
#import "NSImage+EZResize.h"
#import "EZDetectLanguageButton.h"
#include <Carbon/Carbon.h>
#import "NSView+EZHiddenWithAnimation.h"

static CGFloat kExceptTextViewHeight = 30;

@interface EZQueryView () <NSTextViewDelegate, NSTextStorageDelegate>

@property (nonatomic, strong) EZDetectLanguageButton *detectButton;
@property (nonatomic, strong) EZHoverButton *clearButton;

@property (nonatomic, assign) CGFloat textViewMiniHeight;
@property (nonatomic, assign) CGFloat textViewMaxHeight;

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
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
    self.scrollView = scrollView;
    [self addSubview:scrollView];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    scrollView.autohidesScrollers = YES;
    
    EZTextView *textView = [[EZTextView alloc] initWithFrame:scrollView.bounds];
    self.textView = textView;
    self.scrollView.documentView = textView;
    [textView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    textView.delegate = self;
    textView.textStorage.delegate = self;
    
    EZDetectLanguageButton *detectButton = [[EZDetectLanguageButton alloc] initWithFrame:self.bounds];
    [self addSubview:detectButton];
    self.detectButton = detectButton;
    
    mm_weakify(self);
    [detectButton setMenuItemSeletedBlock:^(EZLanguage language) {
        mm_strongify(self);
        if (self.selectedLanguageBlock) {
            self.selectedLanguageBlock(language);
        }
    }];
    
    detectButton.mas_key = @"detectButton";
    
    EZHoverButton *clearButton = [[EZHoverButton alloc] init];
    [self addSubview:clearButton];
    self.clearButton = clearButton;
    
    // !!!: Cannot setHidden to YES, otherwise button won't accept animation.
    clearButton.alphaValue = 0;
    
    NSImage *clearImage = [NSImage imageWithSystemSymbolName:@"xmark.circle.fill" accessibilityDescription:nil];
    clearImage = [clearImage imageWithTintColor:[NSColor mm_colorWithHexString:@"#707070"]];
    clearImage = [clearImage resizeToSize:CGSizeMake(EZAudioButtonImageWidth_15, EZAudioButtonImageWidth_15)];
    clearButton.image = clearImage;
    clearButton.toolTip = @"Clear All";
    
    [clearButton setClickBlock:^(EZButton * _Nonnull button) {
        NSLog(@"clearButton");
        mm_strongify(self);
        if (self.clearBlock) {
            self.clearBlock(self.copiedText);
        }
    }];
}

#pragma mark - Public

- (CGFloat)heightOfQueryView {
    return [self heightOfTextView] + kExceptTextViewHeight;
}

- (void)setClearButtonAnimatedHidden:(BOOL)hidden {
    [self.clearButton setAnimatedHidden:hidden];
}

#pragma mark - Super method

- (void)viewDidMoveToWindow {
    [self scrollToTextViewBottom];
    
    [super viewDidMoveToWindow];
}

- (void)updateConstraints {
    [self updateCustomLayout];
    [self updateDetectButton];
    
    [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.inset(0);
        make.bottom.equalTo(self.audioButton.mas_top).offset(0);
        make.height.mas_greaterThanOrEqualTo(self.textViewMiniHeight).priorityLow();
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
    if (queryText && ![queryText isEqualToString:self.copiedText]) {
        // !!!: Be careful, set `self.textView.string` will call -heightOfTextView to update textView height.
        self.textView.string = model.queryText;
    }
    
    [self updateButtonsDisplayState:queryText];
}

- (void)setQueryText:(NSString *)queryText {
    if (queryText) {
        self.textView.string = queryText;
    }
}

- (void)setWindowType:(EZWindowType)windowType {
    [super setWindowType:windowType];
    
    [self updateCustomLayout];
}


#pragma mark - Getter

- (NSString *)copiedText {
    return self.textView.string;
}


#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    NSEvent *currentEvent = NSApplication.sharedApplication.currentEvent;
    NSEventModifierFlags flags = currentEvent.modifierFlags;
    NSInteger keyCode = currentEvent.keyCode;
    
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
        [[EZWindowManager shared] closeFloatingWindow];
        
        return YES;
    }
    
    // No operation
    if (commandSelector == NSSelectorFromString(@"noop:")) {
        // Cmd + Enter
        if (flags & NSEventModifierFlagCommand && keyCode == kVK_Return) {
            NSLog(@"Cmd + Enter");
            
            EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
            [window.titleBar.favoriteButton openLink];
            
            return YES;
        }
    }
    
    return NO;
}


#pragma mark - NSTextStorageDelegate

- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta {
    NSString *text = textStorage.string;
    
    [self updateButtonsDisplayState:text];
    
    
    CGFloat textViewHeight = [self heightOfTextView];
    
    [self.scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(textViewHeight);
    }];
    
    // cannot layout this, otherwise will crash
    //    [self layoutSubtreeIfNeeded];
    //    NSLog(@"self.frame: %@", @(self.frame));
    
    if (self.updateQueryTextBlock) {
        self.updateQueryTextBlock(text, textViewHeight + kExceptTextViewHeight);
    }
}


#pragma mark - Other

- (CGFloat)heightOfTextView {
    CGFloat height = [self.textView getHeightWithWidth:self.width];
    //    NSLog(@"text: %@, height: %@", self.textView.string, @(height));
    
    height = MAX(height, self.textViewMiniHeight);
    height = MIN(height, self.textViewMaxHeight);
    
    height = ceil(height);
    //    NSLog(@"final height: %.1f", height);
    
    return height;
}

- (void)updateCustomLayout {
    EZWindowType windowType = self.windowType;
    
    self.textView.textContainerInset = [EZLayoutManager.shared textContainerInset:windowType];
    self.textViewMiniHeight = [EZLayoutManager.shared inputViewMiniHeight:windowType];
    self.textViewMaxHeight = [EZLayoutManager.shared inputViewMaxHeight:windowType];
}

- (void)updateButtonsDisplayState:(NSString *)text {
    BOOL isHidden = text.length == 0;
    [self setClearButtonAnimatedHidden:isHidden];
    
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

@end
