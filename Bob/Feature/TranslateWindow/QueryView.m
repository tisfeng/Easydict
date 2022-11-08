//
//  QueryView.m
//  Bob
//
//  Created by ripper on 2019/11/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "QueryView.h"
#import "ImageButton.h"
#import "TextView.h"

#define kTextViewBottomInset 36.0


@interface QueryView () <NSTextViewDelegate>

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSButton *audioButton;
@property (nonatomic, strong) NSButton *textCopyButton;
@property (nonatomic, strong) NSButton *detectLanguageButton;

@end


@implementation QueryView

@synthesize queryText = _queryText;

DefineMethodMMMake_m(QueryView);

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (NSString *)queryText {
    return self.textView.string;
}

- (void)setQueryText:(NSString *)queryText {
    _queryText = queryText ?: @"";
    
    self.textView.string = _queryText;
}


- (void)setup {
    NSColor *blackColor = [NSColor blackColor];
    NSColor *whiteColor = [NSColor whiteColor];
    
    self.wantsLayer = YES;
    
    [self.layer excuteLight:^(id _Nonnull x) {
        [x setBackgroundColor:LightBgColor.CGColor];
    } drak:^(id _Nonnull x) {
        [x setBackgroundColor:DarkBgColor.CGColor];
    }];
    self.layer.cornerRadius = 8;
    
    self.scrollView = [NSScrollView mm_make:^(NSScrollView *_Nonnull scrollView) {
        [self addSubview:scrollView];
        scrollView.hasVerticalScroller = YES;
        scrollView.hasHorizontalScroller = NO;
        scrollView.autohidesScrollers = YES;
        self.textView = [[TextView alloc] initWithFrame:self.bounds];
        self.textView = [TextView mm_make:^(TextView *textView) {
            [textView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
            textView.delegate = self;
        }];
        scrollView.documentView = self.textView;
        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.inset(0);
            make.bottom.inset(kTextViewBottomInset);
        }];
    }];
    
    
    self.audioButton = [ImageButton mm_make:^(ImageButton *_Nonnull button) {
        [self addSubview:button];
        button.bordered = NO;
        button.wantsLayer = YES;
        button.layer.cornerRadius = 5;
        button.layer.masksToBounds = YES;
        button.imageScaling = NSImageScaleProportionallyDown;
        button.bezelStyle = NSBezelStyleRegularSquare;
        [button setButtonType:NSButtonTypeMomentaryChange];
        
        NSImage *image = [NSImage imageNamed:@"audio"];
        button.image = image;
        
        [button.layer excuteLight:^(id _Nonnull x) {
            if (@available(macOS 10.14, *)) {
                button.contentTintColor = blackColor;
            } else {
                button.image = [image imageWithTintColor:blackColor];
            }
        } drak:^(id _Nonnull x) {
            if (@available(macOS 10.14, *)) {
                button.contentTintColor = whiteColor;
            } else {
                button.image = [image imageWithTintColor:whiteColor];
            }
        }];
        
        button.toolTip = @"播放音频";
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(6);
            make.bottom.inset(6);
            make.width.height.mas_equalTo(23);
        }];
        mm_weakify(self)
        [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
            mm_strongify(self) if (self.audioActionBlock) {
                self.audioActionBlock(self);
            }
            return RACSignal.empty;
        }]];
    }];
    
    self.textCopyButton = [ImageButton mm_make:^(ImageButton *_Nonnull button) {
        [self addSubview:button];
        button.bordered = NO;
        button.wantsLayer = YES;
        button.layer.cornerRadius = 5;
        button.layer.masksToBounds = YES;
        
        NSImage *image = [NSImage imageNamed:@"copy"];
        button.image = image;
        
        [button excuteLight:^(NSButton *button) {
            if (@available(macOS 10.14, *)) {
                button.contentTintColor = blackColor;
            } else {
                button.image = [image imageWithTintColor:blackColor];
            }
        } drak:^(NSButton *button) {
            if (@available(macOS 10.14, *)) {
                button.contentTintColor = whiteColor;
            } else {
                button.image = [image imageWithTintColor:whiteColor];
            }
        }];
        
        button.imageScaling = NSImageScaleProportionallyDown;
        button.bezelStyle = NSBezelStyleRegularSquare;
        [button setButtonType:NSButtonTypeMomentaryChange];
        
        button.toolTip = @"复制";
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.audioButton.mas_right);
            make.bottom.equalTo(self.audioButton);
            make.width.height.equalTo(self.audioButton);
        }];
        mm_weakify(self)
        [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
            mm_strongify(self) if (self.copyActionBlock) {
                self.copyActionBlock(self);
            }
            return RACSignal.empty;
        }]];
    }];
    
    self.detectLanguageButton = [NSButton mm_make:^(NSButton *_Nonnull button) {
        [self addSubview:button];
        button.hidden = YES;
        button.bezelStyle = NSBezelStyleInline;
        [button setButtonType:NSButtonTypeMomentaryChange];
        
        button.toolTip = @"检测语言";
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.textCopyButton.mas_right).offset(5);
            make.centerY.equalTo(self.textCopyButton);
            make.height.equalTo(self.textCopyButton).offset(-5);
        }];
        
        [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
            NSLog(@"detectLanguageActionBlock");
            
            return RACSignal.empty;
        }]];
    }];
    
    
    // 将scrollview放到最上层
    [self addSubview:self.scrollView];
        
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSTrackingArea *copyTrackingArea = [[NSTrackingArea alloc]
                                            initWithRect:[self.textCopyButton bounds]
                                            options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                            owner:self
                                            userInfo:nil];
        [self.textCopyButton addTrackingArea:copyTrackingArea];
        
        NSTrackingArea *playTrackingArea = [[NSTrackingArea alloc]
                                            initWithRect:[self.audioButton bounds]
                                            options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                            owner:self
                                            userInfo:nil];
        [self.audioButton addTrackingArea:playTrackingArea];
    });
}

