//
//  EDQueryView.m
//  Bob
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZQueryView.h"
#import "EZButton.h"
#import "NSTextView+Height.h"
#import "EZWindowManager.h"
#import "NSView+EZGetViewController.h"
#import "NSImage+EZResize.h"

static CGFloat kExceptTextViewHeight = 30;

@interface EZQueryView () <NSTextViewDelegate, NSTextStorageDelegate>

@property (nonatomic, strong) EZButton *detectButton;
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

    EZButton *detectButton = [[EZButton alloc] init];
    [self addSubview:detectButton];
    self.detectButton = detectButton;
    detectButton.hidden = YES;
    detectButton.cornerRadius = 10;
    detectButton.title = @"";

    [detectButton excuteLight:^(EZButton *detectButton) {
        detectButton.backgroundColor = [NSColor mm_colorWithHexString:@"#EAEAEA"];
        detectButton.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#E0E0E0"];
        detectButton.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#D1D1D1"];
    } drak:^(EZButton *button) {
        detectButton.backgroundColor = [NSColor mm_colorWithHexString:@"#313233"];
        detectButton.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#424445"];
        detectButton.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#535556"];
    }];

    mm_weakify(self);
    [detectButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"detectButton");

        mm_strongify(self);
        if (self.detectActionBlock) {
            self.detectActionBlock(button);
        }
    }];

    detectButton.mas_key = @"detectButton";
    
    EZHoverButton *clearButton = [[EZHoverButton alloc] init];
    [self addSubview:clearButton];
    self.clearButton = clearButton;
    clearButton.hidden = NO;
    clearButton.image = [[NSImage imageNamed:@"clear_circle"] resizeToSize:CGSizeMake(15, 15)];
    clearButton.toolTip = @"Clear";
    
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
        make.right.equalTo(self).offset(-5);
        make.centerY.equalTo(self.textCopyButton);
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
    if (commandSelector == @selector(insertNewline:)) {
        NSEventModifierFlags flags = NSApplication.sharedApplication.currentEvent.modifierFlags;
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
    
    // escape key
    if (commandSelector == @selector(cancelOperation:)) {
//        NSLog(@"escape: %@", textView);
        [[EZWindowManager shared] closeFloatingWindow];
        
        return NO;
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
    
    self.clearButton.hidden = isHidden;
    if (isHidden) {
        self.detectButton.hidden = YES;
    }
    
    [self updateDetectButton];
}

- (void)updateDetectButton {
    Language fromLanguage = self.queryModel.sourceLanguage;
    if (fromLanguage == Language_auto || self.queryModel.queryText.length == 0) {
        self.detectButton.hidden = YES;
        return;
    }
    
    self.detectButton.hidden = NO;
    
    NSString *detectLanguageTitle =  LanguageDescFromEnum(fromLanguage);
    
    NSString *title = @"识别为 ";
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [attrTitle addAttributes:@{
        NSForegroundColorAttributeName : NSColor.grayColor,
        NSFontAttributeName : [NSFont systemFontOfSize:10],
    }
                       range:NSMakeRange(0, attrTitle.length)];


    NSMutableAttributedString *detectAttrTitle = [[NSMutableAttributedString alloc] initWithString:detectLanguageTitle];
    [detectAttrTitle addAttributes:@{
        NSForegroundColorAttributeName : [NSColor mm_colorWithHexString:@"#007AFF"],
        NSFontAttributeName : [NSFont systemFontOfSize:10],
    }
                             range:NSMakeRange(0, detectAttrTitle.length)];

    [attrTitle appendAttributedString:detectAttrTitle];

    CGFloat width = [attrTitle mm_getTextWidth];
    self.detectButton.attributedTitle = attrTitle;
    [self.detectButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textCopyButton.mas_right).offset(6);
        make.centerY.equalTo(self.textCopyButton);
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(width + 8);
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
