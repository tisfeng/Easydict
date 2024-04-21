//
//  EZLoadingAnimationView.m
//  Easydict
//
//  Created by tisfeng on 2023/1/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZLoadingAnimationView.h"

static CGFloat const kAnimationDuration = 0.5;
static NSInteger const kAnimationDotViewCount = 5;

@interface EZLoadingAnimationView ()

@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation EZLoadingAnimationView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.hidden = YES;
    
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
        [self addSubview:dotView];
        
        [dotView mas_remakeConstraints:^(MASConstraintMaker *make) {
            if (lastView) {
                make.left.equalTo(lastView.mas_right).offset(padding);
            } else {
                make.left.equalTo(self).offset(margin);
            }
            make.centerY.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(width, width));
        }];
        lastView = dotView;
    }
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(lastView).offset(margin);
    }];
}


#pragma mark - Animation

- (void)startLoading:(BOOL)isLoading {
    self.isLoading = isLoading;
    
    if (isLoading) {
        [self startLoadingAnimation];
    } else {
        [self stopLoadingAnimation];
    }
}

- (void)startLoadingAnimation {
//    MMLogVerbose(@"startLoadingAnimation");
    
    /**
     (subviews.count - 1) * X = kAnimationDuration / 2
     4 * X = 0.25
     X = 0.12
     */
    
    NSArray *subviews = self.subviews; // 5
    CGFloat delayInterval = 0.12;
    CGFloat animationInterval = 0.3;
    CGFloat timerInterval = (subviews.count - 1) * delayInterval + kAnimationDuration + animationInterval; // 1.0
    
    mm_weakify(self);
    
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:timerInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
        mm_strongify(self);
        
        for (int i = 0; i < subviews.count; i++) {
            CGFloat delayTime = delayInterval * i;
            NSView *dotView = subviews[i];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.isLoading) {
                    [self scaleAnimateView:dotView];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime + kAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        dotView.hidden = YES;
                    });
                }
            });
        }
    }];
    
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    [self.timer fire];
}

- (void)scaleAnimateView:(NSView *)view {
    self.hidden = NO;
    view.hidden = NO;
    
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
    group.repeatCount = 0;
    [view.layer addAnimation:group forKey:@"group"];
}

- (void)stopLoadingAnimation {
    self.hidden = YES;
    [self.timer invalidate];
    self.timer = nil;
}

- (void)dealloc {
    MMLogVerbose(@"EZResultView dealloc: %@", self);
    [self.timer invalidate];
    self.timer = nil;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
