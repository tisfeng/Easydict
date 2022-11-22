//
//  EZResultView.m
//  Bob
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZResultView.h"
#import "EZServiceTypes.h"
#import "EZHoverButton.h"
#import "EZWordResultView.h"
#import "EZConst.h"

@interface EZResultView ()

@property (nonatomic, strong) NSView *topBarView;
@property (nonatomic, strong) NSImageView *typeImageView;
@property (nonatomic, strong) NSTextField *typeLabel;
@property (nonatomic, strong) NSImageView *disableImageView;

@property (nonatomic, strong) NSButton *arrowButton;

@property (nonatomic, strong) EZWordResultView *wordResultView;

@end


@implementation EZResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.wantsLayer = YES;
    self.layer.cornerRadius = EZCornerRadius_8;
    
    [self.layer excuteLight:^(CALayer *layer) {
        layer.backgroundColor = NSColor.resultViewBgLightColor.CGColor;
    } drak:^(CALayer *layer) {
        layer.backgroundColor = NSColor.resultViewBgDarkColor.CGColor;
    }];
    
    self.topBarView = [NSView mm_make:^(NSView *_Nonnull view) {
        [self addSubview:view];
        view.wantsLayer = YES;
        [view.layer excuteLight:^(CALayer *layer) {
            layer.backgroundColor = NSColor.topBarBgLightColor.CGColor;
        } drak:^(CALayer *layer) {
            layer.backgroundColor = NSColor.topBarBgDarkColor.CGColor;
        }];
    }];
    self.topBarView.mas_key = @"topBarView";
    
    self.typeImageView = [NSImageView mm_make:^(NSImageView *imageView) {
        [self addSubview:imageView];
        [imageView setImage:[NSImage imageNamed:@"Apple Translate"]];
    }];
    self.typeImageView.mas_key = @"typeImageView";
    
    self.typeLabel = [NSTextField mm_make:^(NSTextField *label) {
        [self addSubview:label];
        label.editable = NO;
        label.bordered = NO;
        label.backgroundColor = NSColor.clearColor;
        label.alignment = NSTextAlignmentCenter;
        NSString *title = @"系统翻译";
        label.attributedStringValue = [[NSAttributedString alloc] initWithString:title];
        
        [label excuteLight:^(NSTextField *label) {
            label.textColor = NSColor.resultTextLightColor;
        } drak:^(NSTextField *label) {
            label.textColor = NSColor.resultTextDarkColor;
        }];
    }];
    self.typeLabel.mas_key = @"typeLabel";
    
    self.disableImageView = [NSImageView mm_make:^(NSImageView *imageView) {
        [self addSubview:imageView];
        NSImage *image = [NSImage imageNamed:@"disabled"];
        [imageView setImage:image];
    }];
    self.disableImageView.mas_key = @"disableImageView";
    
    
    EZWordResultView *wordResultView = [[EZWordResultView alloc] initWithFrame:self.bounds];
    [self addSubview:wordResultView];
    self.wordResultView = wordResultView;
    
    mm_weakify(self);
    [wordResultView setPlayAudioBlock:^(EZWordResultView *_Nonnull view, NSString *_Nonnull word) {
        mm_strongify(self);
        if (self.playAudioBlock) {
            self.playAudioBlock(word);
        }
    }];
    
    [wordResultView setCopyTextBlock:^(EZWordResultView *_Nonnull view, NSString *_Nonnull word) {
        if (self.copyTextBlock) {
            self.copyTextBlock(word);
        }
    }];
    
    EZHoverButton *arrowButton = [[EZHoverButton alloc] init];
    self.arrowButton = arrowButton;
    [self addSubview:arrowButton];
    NSImage *image = [NSImage imageNamed:@"arrow-down"];
    arrowButton.image = image;
    self.arrowButton.mas_key = @"arrowButton";
    
    [arrowButton setClickBlock:^(EZButton *_Nonnull button) {
        mm_strongify(self);
        
        BOOL oldIsShowing = self.result.isShowing;
        BOOL newIsShowing = !oldIsShowing;
        self.result.isShowing = newIsShowing;
        NSLog(@"点击 arrowButton, show: %@", @(newIsShowing));
        
        [self setNeedsUpdateConstraints:YES];
        
        if (self.clickArrowBlock) {
            self.clickArrowBlock(newIsShowing);
        }
        
        //        [self rotateArrowButton];
    }];
}


- (void)rotateArrowButton {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = @(0);
    animation.toValue = [NSNumber numberWithFloat:-90 * (M_PI / 180.0f)];
    animation.cumulative = YES;
    animation.repeatCount = 1;
    animation.duration = 1;
    
    CGRect oldRect = self.arrowButton.layer.frame;
    self.arrowButton.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
    self.arrowButton.layer.frame = oldRect;
    
    [self.arrowButton.layer addAnimation:animation forKey:@"animation"];
}

- (void)updateConstraints {
    CGSize iconSize = CGSizeMake(18, 18);
    
    [self updateArrowButton];
    
    [self.topBarView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(kResultViewMiniHeight);
    }];
    
    [self.typeImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topBarView).offset(8);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(iconSize);
    }];
    
    [self.typeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.typeImageView.mas_right).offset(4);
        make.centerY.equalTo(self.topBarView).offset(0);
    }];
    
    [self.disableImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.typeLabel.mas_right).offset(5);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(iconSize);
    }];
    
    [self.arrowButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.topBarView.mas_right).offset(-5);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(CGSizeMake(22, 22));
    }];
    
    [self.wordResultView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBarView.mas_bottom);
        make.left.equalTo(self);
        make.bottom.right.lessThanOrEqualTo(self);
    }];
    
    [super updateConstraints];
}

- (NSString *)copiedText {
    NSString *text = [NSString mm_stringByCombineComponents:self.result.normalResults separatedString:@"\n"] ?: @"";
    return text;
}

- (void)refreshWithResult:(TranslateResult *)result {
    _result = result;
    
    EZServiceType serviceType = result.serviceType;
    NSString *imageName = [NSString stringWithFormat:@"%@ Translate", serviceType];
    self.typeImageView.image = [NSImage imageNamed:imageName];
    
    TranslateService *translate = [EZServiceTypes serviceWithType:serviceType];
    self.typeLabel.attributedStringValue = [NSAttributedString mm_attributedStringWithString:translate.name font:[NSFont systemFontOfSize:13]];
    
    [self updateArrowButton];
    
    [self.wordResultView refreshWithResult:result];
}

- (void)updateArrowButton {
    NSImage *arrowImage = [NSImage imageNamed:@"arrow-left"];
    if (self.result.isShowing) {
        arrowImage = [NSImage imageNamed:@"arrow-down"];
    }
    [self.arrowButton excuteLight:^(NSButton *button) {
        button.image = [arrowImage imageWithTintColor:NSColor.imageTintLightColor];
    } drak:^(NSButton *button) {
        button.image = [arrowImage imageWithTintColor:NSColor.imageTintDarkColor];
    }];
}

- (void)refreshWithStateString:(NSString *)string {
    [self refreshWithStateString:string actionTitle:nil action:nil];
}

- (void)refreshWithStateString:(NSString *)string actionTitle:(NSString *_Nullable)actionTitle action:(void (^_Nullable)(void))action {
}

@end
