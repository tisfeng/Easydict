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
#import "NSView+EZAnimatedHidden.h"
#import "EZLoadingAnimationView.h"
#import "NSImage+EZResize.h"
#import "NSImage+EZSymbolmage.h"
#import "EZWindowManager.h"
#import "EZLocalStorage.h"

@interface EZResultView ()

@property (nonatomic, strong) NSView *topBarView;
@property (nonatomic, strong) NSImageView *serviceIcon;
@property (nonatomic, strong) NSTextField *serviceNameLabel;
@property (nonatomic, strong) EZButton *serviceModelButton;
@property (nonatomic, strong) NSImageView *errorImageView;
@property (nonatomic, strong) EZLoadingAnimationView *loadingView;
@property (nonatomic, strong) EZHoverButton *arrowButton;
@property (nonatomic, strong) EZHoverButton *stopButton;
@property (nonatomic, strong) EZHoverButton *retryButton;

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
        layer.backgroundColor = [NSColor ez_resultViewBgLightColor].CGColor;
    } dark:^(CALayer *layer) {
        layer.backgroundColor = [NSColor ez_resultViewBgDarkColor].CGColor;
    }];
    
    mm_weakify(self);
    
    self.topBarView = [NSView mm_make:^(NSView *_Nonnull view) {
        mm_strongify(self);
        [self addSubview:view];
        view.wantsLayer = YES;
        [view.layer excuteLight:^(CALayer *layer) {
            layer.backgroundColor = [NSColor ez_titleBarBgLightColor].CGColor;
        } dark:^(CALayer *layer) {
            layer.backgroundColor = [NSColor ez_titleBarBgDarkColor].CGColor;
        }];
    }];
    self.topBarView.mas_key = @"topBarView";
    
    self.serviceIcon = [NSImageView mm_make:^(NSImageView *imageView) {
        mm_strongify(self);
        [self addSubview:imageView];
        [imageView setImage:[NSImage imageNamed:@"Apple Translate"]];
    }];
    self.serviceIcon.mas_key = @"typeImageView";
    
    self.serviceNameLabel = [NSTextField mm_make:^(NSTextField *label) {
        mm_strongify(self);
        [self addSubview:label];
        label.editable = NO;
        label.bordered = NO;
        label.backgroundColor = NSColor.clearColor;
        label.alignment = NSTextAlignmentCenter;
        [label excuteLight:^(NSTextField *label) {
            label.textColor = [NSColor ez_resultTextLightColor];
        } dark:^(NSTextField *label) {
            label.textColor = [NSColor ez_resultTextDarkColor];
        }];
    }];
    self.serviceNameLabel.mas_key = @"typeLabel";
    
    self.serviceModelButton = [[EZButton alloc] init];
    [self addSubview:self.serviceModelButton];
    self.serviceModelButton.bordered = NO;
    self.serviceModelButton.cornerRadius = 3.0;
    self.serviceModelButton.titleFont = [NSFont systemFontOfSize:10];
    
    [self.serviceModelButton excuteLight:^(EZButton *button) {
        button.titleColor = [NSColor mm_colorWithHexString:@"#666666"];
        button.backgroundColor = [NSColor mm_colorWithHexString:@"#E2E2E2"];
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#D2D2D2"];
        button.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#B4B4B4"];
    } dark:^(EZButton *button) {
        button.titleColor = [NSColor mm_colorWithHexString:@"#6D6D6D"];
        button.backgroundColor = [NSColor mm_colorWithHexString:@"#202020"];
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#3D3D3D"];
        button.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#585A5C"];
    }];
    self.serviceModelButton.mas_key = @"modelButton";
    
    self.errorImageView = [NSImageView mm_make:^(NSImageView *imageView) {
        mm_strongify(self);
        [self addSubview:imageView];
        imageView.hidden = YES;
        NSImage *image = [NSImage imageNamed:@"disabled"];
        [imageView setImage:image];
    }];
    self.errorImageView.mas_key = @"errorImageView";
    
    EZLoadingAnimationView *loadingView = [[EZLoadingAnimationView alloc] init];
    [self addSubview:loadingView];
    self.loadingView = loadingView;
    
    EZWordResultView *wordResultView = [[EZWordResultView alloc] initWithFrame:self.bounds];
    [self addSubview:wordResultView];
    self.wordResultView = wordResultView;
    
    [wordResultView setDidFinishLoadingHTMLBlock:^{
        mm_strongify(self);
        [self.loadingView startLoading:NO];
    }];
    
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
        
        if (newIsShowing) {
            self.result.manulShow = YES;
        }
        
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
    NSImage *stopImage = [NSImage ez_imageWithSymbolName:@"stop.circle"];
    stopImage = [stopImage imageWithTintColor:[NSColor mm_colorWithHexString:@"#707070"]];
    stopButton.image = stopImage;
    stopButton.mas_key = @"stopButton";
    stopButton.toolTip = NSLocalizedString(@"stop", nil);
    stopButton.hidden = YES;
    
    [stopButton setClickBlock:^(EZButton *_Nonnull button) {
        mm_strongify(self);
        [self.result.queryModel stopServiceRequest:self.result.serviceType];
        self.result.isStreamFinished = YES;
        button.hidden = YES;
    }];
    
    EZHoverButton *retryButton = [[EZHoverButton alloc] init];
    self.retryButton = retryButton;
    [self addSubview:retryButton];
    NSImage *retryImage = [NSImage ez_imageWithSymbolName:@"arrow.clockwise.circle"];
    retryButton.image = retryImage;
    retryButton.mas_key = @"retryButton";
    retryButton.toolTip = NSLocalizedString(@"retry", nil);
    retryButton.hidden = YES;
    [retryButton excuteLight:^(NSButton *button) {
        button.image = [button.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
    } dark:^(NSButton *button) {
        button.image = [button.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
    }];
    
    [retryButton setClickBlock:^(EZButton *button) {
        if (self.retryBlock) {
            self.retryBlock(self.result);
        }
    }];
    
    
    CGSize iconSize = CGSizeMake(16, 16);
    
    [self updateArrowButton];
    
    [self.topBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(EZResultViewMiniHeight);
    }];
    
    [self.serviceIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topBarView).offset(9);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(iconSize);
    }];
    
    [self.serviceNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.serviceIcon.mas_right).offset(4);
        make.centerY.equalTo(self.topBarView).offset(0);
    }];
    
    [self.serviceModelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.serviceNameLabel.mas_right).offset(2);
        make.top.equalTo(self.topBarView).offset(8);
        make.bottom.equalTo(self.topBarView).offset(-8);
    }];
    
    [self.errorImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.serviceNameLabel.mas_right).offset(8);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(iconSize);
    }];
    
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.serviceNameLabel.mas_right).offset(5);
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
    
    [self.retryButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.arrowButton.mas_left).offset(-5);
        make.centerY.equalTo(self.topBarView);
        make.size.mas_equalTo(CGSizeMake(22, 22));
    }];
}

