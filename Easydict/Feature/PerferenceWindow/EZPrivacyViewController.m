//
//  EZPrivacyViewController.m
//  Easydict
//
//  Created by tisfeng on 2023/4/19.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZPrivacyViewController.h"
#import "NSImage+EZResize.h"
#import "EZConfiguration.h"
#import "NSViewController+EZWindow.h"
#import "NSImage+EZSymbolmage.h"
#import "Easydict-Swift.h"

@interface EZPrivacyViewController ()

@property (nonatomic, strong) NSTextField *privacyStatementTextField;
@property (nonatomic, strong) NSTextField *privacyStatementContentTextField;

@property (nonatomic, strong) NSTextField *crashLogTextField;
@property (nonatomic, strong) NSButton *crashLogButton;

@property (nonatomic, strong) NSTextField *analyticsTextField;
@property (nonatomic, strong) NSButton *analyticsButton;

@end

@implementation EZPrivacyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];

    [self updateViewSize];
}

- (void)setupUI {
    self.privacyStatementTextField = [NSTextField labelWithString:EZLocalizedString(@"privacy_statement")];
    [self.contentView addSubview:self.privacyStatementTextField];
    self.privacyStatementTextField.font = [NSFont systemFontOfSize:14];
    
    self.privacyStatementContentTextField = [NSTextField wrappingLabelWithString:EZLocalizedString(@"privacy_statement_content")];
    [self.contentView addSubview:self.privacyStatementContentTextField];
    self.privacyStatementContentTextField.preferredMaxLayoutWidth = 380;


    self.crashLogTextField = [NSTextField labelWithString:EZLocalizedString(@"crash_log")];
    [self.contentView addSubview:self.crashLogTextField];

    self.crashLogButton = [NSButton checkboxWithTitle:EZLocalizedString(@"allow_collect_crash_log")
                                                      target:self
                                                      action:@selector(crashLogButtonClicked:)];
    [self.contentView addSubview:self.crashLogButton];
    
    self.analyticsTextField = [NSTextField labelWithString:EZLocalizedString(@"analytics")];
    [self.contentView addSubview:self.analyticsTextField];

    self.analyticsButton = [NSButton checkboxWithTitle:EZLocalizedString(@"allow_collect_analytics")
                                                      target:self
                                                      action:@selector(analyticsButtonClicked:)];
    [self.contentView addSubview:self.analyticsButton];
    
    Configuration *configuration = [Configuration shared];
    self.crashLogButton.mm_isOn = configuration.allowCrashLog;
    self.analyticsButton.mm_isOn = configuration.allowAnalytics;
}

- (void)updateViewConstraints {
    [self.privacyStatementTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
    }];
    
    [self.privacyStatementContentTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.privacyStatementTextField.mas_bottom).offset(25);
        make.centerX.equalTo(self.contentView);
    }];

    [self.crashLogTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.privacyStatementContentTextField.mas_bottom).offset(40);
        make.left.equalTo(self.contentView).offset(self.leftMargin);
    }];

    [self.crashLogButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.crashLogTextField.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.crashLogTextField);
    }];

    [self.analyticsTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.crashLogTextField.mas_bottom).offset(self.verticalPadding);
        make.right.equalTo(self.crashLogTextField);
    }];

    [self.analyticsButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.analyticsTextField.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.analyticsTextField);
    }];

    
    self.topmostView = self.privacyStatementTextField;
    self.leftmostView = self.privacyStatementContentTextField;
    self.rightmostView = self.privacyStatementContentTextField;
    self.bottommostView = self.analyticsTextField;

    [super updateViewConstraints];
}

#pragma mark - Actions

- (void)crashLogButtonClicked:(NSButton *)sender {    
    if (!sender.mm_isOn) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:EZLocalizedString(@"ok")];
        [alert addButtonWithTitle:EZLocalizedString(@"cancel")];
        alert.messageText = EZLocalizedString(@"disable_crash_log_warning");
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            // ok, disable crash log
            if (returnCode == NSAlertFirstButtonReturn) {
                sender.mm_isOn = NO;
            } else {
                sender.mm_isOn = YES;
            }
            Configuration.shared.allowCrashLog = sender.mm_isOn;
        }];
    } else {
        Configuration.shared.allowCrashLog = YES;
    }
}


- (void)analyticsButtonClicked:(NSButton *)sender {
    Configuration.shared.allowAnalytics = sender.mm_isOn;
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return EZLocalizedString(@"privacy");
}

- (NSImage *)toolbarItemImage {
    NSImage *privacyImage = [NSImage imageNamed:@"toolbar_privacy"];
    /**
     SF image "hand.raised.square" require macOS 12.0
     Fix: https://github.com/tisfeng/Easydict/pull/212#discussion_r1437951644
     */
    if (@available(macOS 12.0, *)) {
        privacyImage = [NSImage ez_imageWithSymbolName:@"hand.raised.square" size:CGSizeMake(18, 16)];
    }
    privacyImage = [privacyImage imageWithTintColor:[NSColor ez_imageTintBlueColor]];
    
    return privacyImage;
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
