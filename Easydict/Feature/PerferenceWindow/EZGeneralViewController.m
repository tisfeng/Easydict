//
//  EZGeneralViewController.m
//  Easydict
//
//  Created by tisfeng on 2022/12/15.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZGeneralViewController.h"
#import "EZShortcut.h"
#import "EZConfiguration.h"

@interface EZGeneralViewController ()

@property (nonatomic, strong) NSTextField *selectLabel;
@property (nonatomic, strong) NSTextField *inputLabel;
@property (nonatomic, strong) NSTextField *snipLabel;
@property (nonatomic, strong) NSTextField *showMiniLabel;

@property (strong) IBOutlet MASShortcutView *selectionShortcutView;
@property (strong) IBOutlet MASShortcutView *snipShortcutView;
@property (strong) IBOutlet MASShortcutView *inputShortcutView;
@property (strong) IBOutlet MASShortcutView *showMiniShortcutView;

@property (nonatomic, strong) NSView *separator;

@property (nonatomic, strong) NSTextField *selectTextLabel;
@property (nonatomic, strong) NSTextField *launchLabel;
@property (nonatomic, strong) NSTextField *checkUpdateLabel;
@property (nonatomic, strong) NSTextField *hideMainWindowLabel;


@property (strong) IBOutlet NSButton *autoSelectTextButton;
@property (strong) IBOutlet NSButton *launchAtStartupButton;
@property (strong) IBOutlet NSButton *autoCheckUpdateButton;
@property (strong) IBOutlet NSButton *hideMainWindowButton;

@end


@implementation EZGeneralViewController


- (void)loadView {
    CGRect frame = CGRectMake(0, 0, 430, 350);
    self.view = [[NSView alloc] initWithFrame:frame];
    //    self.view.wantsLayer = YES;
    //    self.view.layer.cornerRadius = EZCornerRadius_8;
    //    self.view.layer.masksToBounds = YES;
    //    [self.view excuteLight:^(NSView *_Nonnull x) {
    //        x.layer.backgroundColor = NSColor.mainViewBgLightColor.CGColor;
    //    } drak:^(NSView *_Nonnull x) {
    //        x.layer.backgroundColor = NSColor.mainViewBgDarkColor.CGColor;
    //    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

    [self setupUI];
}

- (void)setupUI {
    NSTextField *selectLabel = [NSTextField labelWithString:NSLocalizedString(@"select_translate", nil)];
    [self.view addSubview:selectLabel];
    self.selectLabel = selectLabel;
    self.selectionShortcutView = [[MASShortcutView alloc] init];
    [self.view addSubview:self.selectionShortcutView];


    NSTextField *inputLabel = [NSTextField labelWithString:NSLocalizedString(@"input_translate", nil)];
    [self.view addSubview:inputLabel];
    self.inputLabel = inputLabel;
    self.inputShortcutView = [[MASShortcutView alloc] init];
    [self.view addSubview:self.inputShortcutView];


    NSTextField *snipLabel = [NSTextField labelWithString:NSLocalizedString(@"snip_translate", nil)];
    [self.view addSubview:snipLabel];
    self.snipLabel = snipLabel;
    self.snipShortcutView = [[MASShortcutView alloc] init];
    [self.view addSubview:self.snipShortcutView];


    NSTextField *showMiniLabel = [NSTextField labelWithString:NSLocalizedString(@"show_mini_window", nil)];
    [self.view addSubview:showMiniLabel];
    self.showMiniLabel = showMiniLabel;
    self.showMiniShortcutView = [[MASShortcutView alloc] init];
    [self.view addSubview:self.showMiniShortcutView];

    NSView *separator = [[NSView alloc] init];
    [self.view addSubview:separator];
    self.separator = separator;
    separator.wantsLayer = YES;
    [separator excuteLight:^(NSView *separator) {
        separator.layer.backgroundColor = [NSColor mm_colorWithHexString:@"#212223"].CGColor;
    } drak:^(NSView *separator) {
        separator.layer.backgroundColor = [NSColor mm_colorWithHexString:@"#7C7C7C"].CGColor;
    }];


    NSTextField *selectTextLabel = [NSTextField labelWithString:NSLocalizedString(@"show_icon", nil)];
    [self.view addSubview:selectTextLabel];
    self.selectTextLabel = selectTextLabel;

    NSString *autoSelectTextTitle = NSLocalizedString(@"auto_show_icon", nil);
    self.autoSelectTextButton = [NSButton checkboxWithTitle:autoSelectTextTitle target:self action:@selector(autoSelectTextButtonClicked:)];
    [self.view addSubview:self.autoSelectTextButton];
    [self.autoCheckUpdateButton setButtonType:NSButtonTypeSwitch];

    NSTextField *launchLabel = [NSTextField labelWithString:NSLocalizedString(@"launch", nil)];
    [self.view addSubview:launchLabel];
    self.launchLabel = launchLabel;

    NSString *launchAtStartupTitle = NSLocalizedString(@"launch_at_startup", nil);
    self.launchAtStartupButton = [NSButton checkboxWithTitle:launchAtStartupTitle target:self action:@selector(launchAtStartupButtonClicked:)];
    [self.view addSubview:self.launchAtStartupButton];

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

    [self.selectionShortcutView setAssociatedUserDefaultsKey:EZSelectionShortcutKey];
    [self.inputShortcutView setAssociatedUserDefaultsKey:EZInputShortcutKey];
    [self.snipShortcutView setAssociatedUserDefaultsKey:EZSnipShortcutKey];
    [self.showMiniShortcutView setAssociatedUserDefaultsKey:EZShowMiniShortcutKey];

    self.autoSelectTextButton.mm_isOn = EZConfiguration.shared.autoSelectText;
    self.launchAtStartupButton.mm_isOn = EZConfiguration.shared.launchAtStartup;
    self.autoCheckUpdateButton.mm_isOn = EZConfiguration.shared.automaticallyChecksForUpdates;
    self.hideMainWindowButton.mm_isOn = EZConfiguration.shared.hideMainWindow;
}

