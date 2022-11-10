//
//  EZResultView.m
//  Bob
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZResultView.h"
#import "ServiceTypes.h"
#import "EZHoverButton.h"
#import "EZWordResultView.h"

static const CGFloat kResultViewMiniHeight = 25;

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
    self.topBarView = [NSView mm_make:^(NSView *_Nonnull view) {
        [self addSubview:view];
        view.wantsLayer = YES;
        view.layer.backgroundColor = DarkBarBgColor.CGColor;
        
        [view.layer excuteLight:^(CALayer *layer) {
            layer.backgroundColor = LightBarBgColor.CGColor;
        } drak:^(CALayer *layer) {
            layer.backgroundColor = DarkBarBgColor.CGColor;
        }];
        
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self);
            make.height.mas_equalTo(kResultViewMiniHeight);
        }];
    }];
    self.topBarView.mas_key = @"topBarView";
    
    CGSize iconSize = CGSizeMake(18, 18);
    
    self.typeImageView = [NSImageView mm_make:^(NSImageView *imageView) {
        [self addSubview:imageView];
        [imageView setImage:[NSImage imageNamed:@"Apple Translate"]];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topBarView).offset(10);
            make.centerY.equalTo(self.topBarView);
            make.size.mas_equalTo(iconSize);
        }];
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
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.typeImageView.mas_right).offset(5);
            make.centerY.equalTo(self.topBarView).offset(0);
        }];
        
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
        
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.typeLabel.mas_right).offset(5);
            make.centerY.equalTo(self.topBarView);
            make.size.mas_equalTo(iconSize);
        }];
    }];
    self.disableImageView.mas_key = @"disableImageView";
    
    EZHoverButton *arrowButton = [[EZHoverButton alloc] init];
    self.arrowButton = arrowButton;
        [self addSubview:arrowButton];
        arrowButton.wantsLayer = YES;
        arrowButton.layer.cornerRadius = 3;
        arrowButton.bordered = NO;
        arrowButton.bezelStyle = NSBezelStyleRegularSquare;
        [arrowButton setButtonType:NSButtonTypeMomentaryChange];
        NSImage *image = [NSImage imageNamed:@"arrow-down-slim"];
        [arrowButton excuteLight:^(NSButton *button) {
            button.image = [image imageWithTintColor:NSColor.imageTintLightColor];
        } drak:^(NSButton *button) {
            button.image = [image imageWithTintColor:NSColor.imageTintDarkColor];
        }];
        
        arrowButton.imageScaling = NSImageScaleProportionallyDown;
        [arrowButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.topBarView.mas_right).offset(-8);
            make.centerY.equalTo(self.topBarView);
            make.size.mas_equalTo(iconSize);
        }];
    
        [arrowButton setClickBlock:^(EZButton * _Nonnull button) {
            NSLog(@"点击 arrowButton");
        }];
      
    self.arrowButton.mas_key = @"arrowButton";
    
    EZWordResultView *wordResultView = [[EZWordResultView alloc] initWithFrame:self.bounds];
    [self addSubview:wordResultView];
    self.wordResultView = wordResultView;
    
    mm_weakify(self);
    [wordResultView setPlayAudioBlock:^(EZWordResultView * _Nonnull view, NSString * _Nonnull word) {
        mm_strongify(self);
        if (self.playAudioBlock) {
            self.playAudioBlock(word);
        }
    }];
    
    [wordResultView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBarView.mas_bottom);
        make.left.right.inset(0);
//            make.bottom.inset(kVerticalMargin);
        make.bottom.equalTo(self.audioButton.mas_top).offset(-5);
        
    }];
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
    
    TranslateService *translate = [ServiceTypes serviceWithType:serviceType];
    self.typeLabel.attributedStringValue = [NSAttributedString mm_attributedStringWithString:translate.name font:[NSFont systemFontOfSize:12]];
    
    [self.wordResultView refreshWithResult:result];
}

- (void)refreshWithStateString:(NSString *)string {
    [self refreshWithStateString:string actionTitle:nil action:nil];
}

- (void)refreshWithStateString:(NSString *)string actionTitle:(NSString *_Nullable)actionTitle action:(void (^_Nullable)(void))action {
   
}

@end