#pragma mark - Setter

- (void)setResult:(EZQueryResult *)result {
    _result = result;
    
    EZServiceType serviceType = result.serviceType;
    self.serviceIcon.image = [NSImage imageNamed:serviceType];
    
    self.serviceNameLabel.attributedStringValue = [NSAttributedString mm_attributedStringWithString:result.service.name font:[NSFont systemFontOfSize:13]];
    if ([self isBaseOpenAIService:result.service]) {
        EZBaseOpenAIService *service = (EZBaseOpenAIService *)result.service;
        self.serviceModelButton.title = service.model;
        mm_weakify(self);
        [self.serviceModelButton setClickBlock:^(EZButton *_Nonnull button) {
            mm_strongify(self);
            [self showModelSelectionMenu:button];
        }];
        [self updateServiceModelLabel];
    } else {
        self.serviceModelButton.hidden = YES;
    }
    [self.wordResultView refreshWithResult:result];
    
    mm_weakify(self);
    [self.wordResultView setUpdateViewHeightBlock:^(CGFloat wordResultViewHeight) {
        mm_strongify(self);
        [self updateWordResultViewHeight:wordResultViewHeight];
    }];
    
    [self updateAllButtonStatus];
    
    CGFloat wordResultViewHeight = self.wordResultView.viewHeight ?: result.webViewManager.wordResultViewHeight;
    [self updateWordResultViewHeight:wordResultViewHeight];
    
    // animation need right frame, but result may change, so have to layout frame.
    [self updateLoadingAnimation];
}

- (void)setQueryTextBlock:(void (^)(NSString *_Nonnull))clickTextBlock {
    _queryTextBlock = clickTextBlock;
    self.wordResultView.queryTextBlock = clickTextBlock;
}

#pragma mark -