- (void)updateViewConstraints {
    CGFloat leftMargin = 100;
    CGFloat topMargin = 30;

    CGFloat verticalPadding = 20;
    CGFloat horizontalPadding = 8;

    [self.selectLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(leftMargin);
        make.top.equalTo(self.view).offset(topMargin);
    }];
    [self.selectionShortcutView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.selectLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.selectLabel);
        make.height.mas_equalTo(25);
    }];

    [self.inputLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.selectLabel.mas_bottom).offset(verticalPadding);
    }];
    [self.inputShortcutView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.inputLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.inputLabel);
        make.height.equalTo(self.selectionShortcutView);
    }];

    [self.snipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.inputLabel.mas_bottom).offset(verticalPadding);
    }];
    [self.snipShortcutView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.snipLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.snipLabel);
        make.height.equalTo(self.selectionShortcutView);
    }];

    [self.showMiniLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.snipLabel.mas_bottom).offset(verticalPadding);
    }];
    [self.showMiniShortcutView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.showMiniLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.showMiniLabel);
        make.height.equalTo(self.selectionShortcutView);
    }];

    // add separator
    [self.separator mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.inset(35);
        make.top.equalTo(self.showMiniLabel.mas_bottom).offset(verticalPadding);
        make.height.mas_equalTo(0.5);
    }];

    [self.selectTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.separator.mas_bottom).offset(verticalPadding);
    }];

    [self.autoSelectTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.selectTextLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.selectTextLabel);
    }];

    [self.launchLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.autoSelectTextButton.mas_bottom).offset(verticalPadding);
    }];

    [self.launchAtStartupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.launchLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.launchLabel);
    }];

    [self.checkUpdateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.launchAtStartupButton.mas_bottom).offset(verticalPadding);
    }];

    [self.autoCheckUpdateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.checkUpdateLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.checkUpdateLabel);
    }];

    [self.hideMainWindowLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.autoCheckUpdateButton.mas_bottom).offset(verticalPadding);
    }];

    [self.hideMainWindowButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.hideMainWindowLabel.mas_right).offset(horizontalPadding);
        make.centerY.equalTo(self.hideMainWindowLabel);
    }];


    [super updateViewConstraints];
}

#pragma mark - event

- (IBAction)autoSelectTextButtonClicked:(NSButton *)sender {
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

- (IBAction)launchAtStartupButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.launchAtStartup = sender.mm_isOn;
}

- (IBAction)autoCheckUpdateButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.automaticallyChecksForUpdates = sender.mm_isOn;
}

- (void)hideMainWindowButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.hideMainWindow = sender.mm_isOn;
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"general", nil);
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
