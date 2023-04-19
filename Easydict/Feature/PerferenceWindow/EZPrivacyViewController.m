//
//  EZPrivacyViewController.m
//  Easydict
//
//  Created by tisfeng on 2023/4/19.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZPrivacyViewController.h"
#import "NSImage+EZResize.h"

@interface EZPrivacyViewController ()

@property (nonatomic, strong) NSTextField *privacyStatementTextField;

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

    self.privacyStatementTextField = [NSTextField wrappingLabelWithString:NSLocalizedString(@"privacy_statement", nil)];
    [self.contentView addSubview:self.privacyStatementTextField];
    self.privacyStatementTextField.preferredMaxLayoutWidth = 300;
    

    self.crashLogTextField = [NSTextField labelWithString:NSLocalizedString(@"crash_log", nil)];
    [self.contentView addSubview:self.crashLogTextField];

    self.crashLogButton = [NSButton checkboxWithTitle:NSLocalizedString(@"allow_collect_crash_log", nil)
                                                      target:self
                                                      action:@selector(crashLogButtonClicked:)];
    [self.contentView addSubview:self.crashLogButton];
    
    self.analyticsTextField = [NSTextField labelWithString:NSLocalizedString(@"analytics", nil)];
    [self.contentView addSubview:self.analyticsTextField];

    self.analyticsButton = [NSButton checkboxWithTitle:NSLocalizedString(@"allow_collect_analytics", nil)
                                                      target:self
                                                      action:@selector(analyticsButtonClicked:)];
    [self.contentView addSubview:self.analyticsButton];
}

- (void)updateViewConstraints {
    [self.privacyStatementTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
    }];

    [self.crashLogTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.privacyStatementTextField.mas_bottom).offset(40);
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
    self.leftmostView = self.crashLogTextField;
    self.rightmostView = self.privacyStatementTextField;
    self.bottommostView = self.analyticsTextField;

    [super updateViewConstraints];
}

#pragma mark - Actions

- (void)crashLogButtonClicked:(NSButton *)sender {
    NSLog(@"%s", __func__);
}

- (void)analyticsButtonClicked:(NSButton *)sender {
    NSLog(@"%s", __func__);
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"privacy", nil);
}

- (NSImage *)toolbarItemImage {
    NSImage *privacyImage = [NSImage imageWithSystemSymbolName:@"hand.raised.square.fill" accessibilityDescription:nil];
    privacyImage = [privacyImage imageWithTintColor:[NSColor mm_colorWithHexString:@"#1296DB"]];
    privacyImage = [privacyImage resizeToSize:CGSizeMake(EZAudioButtonImageWidth_16, EZAudioButtonImageWidth_16)];
        
    return privacyImage;
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
