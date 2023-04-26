//
//  EZResultView.m
//  Easydict
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZResultView.h"
#import "EZServiceTypes.h"
#import "EZHoverButton.h"
#import "EZWordResultView.h"
#import "NSView+EZAnimatedHidden.h"
#import "EZLoadingAnimationView.h"
#import "NSImage+EZResize.h"

@interface EZResultView ()

@property (nonatomic, strong) NSView *topBarView;
@property (nonatomic, strong) NSImageView *typeImageView;
@property (nonatomic, strong) NSTextField *typeLabel;
@property (nonatomic, strong) NSImageView *warningImageView;
@property (nonatomic, strong) EZLoadingAnimationView *loadingView;
@property (nonatomic, strong) NSButton *arrowButton;
@property (nonatomic, strong) NSButton *stopButton;

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
    } dark:^(CALayer *layer) {
        layer.backgroundColor = NSColor.resultViewBgDarkColor.CGColor;
    }];

    mm_weakify(self);

    self.topBarView = [NSView mm_make:^(NSView *_Nonnull view) {
        mm_strongify(self);
        [self addSubview:view];
        view.wantsLayer = YES;
        [view.layer excuteLight:^(CALayer *layer) {
            layer.backgroundColor = NSColor.topBarBgLightColor.CGColor;
        } dark:^(CALayer *layer) {
            layer.backgroundColor = NSColor.topBarBgDarkColor.CGColor;
        }];
    }];
    self.topBarView.mas_key = @"topBarView";

    self.typeImageView = [NSImageView mm_make:^(NSImageView *imageView) {
        mm_strongify(self);
        [self addSubview:imageView];
        [imageView setImage:[NSImage imageNamed:@"Apple Translate"]];
    }];
    self.typeImageView.mas_key = @"typeImageView";

    self.typeLabel = [NSTextField mm_make:^(NSTextField *label) {
        mm_strongify(self);
        [self addSubview:label];
        label.editable = NO;
        label.bordered = NO;
        label.backgroundColor = NSColor.clearColor;
        label.alignment = NSTextAlignmentCenter;
        [label excuteLight:^(NSTextField *label) {
            label.textColor = NSColor.resultTextLightColor;
        } dark:^(NSTextField *label) {
            label.textColor = NSColor.resultTextDarkColor;
        }];
    }];
    self.typeLabel.mas_key = @"typeLabel";

    self.warningImageView = [NSImageView mm_make:^(NSImageView *imageView) {
        mm_strongify(self);
        [self addSubview:imageView];
        imageView.hidden = YES;
        NSImage *image = [NSImage imageNamed:@"disabled"];
        [imageView setImage:image];
    }];
    self.warningImageView.mas_key = @"warningImageView";

    EZLoadingAnimationView *loadingView = [[EZLoadingAnimationView alloc] init];
    [self addSubview:loadingView];
    self.loadingView = loadingView;

    EZWordResultView *wordResultView = [[EZWordResultView alloc] initWithFrame:self.bounds];
    [self addSubview:wordResultView];
    self.wordResultView = wordResultView;

    EZHoverButton *arrowButton = [[EZHoverButton alloc] init];
    self.arrowButton = arrowButton;
    [self addSubview:arrowButton];
    NSImage *image = [NSImage imageNamed:@"arrow-down"];
    arrowButton.image = image;
    self.arrowButton.mas_key = @"arrowButton";

    [arrowButton setClickBlock:^(EZButton *_Nonnull button) {
        mm_strongify(self);

        if (!self.result.hasShowingResult && self.result.queryModel.queryText.length == 0) {
            NSLog(@"query text is empty");
            return;
        }

        BOOL oldIsShowing = self.result.isShowing;
        BOOL newIsShowing = !oldIsShowing;
        self.result.isShowing = newIsShowing;
        NSLog(@"点击 arrowButton, show: %@", @(newIsShowing));

        [self updateArrowButton];

        if (self.clickArrowBlock) {
            self.clickArrowBlock(self.result);
        }

        // TODO: add arrow roate animation.

        //        [self rotateArrowButton];
    }];
    
    
    EZHoverButton *stopButton = [[EZHoverButton alloc] init];
    self.stopButton = stopButton;
    [self addSubview:stopButton];
    NSImage *stopImage = [NSImage imageWithSystemSymbolName:@"stop.circle" accessibilityDescription:nil];
    stopImage = [stopImage imageWithTintColor:[NSColor mm_colorWithHexString:@"#707070"]];
    stopImage = [stopImage resizeToSize:CGSizeMake(EZAudioButtonImageWidth_16, EZAudioButtonImageWidth_16)];
    stopButton.image = stopImage;
    self.stopButton.mas_key = @"stopButton";
    self.stopButton.toolTip = @"Stop";

    [stopButton setClickBlock:^(EZButton *_Nonnull button) {
        mm_strongify(self);
        [self.result.queryModel stopServiceRequest:self.result.serviceType];
        button.hidden = YES;
    }];


    CGSize iconSize = CGSizeMake(16, 16);

    [self updateArrowButton];

    [self.topBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(EZResultViewMiniHeight);
    }];

    [self.typeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topBarView).offset(9);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(iconSize);
    }];

    [self.typeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.typeImageView.mas_right).offset(4);
        make.centerY.equalTo(self.topBarView).offset(0);
    }];

    [self.warningImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.typeLabel.mas_right).offset(5);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(iconSize);
    }];

    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.typeLabel.mas_right).offset(5);
        make.centerY.equalTo(self.topBarView);
        make.height.equalTo(self.topBarView);
    }];


    [self.arrowButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.topBarView.mas_right).offset(-5);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(CGSizeMake(22, 22));
    }];
    
    [self.stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.arrowButton.mas_left).offset(-5);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(CGSizeMake(22, 22));
    }];
}

