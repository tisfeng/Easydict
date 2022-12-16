//
//  EZResultView.m
//  Bob
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZResultView.h"
#import "EZServiceTypes.h"
#import "EZHoverButton.h"
#import "EZWordResultView.h"
#import "EZConst.h"
#import "NSView+EZAnimatedHidden.h"

static CGFloat const kAnimationDuration = 0.5;
static NSInteger const kAnimationDotViewCount = 5;

@interface EZResultView () <CAAnimationDelegate>

@property (nonatomic, strong) NSView *topBarView;
@property (nonatomic, strong) NSImageView *typeImageView;
@property (nonatomic, strong) NSTextField *typeLabel;
@property (nonatomic, strong) NSImageView *disableImageView;
@property (nonatomic, strong) NSView *loadingView;

@property (nonatomic, strong) NSButton *arrowButton;

@property (nonatomic, strong) EZWordResultView *wordResultView;

@property (nonatomic, strong) EZQueryResult *result;

@property (nonatomic, strong) NSTimer *timer;

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
    
    mm_weakify(self);
    
    self.topBarView = [NSView mm_make:^(NSView *_Nonnull view) {
        mm_strongify(self);
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
        mm_strongify(self);
        [self addSubview:imageView];
        imageView.hidden = YES;
        NSImage *image = [NSImage imageNamed:@"disabled"];
        [imageView setImage:image];
    }];
    self.disableImageView.mas_key = @"disableImageView";
    
    NSView *loadingView = [[NSView alloc] init];
    [self addSubview:loadingView];
    self.loadingView = loadingView;
    
    EZWordResultView *wordResultView = [[EZWordResultView alloc] initWithFrame:self.bounds];
    [self addSubview:wordResultView];
    self.wordResultView = wordResultView;
    
    [wordResultView setPlayAudioBlock:^(EZWordResultView *_Nonnull view, NSString *_Nonnull word) {
        mm_strongify(self);
        if (self.playAudioBlock) {
            self.playAudioBlock(word);
        }
    }];
    
    [wordResultView setCopyTextBlock:^(EZWordResultView *_Nonnull view, NSString *_Nonnull word) {
        mm_strongify(self);
        if (self.copyTextBlock) {
            self.copyTextBlock(word);
        }
    }];
    
    [wordResultView setQueryTextBlock:^(EZWordResultView *_Nonnull view, NSString *_Nonnull word) {
        mm_strongify(self);
        if (self.queryTextBlock) {
            self.queryTextBlock(word);
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
        
        if (!self.result.hasResult && self.result.queryModel.queryText.length == 0) {
            NSLog(@"query text is empty");
            return;
        }
        
        BOOL oldIsShowing = self.result.isShowing;
        BOOL newIsShowing = !oldIsShowing;
        self.result.isShowing = newIsShowing;
        NSLog(@"点击 arrowButton, show: %@", @(newIsShowing));
        
        [self updateArrowButton];
        
        //        [self setNeedsUpdateConstraints:YES];
        
        if (self.clickArrowBlock) {
            self.clickArrowBlock(self.result);
        }
        
        //        [self rotateArrowButton];
    }];
}


- (void)updateConstraints {
    CGSize iconSize = CGSizeMake(16, 16);
    
    [self updateArrowButton];
    
    [self.topBarView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(kResultViewMiniHeight);
    }];
    
    [self.typeImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topBarView).offset(9);
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
    
    [self.loadingView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.typeLabel.mas_right).offset(5);
        make.centerY.equalTo(self.topBarView);
        make.height.equalTo(self.topBarView);
    }];
    [self.loadingView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSView *lastView = nil;
    CGFloat width = 4;
    CGFloat padding = 1.8 * width;
    CGFloat margin = width;
    for (int i = 0; i < kAnimationDotViewCount; i++) {
        CGRect rect = CGRectMake(0, 0, width, width);
        NSView *dotView = [[NSView alloc] initWithFrame:rect];
        dotView.wantsLayer = YES;
        dotView.hidden = YES;
        dotView.layer.backgroundColor = [NSColor mm_colorWithHexString:@"#FF8E27"].CGColor;
        dotView.layer.cornerRadius = width / 2;
        [self.loadingView addSubview:dotView];
        
        [dotView mas_remakeConstraints:^(MASConstraintMaker *make) {
            if (lastView) {
                make.left.equalTo(lastView.mas_right).offset(padding);
            } else {
                make.left.equalTo(self.loadingView).offset(margin);
            }
            make.centerY.equalTo(self.loadingView);
            make.size.mas_equalTo(CGSizeMake(width, width));
        }];
        lastView = dotView;
    }
    [self.loadingView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(lastView).offset(margin);
    }];
    
    
    [self.arrowButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.topBarView.mas_right).offset(-5);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(CGSizeMake(22, 22));
    }];
    
    [self.wordResultView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBarView.mas_bottom);
        make.left.right.equalTo(self);
        make.bottom.lessThanOrEqualTo(self).offset(-5); // Since coordinate, wordResultView is under resultView
    }];
    
    [super updateConstraints];
}


