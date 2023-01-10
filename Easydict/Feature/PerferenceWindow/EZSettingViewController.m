//
//  EZGeneralViewController.m
//  Easydict
//
//  Created by tisfeng on 2022/12/15.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZSettingViewController.h"
#import "EZShortcut.h"
#import "EZConfiguration.h"
#import "EZWindowManager.h"

static CGFloat const kMargin = 0;

@interface EZSettingViewController ()

@property (nonatomic, strong) NSScrollView *scrollView;

@property (nonatomic, strong) NSTextField *selectTextLabel;
@property (nonatomic, strong) NSTextField *playAudioLabel;
@property (nonatomic, strong) NSTextField *snipTranslateLabel;

@property (nonatomic, strong) NSTextField *checkUpdateLabel;
@property (nonatomic, strong) NSTextField *hideMainWindowLabel;
@property (nonatomic, strong) NSTextField *launchLabel;

@property (strong) NSButton *autoSelectTextButton;
@property (strong) NSButton *autoPlayAudioButton;
@property (strong) NSButton *snipTranslateButton;
@property (strong) NSButton *autoCheckUpdateButton;
@property (strong) NSButton *hideMainWindowButton;
@property (strong) NSButton *launchAtStartupButton;

@end


@implementation EZSettingViewController


- (void)loadView {
    CGRect frame = CGRectMake(0, 0, 450, 300);
    self.view = [[NSView alloc] initWithFrame:frame];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

    [self setupUI];

    [self.view layoutSubtreeIfNeeded];
    CGSize documentViewSize = self.scrollView.documentView.size;
    self.view.size = CGSizeMake(documentViewSize.width + 2 * kMargin, documentViewSize.height + 2 * kMargin);
}

- (void)setupUI {
    NSColor *lightBgColor = [NSColor mm_colorWithHexString:@"#F2F0F1"];
    NSColor *darkBgColor = [NSColor mm_colorWithHexString:@"#353131"];

    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    self.scrollView = scrollView;
    [self.view addSubview:scrollView];
    
    NSView *contentView = [[NSView alloc] initWithFrame:self.view.bounds];
    scrollView.documentView = contentView;
    contentView.wantsLayer = YES;

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

    NSTextField *selectTextLabel = [NSTextField labelWithString:NSLocalizedString(@"show_icon", nil)];
    [contentView addSubview:selectTextLabel];
    self.selectTextLabel = selectTextLabel;

    NSString *autoSelectTextTitle = NSLocalizedString(@"auto_show_icon", nil);
    self.autoSelectTextButton = [NSButton checkboxWithTitle:autoSelectTextTitle target:self action:@selector(autoSelectTextButtonClicked:)];
    [contentView addSubview:self.autoSelectTextButton];
    [self.autoCheckUpdateButton setButtonType:NSButtonTypeSwitch];

    NSTextField *playAudioLabel = [NSTextField labelWithString:NSLocalizedString(@"play_audio", nil)];
    [contentView addSubview:playAudioLabel];
    self.playAudioLabel = playAudioLabel;

    NSString *autoPlayAudioTitle = NSLocalizedString(@"auto_play_audio", nil);
    self.autoPlayAudioButton = [NSButton checkboxWithTitle:autoPlayAudioTitle target:self action:@selector(autoPlayAudioButtonClicked:)];
    [contentView addSubview:self.autoPlayAudioButton];


    NSTextField *snipTranslateLabel = [NSTextField labelWithString:NSLocalizedString(@"snip_translate", nil)];
    [contentView addSubview:snipTranslateLabel];
    self.snipTranslateLabel = snipTranslateLabel;

    NSString *snipTranslateTitle = NSLocalizedString(@"auto_snip_translate", nil);
    self.snipTranslateButton = [NSButton checkboxWithTitle:snipTranslateTitle target:self action:@selector(snipTranslateButtonClicked:)];
    [contentView addSubview:self.snipTranslateButton];

    NSTextField *checkUpdateLabel = [NSTextField labelWithString:NSLocalizedString(@"check_update", nil)];
    [contentView addSubview:checkUpdateLabel];
    self.checkUpdateLabel = checkUpdateLabel;

    NSString *autoCheckUpdateTitle = NSLocalizedString(@"auto_check_update", nil);
    self.autoCheckUpdateButton = [NSButton checkboxWithTitle:autoCheckUpdateTitle target:self action:@selector(autoCheckUpdateButtonClicked:)];
    [contentView addSubview:self.autoCheckUpdateButton];

    NSTextField *hideMainWindowLabel = [NSTextField labelWithString:NSLocalizedString(@"main_window", nil)];
    [contentView addSubview:hideMainWindowLabel];
    self.hideMainWindowLabel = hideMainWindowLabel;

    NSString *hideMainWindowTitle = NSLocalizedString(@"hide_main_window", nil);
    self.hideMainWindowButton = [NSButton checkboxWithTitle:hideMainWindowTitle target:self action:@selector(hideMainWindowButtonClicked:)];
    [contentView addSubview:self.hideMainWindowButton];

    NSTextField *launchLabel = [NSTextField labelWithString:NSLocalizedString(@"launch", nil)];
    [contentView addSubview:launchLabel];
    self.launchLabel = launchLabel;

    NSString *launchAtStartupTitle = NSLocalizedString(@"launch_at_startup", nil);
    self.launchAtStartupButton = [NSButton checkboxWithTitle:launchAtStartupTitle target:self action:@selector(launchAtStartupButtonClicked:)];
    [contentView addSubview:self.launchAtStartupButton];


    self.autoSelectTextButton.mm_isOn = EZConfiguration.shared.autoSelectText;
    self.launchAtStartupButton.mm_isOn = EZConfiguration.shared.launchAtStartup;
    self.autoCheckUpdateButton.mm_isOn = EZConfiguration.shared.automaticallyChecksForUpdates;
    self.hideMainWindowButton.mm_isOn = EZConfiguration.shared.hideMainWindow;
    self.snipTranslateButton.mm_isOn = EZConfiguration.shared.autoSnipTranslate;
}

