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
        self.maxViewSize = CGSizeMake(800, 500);

        self.verticalMargin = 25;
        self.horizontalMargin = 50;
        self.verticalPadding = 15;
        self.horizontalPadding = 8;
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
    NSColor *lightBgColor = [NSColor resultViewBgLightColor];  // [NSColor mm_colorWithHexString:@"#F2F0F1"];
    NSColor *darkBgColor = [NSColor resultViewBgDarkColor]; // [NSColor mm_colorWithHexString:@"#353131"];

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

    self.topmostView = self.view;
    self.bottommostView = self.view;
    self.leftmostView = self.view;
    self.rightmostView = self.view;
}

- (void)updateViewConstraints {
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.inset(kMargin);
    }];

    [self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topmostView).offset(-self.verticalMargin);
        make.bottom.equalTo(self.bottommostView).offset(self.verticalMargin);
        make.right.equalTo(self.rightmostView).offset(self.horizontalMargin);
        make.left.equalTo(self.leftmostView).offset(-self.horizontalMargin);
    }];

    [super updateViewConstraints];
}


@end
