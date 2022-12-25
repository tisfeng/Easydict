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

@interface EZSettingViewController ()

@property (nonatomic, strong) NSTextField *selectTextLabel;
@property (nonatomic, strong) NSTextField *launchLabel;
@property (nonatomic, strong) NSTextField *checkUpdateLabel;
@property (nonatomic, strong) NSTextField *hideMainWindowLabel;
@property (nonatomic, strong) NSTextField *snipTranslateLabel;

@property (strong) NSButton *autoSelectTextButton;
@property (strong) NSButton *launchAtStartupButton;
@property (strong) NSButton *autoCheckUpdateButton;
@property (strong) NSButton *hideMainWindowButton;
@property (strong) NSButton *snipTranslateButton;

@end


@implementation EZSettingViewController


- (void)loadView {
    CGRect frame = CGRectMake(0, 0, 430, 200);
    self.view = [[NSView alloc] initWithFrame:frame];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

    [self setupUI];
}

- (void)setupUI {
    NSTextField *selectTextLabel = [NSTextField labelWithString:NSLocalizedString(@"show_icon", nil)];
    [self.view addSubview:selectTextLabel];
    self.selectTextLabel = selectTextLabel;

    NSString *autoSelectTextTitle = NSLocalizedString(@"auto_show_icon", nil);
    self.autoSelectTextButton = [NSButton checkboxWithTitle:autoSelectTextTitle target:self action:@selector(autoSelectTextButtonClicked:)];
    [self.view addSubview:self.autoSelectTextButton];
    [self.autoCheckUpdateButton setButtonType:NSButtonTypeSwitch];


    NSTextField *checkUpdateLabel = [NSTextField labelWithString:NSLocalizedString(@"check_update", nil)];
    [self.view addSubview:checkUpdateLabel];
    self.checkUpdateLabel = checkUpdateLabel;

    NSString *autoCheckUpdateTitle = NSLocalizedString(@"auto_check_update", nil);
    self.autoCheckUpdateButton = [NSButton checkboxWithTitle:autoCheckUpdateTitle target:self action:@selector(autoCheckUpdateButtonClicked:)];
    [self.view addSubview:self.autoCheckUpdateButton];

    NSTextField *hideMainWindowLabel = [NSTextField labelWithString:NSLocalizedString(@"main_window", nil)];
    [self.view addSubview:hideMainWindowLabel];
    self.hideMainWindowLabel = hideMainWindowLabel;

    NSString *hideMainWindowTitle = NSLocalizedString(@"hide_main_window", nil);
    self.hideMainWindowButton = [NSButton checkboxWithTitle:hideMainWindowTitle target:self action:@selector(hideMainWindowButtonClicked:)];
    [self.view addSubview:self.hideMainWindowButton];

    NSTextField *launchLabel = [NSTextField labelWithString:NSLocalizedString(@"launch", nil)];
    [self.view addSubview:launchLabel];
    self.launchLabel = launchLabel;

    NSString *launchAtStartupTitle = NSLocalizedString(@"launch_at_startup", nil);
    self.launchAtStartupButton = [NSButton checkboxWithTitle:launchAtStartupTitle target:self action:@selector(launchAtStartupButtonClicked:)];
    [self.view addSubview:self.launchAtStartupButton];

    NSTextField *snipTranslateLabel = [NSTextField labelWithString:NSLocalizedString(@"snip_translate", nil)];
    [self.view addSubview:snipTranslateLabel];
    self.snipTranslateLabel = snipTranslateLabel;

    NSString *snipTranslateTitle = NSLocalizedString(@"auto_snip_translate", nil);
    self.snipTranslateButton = [NSButton checkboxWithTitle:snipTranslateTitle target:self action:@selector(snipTranslateButtonClicked:)];
    [self.view addSubview:self.snipTranslateButton];


    self.autoSelectTextButton.mm_isOn = EZConfiguration.shared.autoSelectText;
    self.launchAtStartupButton.mm_isOn = EZConfiguration.shared.launchAtStartup;
    self.autoCheckUpdateButton.mm_isOn = EZConfiguration.shared.automaticallyChecksForUpdates;
    self.hideMainWindowButton.mm_isOn = EZConfiguration.shared.hideMainWindow;
    self.snipTranslateButton.mm_isOn = EZConfiguration.shared.autoSnipTranslate;
}

- (void)updateViewConstraints {
    CGFloat leftMargin = 60;
    CGFloat topMargin = 20;

    CGFloat verticalPadding = 15;
    CGFloat horizontalPadding = 8;


    [self.selectTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(leftMargin);
        make.top.equalTo(self.view).offset(topMargin);
    }];

    [self.autoSelectTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.selectTextLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.selectTextLabel);
    }];

    [self.snipTranslateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectTextLabel);
        make.top.equalTo(self.autoSelectTextButton.mas_bottom).offset(verticalPadding);
    }];

    [self.snipTranslateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.snipTranslateLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.snipTranslateLabel);
    }];

    [self.checkUpdateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectTextLabel);
        make.top.equalTo(self.snipTranslateButton.mas_bottom).offset(verticalPadding);
    }];

    [self.autoCheckUpdateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.checkUpdateLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.checkUpdateLabel);
    }];

    [self.hideMainWindowLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectTextLabel);
        make.top.equalTo(self.autoCheckUpdateButton.mas_bottom).offset(verticalPadding);
    }];

    [self.hideMainWindowButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.hideMainWindowLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.hideMainWindowLabel);
    }];


    [self.launchLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectTextLabel);
        make.top.equalTo(self.hideMainWindowButton.mas_bottom).offset(verticalPadding);
    }];

    [self.launchAtStartupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.launchLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.launchLabel);
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
}

- (void)snipTranslateButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.autoSnipTranslate = sender.mm_isOn;
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"setting", nil);
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:@"toolbar_general"];
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
