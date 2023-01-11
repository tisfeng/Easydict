//
//  EZAboutViewController.m
//  Easydict
//
//  Created by tisfeng on 2022/12/15.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZAboutViewController.h"
#import "EZBlueTextButton.h"

@interface EZAboutViewController ()

@property (nonatomic, strong) NSImageView *logoImageView;
@property (nonatomic, strong) NSTextField *appNameTextField;
@property (nonatomic, strong) NSTextField *versionTextField;
@property (nonatomic, strong) NSTextField *githubTextField;
@property (nonatomic, strong) EZBlueTextButton *githubLinkButton;

@end


@implementation EZAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupUI];

    [self updateViewSize];
}

- (void)setupUI {
    NSImageView *logoImageView = [[NSImageView alloc] init];
    logoImageView.image = [NSImage imageNamed:@"logo"];
    [self.contentView addSubview:logoImageView];
    self.logoImageView = logoImageView;

    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSTextField *appNameTextField = [NSTextField labelWithString:appName];
    appNameTextField.font = [NSFont systemFontOfSize:20 weight:NSFontWeightSemibold];
    [self.contentView addSubview:appNameTextField];
    self.appNameTextField = appNameTextField;

   
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *versionString = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"version", nil), version];
    NSTextField *versionValueTextField = [NSTextField labelWithString:versionString];

    [self.contentView addSubview:versionValueTextField];
    self.versionTextField = versionValueTextField;

    NSTextField *githubTextField = [NSTextField labelWithString:NSLocalizedString(@"Github:", nil)];
    [self.contentView addSubview:githubTextField];
    self.githubTextField = githubTextField;

    EZBlueTextButton *githubLinkButton = [[EZBlueTextButton alloc] init];
    [self.contentView addSubview:githubLinkButton];
    self.githubLinkButton = githubLinkButton;
    
    githubLinkButton.title = EZRepoGithubURL;
    [githubLinkButton setClickBlock:^(EZButton * _Nonnull button) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:EZRepoGithubURL]];
        [self.view.window close];
    }];
}

- (void)updateViewConstraints {
    [self.logoImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.width.height.mas_equalTo(100);
    }];
    self.topmostView = self.logoImageView;

    [self.appNameTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(1.5 * self.verticalPadding);
        make.centerX.equalTo(self.contentView);
    }];

    [self.versionTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appNameTextField.mas_bottom).offset(self.verticalPadding);
        make.centerX.equalTo(self.contentView);
    }];

    [self.githubTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.versionTextField.mas_bottom).offset(self.verticalPadding);
    }];
    self.leftmostView = self.githubTextField;

    [self.githubLinkButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.githubTextField);
        make.left.equalTo(self.githubTextField.mas_right).offset(2);
    }];
    self.rightmostView = self.githubLinkButton;
    self.bottommostView = self.githubLinkButton;

    [super updateViewConstraints];
}


#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"about", nil);
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:@"toolbar_about"];
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