#pragma mark - Setter

- (void)setResult:(EZQueryResult *)result {
    _result = result;

    EZServiceType serviceType = result.serviceType;
    self.typeImageView.image = [NSImage imageNamed:serviceType];

    self.typeLabel.attributedStringValue = [NSAttributedString mm_attributedStringWithString:result.service.name font:[NSFont systemFontOfSize:13]];


    [self.wordResultView refreshWithResult:result];

    BOOL hideWarningImage = YES;
    if (!result.hasTranslatedResult && (result.error || result.errorMessage.length)) {
        hideWarningImage = NO;
    }
    self.warningImageView.hidden = hideWarningImage;

    [self updateArrowButton];
    
    // Currently, only support stop OpenAI service.
    BOOL isFinished = result.hasTranslatedResult && !result.isFinished;
    BOOL isOpenAIFinished = isFinished && [serviceType isEqualToString:EZServiceTypeOpenAI];
    self.stopButton.hidden = !isOpenAIFinished;


    CGFloat wordResultViewHeight = self.wordResultView.viewHeight;
    [self.wordResultView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBarView.mas_bottom);
        make.left.right.equalTo(self);

        make.height.mas_equalTo(wordResultViewHeight);
    }];

    CGFloat viewHeight = EZResultViewMiniHeight;
    if (result.hasShowingResult && result.isShowing) {
        viewHeight = EZResultViewMiniHeight + wordResultViewHeight;
        //        NSLog(@"show result view height: %@", @(self.height));
    }
    self.result.viewHeight = viewHeight;
    //    NSLog(@"%@, result view height: %@", result.serviceType, @(viewHeight));


    // animation need right frame, but result may change, so have to layout frame.
    [self updateLoadingAnimation];
}

- (void)setCopyTextBlock:(void (^)(NSString *_Nonnull))copyTextBlock {
    _copyTextBlock = copyTextBlock;
    self.wordResultView.copyTextBlock = copyTextBlock;
}

- (void)setClickTextBlock:(void (^)(NSString *_Nonnull))clickTextBlock {
    _clickTextBlock = clickTextBlock;
    self.wordResultView.clickTextBlock = clickTextBlock;
}


#pragma mark - Public Methods

- (void)updateLoadingAnimation {
    [self startOrStopLoadingAnimation:self.result.isLoading];
}

- (void)startOrStopLoadingAnimation:(BOOL)isLoading {
    if (isLoading) {
        self.warningImageView.hidden = YES;
    }
    [self.loadingView startLoading:isLoading];
}

#pragma mark -

- (void)updateArrowButton {
    NSImage *arrowImage = [NSImage imageNamed:@"arrow-left"];
    if (self.result.isShowing) {
        arrowImage = [NSImage imageNamed:@"arrow-down"];
    }
    
    self.arrowButton.toolTip = self.result.isShowing ? @"Hide" : @"Show";
    
    [self.arrowButton excuteLight:^(NSButton *button) {
        button.image = [arrowImage imageWithTintColor:NSColor.imageTintLightColor];
    } dark:^(NSButton *button) {
        button.image = [arrowImage imageWithTintColor:NSColor.imageTintDarkColor];
    }];
}

#pragma mark - Animation

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

// add color animation for view. color from white to gray
- (void)addColorAnimationForView:(NSView *)view {
    CABasicAnimation *colorAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    colorAnimation.fromValue = (id)[NSColor whiteColor].CGColor;
    colorAnimation.toValue = (id)[NSColor grayColor].CGColor;
    colorAnimation.duration = 0.5;
    colorAnimation.repeatCount = MAXFLOAT;
    colorAnimation.autoreverses = YES;
    [view.layer addAnimation:colorAnimation forKey:@"colorAnimation"];
}

// add scale animation for view. scale from 1.0 to 1.8
- (void)addScaleAnimationForView:(NSView *)view {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    animation.values = @[ @1.0, @1.8, @1.0 ];
    animation.repeatCount = MAXFLOAT;
    animation.duration = 0.6;
    [view.layer addAnimation:animation forKey:@"animation"];
}

// add rotation animation for view. rotation from 0 to 90
- (void)addRotationAnimationForView:(NSView *)view {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = @(0);
    animation.toValue = [NSNumber numberWithFloat:90 * (M_PI / 180.0f)];
    animation.cumulative = YES;
    animation.repeatCount = MAXFLOAT;
    animation.duration = 1;
    [view.layer addAnimation:animation forKey:@"animation"];
}

// add animation group for view. group include scale and rotation animation
- (void)addAnimationGroupForView:(NSView *)view {
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.values = @[ @1.0, @1.8, @1.0 ];
    scaleAnimation.repeatCount = MAXFLOAT;
    scaleAnimation.duration = 0.6;

    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = @(0);
    rotationAnimation.toValue = [NSNumber numberWithFloat:90 * (M_PI / 180.0f)];
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = MAXFLOAT;
    rotationAnimation.duration = 1;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[ scaleAnimation, rotationAnimation ];
    group.duration = 1;
    group.repeatCount = MAXFLOAT;
    [view.layer addAnimation:group forKey:@"group"];
}

@end
