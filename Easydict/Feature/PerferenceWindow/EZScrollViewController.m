//
//  EZScrollViewController.m
//  Easydict
//
//  Created by tisfeng on 2023/1/11.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZScrollViewController.h"

static CGFloat const kMargin = 0;

@interface EZScrollViewController ()

@property (nonatomic, strong) NSScrollView *scrollView;

@end

@implementation EZScrollViewController

- (instancetype)init {
    if (self = [super init]) {
        self.maxViewSize = CGSizeMake(800, 700);

        self.verticalPadding = 15;
        self.horizontalPadding = 8;

        self.topMargin = 30;
        self.bottomMargin = 30;
        self.leftMargin = 50;
        self.rightMargin = 50;
    }
    return self;
}

- (void)loadView {
    CGRect frame = CGRectMake(0, 0, self.maxViewSize.width, self.maxViewSize.height);
    self.view = [[NSView alloc] initWithFrame:frame];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self _setupUI];
}

- (void)updateViewSize {
    [self.view layoutSubtreeIfNeeded];

    CGSize viewSize = self.scrollView.documentView.size;
    if (viewSize.height > self.maxViewSize.height) {
        viewSize.height = self.maxViewSize.height;
    }
    self.view.size = CGSizeMake(viewSize.width + 2 * kMargin, viewSize.height + 2 * kMargin);
}

- (void)_setupUI {
    NSColor *lightBgColor = [NSColor resultViewBgLightColor];
    NSColor *darkBgColor = [NSColor resultViewBgDarkColor];

    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    self.scrollView = scrollView;
    [self.view addSubview:scrollView];

    NSView *contentView = [[NSView alloc] initWithFrame:self.view.bounds];
    scrollView.documentView = contentView;
    contentView.wantsLayer = YES;
    self.contentView = contentView;

    [contentView.layer excuteLight:^(CALayer *layer) {
        layer.backgroundColor = lightBgColor.CGColor;
    } drak:^(CALayer *layer) {
        layer.backgroundColor = darkBgColor.CGColor;
    }];

    [scrollView.contentView excuteLight:^(NSClipView *contentView) {
        contentView.backgroundColor = lightBgColor;
    } drak:^(NSClipView *contentView) {
        contentView.backgroundColor = darkBgColor;
    }];
}

- (void)updateViewConstraints {
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.inset(kMargin);
    }];

    if (self.topmostView && self.bottommostView && self.leftmostView && self.rightmostView) {
        [self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topmostView).offset(-self.topMargin);
            make.bottom.equalTo(self.bottommostView).offset(self.bottomMargin);
            make.left.equalTo(self.leftmostView).offset(-self.leftMargin);
            make.right.equalTo(self.rightmostView).offset(self.rightMargin);
        }];
    }

    [super updateViewConstraints];
}

@end