- (void)mouseEntered:(NSEvent *)theEvent {
    CGPoint point = theEvent.locationInWindow;
    point = [self convertPoint:point fromView:nil];
    
    [self excuteLight:^(id x) {
        NSColor *highlightBgColor = [NSColor mm_colorWithHexString:@"#E2E2E2"];
        [self hightlightCopyButtonBgColor:highlightBgColor point:point];
    } drak:^(id x) {
        [self hightlightCopyButtonBgColor:DarkBorderColor point:point];
    }];
}

- (void)hightlightCopyButtonBgColor:(NSColor *)color point:(CGPoint)point {
    if (CGRectContainsPoint(self.textCopyButton.frame, point)) {
        [[self.textCopyButton cell] setBackgroundColor:color];
    } else if (CGRectContainsPoint(self.audioButton.frame, point)) {
        [[self.audioButton cell] setBackgroundColor:color];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    [[self.textCopyButton cell] setBackgroundColor:NSColor.clearColor];
    [[self.audioButton cell] setBackgroundColor:NSColor.clearColor];
}

- (void)setDetectLanguage:(NSString *)detectLanguage {
    _detectLanguage = detectLanguage;
    
    NSString *title = @"识别为 ";
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [attrTitle addAttributes:@{
        NSForegroundColorAttributeName : NSColor.grayColor,
        NSFontAttributeName : [NSFont systemFontOfSize:10],
    }
                       range:NSMakeRange(0, attrTitle.length)];
    
    
    NSMutableAttributedString *detectAttrTitle = [[NSMutableAttributedString alloc] initWithString:detectLanguage];
    [detectAttrTitle addAttributes:@{
        NSForegroundColorAttributeName : [NSColor mm_colorWithHexString:@"#007AFF"],
        NSFontAttributeName : [NSFont systemFontOfSize:10],
    }
                             range:NSMakeRange(0, detectAttrTitle.length)];
    
    [attrTitle appendAttributedString:detectAttrTitle];
    
    CGFloat width = [attrTitle mm_getTextWidth];
    self.detectLanguageButton.hidden = NO;
    self.detectLanguageButton.attributedTitle = attrTitle;
    [self.detectLanguageButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width + 10);
    }];
    
//    [self setNeedsLayout:YES];
    [self layoutSubtreeIfNeeded];
}


#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)) {
        NSEventModifierFlags flags = NSApplication.sharedApplication.currentEvent.modifierFlags;
        if (flags & NSEventModifierFlagShift) {
            return NO;
        } else {
            if (self.enterActionBlock) {
                self.enterActionBlock(self);
            }
            return YES;
        }
    }
    return NO;
}

@end