- (void)updateViewConstraints {
    CGFloat verticalMargin = 25;
    CGFloat horizontalMargin = 50;

    CGFloat verticalPadding = 15;
    CGFloat horizontalPadding = 8;
    CGFloat buttonHeight = 20;

    NSView *leftmostView;
    NSView *rightmostView;
    NSView *topmostView;
    NSView *bottommostView;

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.inset(kMargin);
    }];

    [self.selectTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.scrollView).offset(horizontalMargin);
        make.top.equalTo(self.scrollView).offset(verticalMargin);
    }];
    topmostView = self.selectTextLabel;

    [self.autoSelectTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.selectTextLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.selectTextLabel);
        make.height.mas_equalTo(buttonHeight);
    }];
    rightmostView = self.autoSelectTextButton;

    [self.playAudioLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectTextLabel);
        make.top.equalTo(self.autoSelectTextButton.mas_bottom).offset(verticalPadding);
    }];
    leftmostView = self.playAudioLabel;

    [self.autoPlayAudioButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playAudioLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.playAudioLabel);
        make.height.mas_equalTo(buttonHeight);
    }];

    [self.snipTranslateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectTextLabel);
        make.top.equalTo(self.autoPlayAudioButton.mas_bottom).offset(verticalPadding);
    }];

    [self.snipTranslateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.snipTranslateLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.snipTranslateLabel);
        make.height.mas_equalTo(buttonHeight);
    }];

    [self.checkUpdateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectTextLabel);
        make.top.equalTo(self.snipTranslateButton.mas_bottom).offset(verticalPadding);
    }];

    [self.autoCheckUpdateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.checkUpdateLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.checkUpdateLabel);
        make.height.mas_equalTo(buttonHeight);
    }];

    [self.hideMainWindowLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectTextLabel);
        make.top.equalTo(self.autoCheckUpdateButton.mas_bottom).offset(verticalPadding);
    }];

    [self.hideMainWindowButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.hideMainWindowLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.hideMainWindowLabel);
        make.height.mas_equalTo(buttonHeight);
    }];


    [self.launchLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectTextLabel);
        make.top.equalTo(self.hideMainWindowButton.mas_bottom).offset(verticalPadding);
    }];

    [self.launchAtStartupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.launchLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.launchLabel);
        make.height.mas_equalTo(buttonHeight);
    }];
    bottommostView = self.launchAtStartupButton;

    [self.scrollView.documentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topmostView).offset(-verticalMargin);
        make.bottom.equalTo(bottommostView).offset(verticalMargin);
        make.right.equalTo(rightmostView).offset(horizontalMargin);
        make.left.equalTo(leftmostView).offset(-horizontalMargin);
    }];

    [super updateViewConstraints];
}

#pragma mark - event

- (void)autoSelectTextButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.autoSelectText = sender.mm_isOn;

    if (sender.mm_isOn) {
        [self checkAppIsTrusted];
    }
}

- (BOOL)checkAppIsTrusted {
    BOOL isTrusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef) @{(__bridge NSString *)kAXTrustedCheckOptionPrompt : @YES});
    NSLog(@"isTrusted: %d", isTrusted);

    return isTrusted == YES;
}

- (void)launchAtStartupButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.launchAtStartup = sender.mm_isOn;
}

- (void)autoCheckUpdateButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.automaticallyChecksForUpdates = sender.mm_isOn;
}

- (void)hideMainWindowButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.hideMainWindow = sender.mm_isOn;

    [[EZWindowManager shared] showOrHideDockAppAndMainWindow];
}

- (void)snipTranslateButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.autoSnipTranslate = sender.mm_isOn;
}

- (void)autoPlayAudioButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.autoPlayAudio = self.autoPlayAudioButton.mm_isOn;
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"setting", nil);
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:@"toolbar_setting"];
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