- (void)updateWordResultViewHeight:(CGFloat)wordResultViewHeight {
    if (self.result.HTMLString.length) {
        self.result.webViewManager.wordResultViewHeight = wordResultViewHeight;
        
        if (wordResultViewHeight) {
            self.result.isLoading = NO;
        }
    }
    
    [self.wordResultView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBarView.mas_bottom);
        make.left.right.equalTo(self);
        
        make.height.mas_equalTo(wordResultViewHeight);
    }];
    
    CGFloat viewHeight = EZResultViewMiniHeight;
    if (self.result.hasShowingResult && self.result.isShowing) {
        viewHeight = EZResultViewMiniHeight + wordResultViewHeight;
        //        NSLog(@"show result view height: %@", @(self.height));
    }
    self.result.viewHeight = viewHeight;
    //    NSLog(@"%@, result view height: %@", result.serviceType, @(viewHeight));
}

#pragma mark - Public Methods

- (void)updateLoadingAnimation {
    [self updateServiceModelLabel];
    [self startOrStopLoadingAnimation:self.result.isLoading];
}

- (void)startOrStopLoadingAnimation:(BOOL)isLoading {
    if (isLoading) {
        self.errorImageView.hidden = YES;
    }
    [self.loadingView startLoading:isLoading];
}

#pragma mark -

- (void)updateAllButtonStatus {
    [self updateErrorImage];
    
    [self updateRetryButton];
    [self updateStopButton];
    [self updateArrowButton];
    [self updateServiceModelLabel];
}

- (void)updateErrorImage {
    BOOL showWarningImage = !self.result.hasTranslatedResult && self.result.error.type;
    self.errorImageView.hidden = !showWarningImage;
    
    NSString *errorImageName = @"disabled";
    NSString *toolTip = @"Unsupported Language";
    if (!self.result.isWarningErrorType) {
        errorImageName = @"error";
    }
    NSImage *errorImage = [NSImage imageNamed:errorImageName];
    
    self.errorImageView.image = errorImage;
    self.errorImageView.toolTip = toolTip;
}

- (void)updateRetryButton {
    BOOL showRetryButton = self.result.error && (!self.result.isWarningErrorType);
    self.retryButton.hidden = !showRetryButton;
}

- (void)updateStopButton {
    BOOL showStopButton = NO;
    
    // Currently, only support stop OpenAI service.
    if (self.result.service.isStream) {
        showStopButton = self.result.hasTranslatedResult && !self.result.isStreamFinished;
    }
    
    self.stopButton.hidden = !showStopButton;
}

- (void)updateArrowButton {
    NSImage *arrowImage = [NSImage imageNamed:@"arrow-left"];
    if (self.result.isShowing) {
        arrowImage = [NSImage imageNamed:@"arrow-down"];
    }
    
    self.arrowButton.toolTip = self.result.isShowing ? NSLocalizedString(@"hide", nil) : NSLocalizedString(@"show", nil);
    
    [self.arrowButton excuteLight:^(NSButton *button) {
        button.image = [arrowImage imageWithTintColor:[NSColor ez_imageTintLightColor]];
    } dark:^(NSButton *button) {
        button.image = [arrowImage imageWithTintColor:[NSColor ez_imageTintDarkColor]];
    }];
}

- (BOOL)isBaseOpenAIService:(EZQueryService *)service {
    return [service isKindOfClass:[EZBaseOpenAIService class]];
}

- (void)updateServiceModelLabel {
    if (![self isBaseOpenAIService:self.result.service]) {
        return;
    }
    BOOL showWarningImage = !self.result.hasTranslatedResult && self.result.error.type;
    BOOL showRetryButton = self.result.error && (!self.result.isWarningErrorType);
    BOOL isLoading = self.result.isLoading;
    self.serviceModelButton.hidden = showWarningImage || showRetryButton || isLoading;
}

- (void)showModelSelectionMenu:(EZButton *)sender {
    EZBaseOpenAIService *service = (EZBaseOpenAIService *)self.result.service;    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Menu"];
    for (NSString *model in service.availableModels) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:model action:@selector(modelDidSelected:) keyEquivalent:@""];
        item.target = self;
        [menu addItem:item];
    }
    [menu popUpBelowView:sender];
}

- (void)modelDidSelected:(NSMenuItem *)sender {
    EZBaseOpenAIService *service = (EZBaseOpenAIService *)self.result.service;
    if (![service.model isEqualToString:sender.title]) {
        service.model = sender.title;
        self.serviceModelButton.title = service.model;
        [self postServiceUpdatedNotification:service.serviceType];
    }
}

- (void)postServiceUpdatedNotification:(EZServiceType)serviceType {
    NSDictionary *userInfo = @{EZServiceTypeKey : serviceType};
    NSNotification *notification = [NSNotification notificationWithName:EZServiceHasUpdatedNotification object:nil userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
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
