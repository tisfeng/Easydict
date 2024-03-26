//
//  EZAboutViewController.m
//  Easydict
//
//  Created by tisfeng on 2022/12/15.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZAboutViewController.h"
#import "EZBlueTextButton.h"
#import "EZConfiguration.h"
#import "EZMenuItemManager.h"
#import "Easydict-Swift.h"

@interface EZAboutViewController ()

@property (nonatomic, strong) NSImageView *logoImageView;
@property (nonatomic, strong) NSTextField *appNameTextField;
@property (nonatomic, strong) NSTextField *currentVersionTextField;
@property (nonatomic, strong) NSTextField *latestVersionTextField;
@property (nonatomic, strong) NSButton *autoCheckUpdateButton;

@property (nonatomic, strong) NSView *authorView;
@property (nonatomic, strong) NSTextField *authorTextField;
@property (nonatomic, strong) EZBlueTextButton *authorLinkButton;

@property (nonatomic, strong) NSTextField *githubTextField;
@property (nonatomic, strong) EZBlueTextButton *githubLinkButton;

@end


@implementation EZAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupUI];
    self.autoCheckUpdateButton.mm_isOn = Configuration.shared.automaticallyChecksForUpdates;

    [self updateViewSize];

    [self updateLatestVersion];
    
//    [self fetchGithubRepoInfo:repo];
}

- (void)setupUI {
    NSImageView *logoImageView = [[NSImageView alloc] init];
    logoImageView.image = [NSImage imageNamed:@"logo"];
    [self.contentView addSubview:logoImageView];
    self.logoImageView = logoImageView;

    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSTextField *appNameTextField = [NSTextField labelWithString:appName];
    appNameTextField.font = [NSFont systemFontOfSize:26 weight:NSFontWeightSemibold];
    [self.contentView addSubview:appNameTextField];
    self.appNameTextField = appNameTextField;


    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *versionString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"current_version", nil), version];
    NSTextField *versionValueTextField = [NSTextField labelWithString:versionString];
    versionValueTextField.font = [NSFont systemFontOfSize:14];
    [self.contentView addSubview:versionValueTextField];
    self.currentVersionTextField = versionValueTextField;

    NSString *autoCheckUpdateTitle = NSLocalizedString(@"auto_check_update", nil);
    self.autoCheckUpdateButton = [NSButton checkboxWithTitle:autoCheckUpdateTitle target:self action:@selector(autoCheckUpdateButtonClicked:)];
    [self.contentView addSubview:self.autoCheckUpdateButton];

    NSString *latestVersionString = [NSString stringWithFormat:@"(%@ %@)", NSLocalizedString(@"lastest_version", nil), version];
    NSTextField *latestVersionTextField = [NSTextField labelWithString:latestVersionString];
    [self.contentView addSubview:latestVersionTextField];
    self.latestVersionTextField = latestVersionTextField;

    self.authorView = [[NSView alloc] init];
    [self.contentView addSubview:self.authorView];

    NSTextField *authorTextField = [NSTextField labelWithString:NSLocalizedString(@"author", nil)];
    [self.authorView addSubview:authorTextField];
    self.authorTextField = authorTextField;

    EZBlueTextButton *authorLinkButton = [[EZBlueTextButton alloc] init];
    [self.authorView addSubview:authorLinkButton];
    self.authorLinkButton = authorLinkButton;

    authorLinkButton.title = @"Tisfeng";
    
    NSString *urlString = EZGithubRepoEasydictURL;
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];

    NSString *path = components.path;
    NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
    if (pathComponents.count > 1) {
        NSMutableArray *mutablePathComponents = [pathComponents mutableCopy];
        [mutablePathComponents removeLastObject];
        NSString *newPath = [mutablePathComponents componentsJoinedByString:@"/"];
        components.path = newPath;
    }
    NSString *authorURL = components.URL.absoluteString;
    
    authorLinkButton.openURL = authorURL; // https://github.com/tisfeng
    authorLinkButton.closeWindowAfterOpeningURL = YES;

    NSTextField *githubTextField = [NSTextField labelWithString:NSLocalizedString(@"GitHub:", nil)];
    [self.contentView addSubview:githubTextField];
    self.githubTextField = githubTextField;

    EZBlueTextButton *githubLinkButton = [[EZBlueTextButton alloc] init];
    [self.contentView addSubview:githubLinkButton];
    self.githubLinkButton = githubLinkButton;

    githubLinkButton.title = EZGithubRepoEasydictURL;
    githubLinkButton.openURL = EZGithubRepoEasydictURL;
    githubLinkButton.closeWindowAfterOpeningURL = YES;
}

- (void)updateViewConstraints {
    [self.logoImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.width.height.mas_equalTo(110);
    }];
    self.topmostView = self.logoImageView;

    [self.appNameTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(self.verticalPadding);
        make.centerX.equalTo(self.contentView);
    }];

    [self.currentVersionTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appNameTextField.mas_bottom).offset(1.5 * self.verticalPadding);
        make.centerX.equalTo(self.contentView);
    }];

    [self.autoCheckUpdateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.currentVersionTextField.mas_bottom).offset(self.verticalPadding);
        make.centerX.equalTo(self.contentView);
    }];

    [self.latestVersionTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.autoCheckUpdateButton.mas_bottom).offset(5);
        make.centerX.equalTo(self.contentView);
    }];

    [self.authorView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.latestVersionTextField.mas_bottom).offset(40);
        make.centerX.equalTo(self.contentView);
        make.height.equalTo(self.authorLinkButton);
    }];

    [self.authorTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.authorView);
        make.left.equalTo(self.authorView);
    }];

    [self.authorLinkButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.authorView);
        make.left.equalTo(self.authorTextField.mas_right).offset(2);
        make.right.equalTo(self.authorView);
    }];

    [self.githubTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.authorView.mas_bottom).offset(self.verticalPadding);
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

#pragma mark - Actions

- (void)autoCheckUpdateButtonClicked:(NSButton *)sender {
    Configuration.shared.automaticallyChecksForUpdates = sender.mm_isOn;
}

- (void)updateLatestVersion {
    [EZMenuItemManager.shared fetchRepoLatestVersion:EZGithubRepoEasydict completion:^(NSString *latestVersion) {
        NSString *latestVersionString = [NSString stringWithFormat:@"(%@ %@)", NSLocalizedString(@"lastest_version", nil), latestVersion];
        self.latestVersionTextField.stringValue = latestVersionString;
    }];
}

- (void)fetchGithubRepoInfo:(NSString *)repo {
    NSString *urlString = [NSString stringWithFormat:@"https://api.github.com/repos/%@", repo];
    NSURL *url = [NSURL URLWithString:urlString];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {

    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
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