- (void)refreshWithResult:(EZQueryResult *)result {
    _result = result;
    
    EZServiceType serviceType = result.serviceType;
    NSString *imageName = [NSString stringWithFormat:@"%@ Translate", serviceType];
    self.typeImageView.image = [NSImage imageNamed:imageName];
    
    self.typeLabel.attributedStringValue = [NSAttributedString mm_attributedStringWithString:result.service.name font:[NSFont systemFontOfSize:13]];
    
    [self updateArrowButton];
    
    [self.wordResultView refreshWithResult:result];
    
    
    // TODO: need to optimize. This way seems to be too time consuming and can cause UI lag, such as clicking arrow buttons. Let's change to manual height calculation later.
    [self layoutSubtreeIfNeeded];
    
    CGFloat viewHeight = kResultViewMiniHeight;
    if (result.hasResult && result.isShowing) {
        viewHeight = self.height;
//        NSLog(@"result view height: %@", @(self.height));
    }
    self.result.viewHeight = viewHeight;
    
    // animation need right frame, but result may change, so have to layout frame.
    //    [self observeIsLoadingState];
    
    [self startOrEndLoadingAnimation:self.result.isLoading];
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


#pragma mark - Animation

- (void)startOrEndLoadingAnimation:(BOOL)isLoading {
    if (isLoading) {
        [self startLoadingAnimation];
    } else {
        [self removeLoadingAnimation];
    }
}

- (void)startLoadingAnimation {
    NSLog(@"startLoadingAnimation");
    
    mm_weakify(self);

    /**
     (subviews.count - 1) * X = kAnimationDuration / 2
     4 * X = 0.25
     X = 0.12
     */
    
    NSArray *subviews = self.loadingView.subviews; // 5
    CGFloat delayInterval = 0.12;
    CGFloat animationInterval = 0.1;
    CGFloat timerInterval = (subviews.count - 1) * delayInterval + kAnimationDuration + animationInterval; // 1.0
    
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:timerInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
        mm_strongify(self);
        
        for (int i = 0; i < subviews.count; i++) {
            CGFloat delayTime = delayInterval * i;
            NSView *dotView = subviews[i];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                dotView.hidden = NO;
                [self scaleAnimateView:dotView];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime + kAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    dotView.hidden = YES;
                });
            });
        }
        
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    [self.timer fire];
}

- (void)scaleAnimateView:(NSView *)view {
    self.loadingView.hidden = NO;
    
    [view.layer removeAllAnimations];
    
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.values = @[ @1.0, @2.0, @1.0 ];
    scaleAnimation.removedOnCompletion = NO;
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.calculationMode = kCAAnimationLinear;
    
    CGRect oldRect = view.layer.frame;
    view.layer.anchorPoint = CGPointMake(0.5, 0.5);
    view.layer.frame = oldRect;
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[ scaleAnimation ];
    group.duration = kAnimationDuration;
    group.delegate = self;
    group.repeatCount = 0;
    [view.layer addAnimation:group forKey:@"group"];
}

- (void)removeLoadingAnimation {
    self.loadingView.hidden = YES;
    [self.timer invalidate];
}


#pragma mark -

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
