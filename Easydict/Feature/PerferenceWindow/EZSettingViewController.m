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
#import "NSViewController+EZWindow.h"

@interface EZSettingViewController () <NSComboBoxDelegate>

@property (nonatomic, strong) NSTextField *selectLabel;
@property (nonatomic, strong) NSTextField *inputLabel;
@property (nonatomic, strong) NSTextField *snipLabel;
@property (nonatomic, strong) NSTextField *showMiniLabel;

@property (nonatomic, strong) MASShortcutView *selectionShortcutView;
@property (nonatomic, strong) MASShortcutView *snipShortcutView;
@property (nonatomic, strong) MASShortcutView *inputShortcutView;
@property (nonatomic, strong) MASShortcutView *showMiniShortcutView;

@property (nonatomic, strong) NSView *separatorView;

@property (nonatomic, strong) NSTextField *showQueryIconLabel;
@property (nonatomic, strong) NSButton *showQueryIconButton;

@property (nonatomic, strong) NSTextField *adjustQueryIconPostionLabel;
@property (nonatomic, strong) NSButton *adjustQueryIconPostionButton;

@property (nonatomic, strong) NSTextField *languageDetectLabel;
@property (nonatomic, strong) NSPopUpButton *languageDetectOptimizePopUpButton;

@property (nonatomic, strong) NSTextField *fixedWindowPositionLabel;
@property (nonatomic, strong) NSPopUpButton *fixedWindowPositionPopUpButton;

@property (nonatomic, strong) NSTextField *playAudioLabel;
@property (nonatomic, strong) NSButton *autoPlayAudioButton;

@property (nonatomic, strong) NSTextField *autoQueryLabel;
@property (nonatomic, strong) NSButton *autoQueryOCRTextButton;
@property (nonatomic, strong) NSButton *autoQuerySelectedTextButton;

@property (nonatomic, strong) NSTextField *autoCopyTextLabel;
@property (nonatomic, strong) NSButton *autoCopySelectedTextButton;
@property (nonatomic, strong) NSButton *autoCopyOCRTextButton;


@property (nonatomic, strong) NSTextField *showQuickLinkLabel;
@property (nonatomic, strong) NSButton *showGoogleQuickLinkButton;
@property (nonatomic, strong) NSButton *showEudicQuickLinkButton;

@property (nonatomic, strong) NSView *separatorView2;

@property (nonatomic, strong) NSTextField *hideMainWindowLabel;
@property (nonatomic, strong) NSButton *hideMainWindowButton;

@property (nonatomic, strong) NSTextField *launchLabel;
@property (nonatomic, strong) NSButton *launchAtStartupButton;

@property (nonatomic, strong) NSTextField *menuBarIconLabel;
@property (nonatomic, strong) NSButton *hideMenuBarIconButton;

@property (nonatomic, strong) NSTextField *disableEmptyCopyBeepLabel;
@property (nonatomic, strong) NSButton *disableEmptyCopyBeepButton;

@end


@implementation EZSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self setupUI];
    
    self.leftMargin = 110;
    self.rightMargin = 100;
    
    [self updateViewSize];
}

- (void)setupUI {
    NSFont *font = [NSFont systemFontOfSize:13];
    
    NSTextField *inputLabel = [NSTextField labelWithString:NSLocalizedString(@"input_translate", nil)];
    inputLabel.font = font;
    [self.contentView addSubview:inputLabel];
    self.inputLabel = inputLabel;
    self.inputShortcutView = [[MASShortcutView alloc] init];
    [self.contentView addSubview:self.inputShortcutView];
    
    NSTextField *snipLabel = [NSTextField labelWithString:NSLocalizedString(@"snip_translate", nil)];
    snipLabel.font = font;
    [self.contentView addSubview:snipLabel];
    self.snipLabel = snipLabel;
    self.snipShortcutView = [[MASShortcutView alloc] init];
    [self.contentView addSubview:self.snipShortcutView];
    
    NSTextField *selectLabel = [NSTextField labelWithString:NSLocalizedString(@"select_translate", nil)];
    selectLabel.font = font;
    [self.contentView addSubview:selectLabel];
    self.selectLabel = selectLabel;
    self.selectionShortcutView = [[MASShortcutView alloc] init];
    [self.contentView addSubview:self.selectionShortcutView];
    
    NSTextField *showMiniLabel = [NSTextField labelWithString:NSLocalizedString(@"show_mini_window", nil)];
    showMiniLabel.font = font;
    [self.contentView addSubview:showMiniLabel];
    self.showMiniLabel = showMiniLabel;
    self.showMiniShortcutView = [[MASShortcutView alloc] init];
    [self.contentView addSubview:self.showMiniShortcutView];
    
    if ([EZLanguageManager isEnglishFirstLanguage]) {
        self.leftmostView = self.showMiniLabel;
    }
    
    [self.inputShortcutView setAssociatedUserDefaultsKey:EZInputShortcutKey];
    [self.snipShortcutView setAssociatedUserDefaultsKey:EZSnipShortcutKey];
    [self.selectionShortcutView setAssociatedUserDefaultsKey:EZSelectionShortcutKey];
    [self.showMiniShortcutView setAssociatedUserDefaultsKey:EZShowMiniShortcutKey];
    
    NSColor *separatorLightColor = [NSColor mm_colorWithHexString:@"#D9DADA"];
    NSColor *separatorDarkColor = [NSColor mm_colorWithHexString:@"#3C3C3C"];
    
    NSView *separatorView = [[NSView alloc] init];
    [self.contentView addSubview:separatorView];
    self.separatorView = separatorView;
    separatorView.wantsLayer = YES;
    [separatorView excuteLight:^(NSView *view) {
        view.layer.backgroundColor = separatorLightColor.CGColor;
    } dark:^(NSView *view) {
        view.layer.backgroundColor = separatorDarkColor.CGColor;
    }];
    
    NSTextField *showQueryIconLabel = [NSTextField labelWithString:NSLocalizedString(@"show_query_icon", nil)];
    showQueryIconLabel.font = font;
    [self.contentView addSubview:showQueryIconLabel];
    self.showQueryIconLabel = showQueryIconLabel;
    
    NSString *showQueryIconTitle = NSLocalizedString(@"auto_show_icon", nil);
    self.showQueryIconButton = [NSButton checkboxWithTitle:showQueryIconTitle target:self action:@selector(autoSelectTextButtonClicked:)];
    [self.contentView addSubview:self.showQueryIconButton];
    
    NSTextField *adjustQueryIconPostionLabel = [NSTextField labelWithString:NSLocalizedString(@"adjust_pop_button_origin", nil)];
    adjustQueryIconPostionLabel.font = font;
    [self.contentView addSubview:adjustQueryIconPostionLabel];
    self.adjustQueryIconPostionLabel = adjustQueryIconPostionLabel;
    
    NSString *adjustQueryIconPostionTitle = NSLocalizedString(@"avoid_conflict_with_PopClip_display", nil);
    self.adjustQueryIconPostionButton = [NSButton checkboxWithTitle:adjustQueryIconPostionTitle target:self action:@selector(adjustQueryIconPostionButtonClicked:)];
    [self.contentView addSubview:self.adjustQueryIconPostionButton];
    
    
    NSTextField *usesLanguageCorrectionLabel = [NSTextField labelWithString:NSLocalizedString(@"language_detect_optimize", nil)];
    usesLanguageCorrectionLabel.font = font;
    [self.contentView addSubview:usesLanguageCorrectionLabel];
    self.languageDetectLabel = usesLanguageCorrectionLabel;
    
    
    self.languageDetectOptimizePopUpButton = [[NSPopUpButton alloc] init];
    
    NSArray *languageDetectOptimizeItems = @[
        NSLocalizedString(@"language_detect_optimize_none", nil),
        NSLocalizedString(@"language_detect_optimize_baidu", nil),
        NSLocalizedString(@"language_detect_optimize_google", nil),
    ];
    [self.languageDetectOptimizePopUpButton addItemsWithTitles:languageDetectOptimizeItems];
    [self.contentView addSubview:self.languageDetectOptimizePopUpButton];
    self.languageDetectOptimizePopUpButton.target = self;
    self.languageDetectOptimizePopUpButton.action = @selector(languageDetectOptimizePopUpButtonClicked:);
    
    
    NSTextField *fixedWindowPositionLabel = [NSTextField labelWithString:NSLocalizedString(@"fixed_window_position", nil)];
    fixedWindowPositionLabel.font = font;
    [self.contentView addSubview:fixedWindowPositionLabel];
    self.fixedWindowPositionLabel = fixedWindowPositionLabel;
    
    self.fixedWindowPositionPopUpButton = [[NSPopUpButton alloc] init];
    MMOrderedDictionary *fixedWindowPostionDict = [EZLayoutManager.shared fixedWindowPositionDict];
    NSArray *fixedWindowPositionItems = [fixedWindowPostionDict sortedValues];
    [self.fixedWindowPositionPopUpButton addItemsWithTitles:fixedWindowPositionItems];
    [self.contentView addSubview:self.fixedWindowPositionPopUpButton];
    self.fixedWindowPositionPopUpButton.target = self;
    self.fixedWindowPositionPopUpButton.action = @selector(fixedWindowPositionPopUpButtonClicked:);
    
    
    NSTextField *playAudioLabel = [NSTextField labelWithString:NSLocalizedString(@"play_audio", nil)];
    playAudioLabel.font = font;
    [self.contentView addSubview:playAudioLabel];
    self.playAudioLabel = playAudioLabel;
    
    NSString *autoPlayAudioTitle = NSLocalizedString(@"auto_play_audio", nil);
    self.autoPlayAudioButton = [NSButton checkboxWithTitle:autoPlayAudioTitle target:self action:@selector(autoPlayAudioButtonClicked:)];
    [self.contentView addSubview:self.autoPlayAudioButton];
    
    
    NSTextField *autoQueryLabel = [NSTextField labelWithString:NSLocalizedString(@"auto_query", nil)];
    autoQueryLabel.font = font;
    [self.contentView addSubview:autoQueryLabel];
    self.autoQueryLabel = autoQueryLabel;
    
    NSString *autoQueryOCTText = NSLocalizedString(@"auto_query_ocr_text", nil);
    self.autoQueryOCRTextButton = [NSButton checkboxWithTitle:autoQueryOCTText target:self action:@selector(autoQueryOCRTextButtonClicked:)];
    [self.contentView addSubview:self.autoQueryOCRTextButton];
    
    NSString *autoQuerySelectedText = NSLocalizedString(@"auto_query_selected_text", nil);
    self.autoQuerySelectedTextButton = [NSButton checkboxWithTitle:autoQuerySelectedText target:self action:@selector(autoQuerySelectedTextButtonClicked:)];
    [self.contentView addSubview:self.autoQuerySelectedTextButton];
    
    
    NSTextField *autoCopyTextLabel = [NSTextField labelWithString:NSLocalizedString(@"auto_copy_text", nil)];
    autoCopyTextLabel.font = font;
    [self.contentView addSubview:autoCopyTextLabel];
    self.autoCopyTextLabel = autoCopyTextLabel;
    
    NSString *autoCopyOCRText = NSLocalizedString(@"auto_copy_ocr_text", nil);
    self.autoCopyOCRTextButton = [NSButton checkboxWithTitle:autoCopyOCRText target:self action:@selector(autoCopyOCRTextButtonClicked:)];
    [self.contentView addSubview:self.autoCopyOCRTextButton];
    
    NSString *autoCopySelectedText = NSLocalizedString(@"auto_copy_selected_text", nil);
    self.autoCopySelectedTextButton = [NSButton checkboxWithTitle:autoCopySelectedText target:self action:@selector(autoCopySelectedTextButtonClicked:)];
    [self.contentView addSubview:self.autoCopySelectedTextButton];
    
    NSTextField *showQuickLinkLabel = [NSTextField labelWithString:NSLocalizedString(@"quick_link", nil)];
    showQuickLinkLabel.font = font;
    [self.contentView addSubview:showQuickLinkLabel];
    self.showQuickLinkLabel = showQuickLinkLabel;
    
    NSString *showGoogleQuickLink = NSLocalizedString(@"show_google_quick_link", nil);
    self.showGoogleQuickLinkButton = [NSButton checkboxWithTitle:showGoogleQuickLink target:self action:@selector(showGoogleQuickLinkButtonClicked:)];
    [self.contentView addSubview:self.showGoogleQuickLinkButton];
    
    NSString *showEudicQuickLink = NSLocalizedString(@"show_eudic_quick_link", nil);
    self.showEudicQuickLinkButton = [NSButton checkboxWithTitle:showEudicQuickLink target:self action:@selector(showEudicQuickLinkButtonClicked:)];
    [self.contentView addSubview:self.showEudicQuickLinkButton];
    
    NSTextField *disableEmptyCopyBeepLabel = [NSTextField labelWithString:NSLocalizedString(@"disable_empty_copy_beep", nil)];
    disableEmptyCopyBeepLabel.font = font;
    [self.contentView addSubview:disableEmptyCopyBeepLabel];
    self.disableEmptyCopyBeepLabel = disableEmptyCopyBeepLabel;
    
    NSString *disableEmptyCopyBeepTitle = NSLocalizedString(@"disable_empty_copy_beep_info", nil);
    self.disableEmptyCopyBeepButton = [NSButton checkboxWithTitle:disableEmptyCopyBeepTitle target:self action:@selector(disableEmptyCopyBeepButtonClicked:)];
    self.disableEmptyCopyBeepButton.toolTip = @"Some apps may have beeps when using it. Enabling it can disable the beeps.";
    [self.contentView addSubview:self.disableEmptyCopyBeepButton];
    
    
    NSView *separatorView2 = [[NSView alloc] init];
    [self.contentView addSubview:separatorView2];
    self.separatorView2 = separatorView2;
    separatorView2.wantsLayer = YES;
    [separatorView2 excuteLight:^(NSView *view) {
        view.layer.backgroundColor = separatorLightColor.CGColor;
    } dark:^(NSView *view) {
        view.layer.backgroundColor = separatorDarkColor.CGColor;
    }];
    
    NSTextField *hideMainWindowLabel = [NSTextField labelWithString:NSLocalizedString(@"show_main_window", nil)];
    hideMainWindowLabel.font = font;
    [self.contentView addSubview:hideMainWindowLabel];
    self.hideMainWindowLabel = hideMainWindowLabel;
    
    NSString *hideMainWindowTitle = NSLocalizedString(@"hide_main_window", nil);
    self.hideMainWindowButton = [NSButton checkboxWithTitle:hideMainWindowTitle target:self action:@selector(hideMainWindowButtonClicked:)];
    [self.contentView addSubview:self.hideMainWindowButton];
    
    NSTextField *launchLabel = [NSTextField labelWithString:NSLocalizedString(@"launch", nil)];
    launchLabel.font = font;
    [self.contentView addSubview:launchLabel];
    self.launchLabel = launchLabel;
    
    NSString *launchAtStartupTitle = NSLocalizedString(@"launch_at_startup", nil);
    self.launchAtStartupButton = [NSButton checkboxWithTitle:launchAtStartupTitle target:self action:@selector(launchAtStartupButtonClicked:)];
    [self.contentView addSubview:self.launchAtStartupButton];
    
    NSTextField *menubarIconLabel = [NSTextField labelWithString:NSLocalizedString(@"menu_bar_icon", nil)];
    menubarIconLabel.font = font;
    [self.contentView addSubview:menubarIconLabel];
    self.menuBarIconLabel = menubarIconLabel;
    
    NSString *hideMenuBarIcon = NSLocalizedString(@"hide_menu_bar_icon", nil);
    self.hideMenuBarIconButton = [NSButton checkboxWithTitle:hideMenuBarIcon target:self action:@selector(hideMenuBarIconButtonClicked:)];
    [self.contentView addSubview:self.hideMenuBarIconButton];
    
    
    EZConfiguration *configuration = [EZConfiguration shared];
    self.showQueryIconButton.mm_isOn = configuration.autoSelectText;
    self.adjustQueryIconPostionButton.mm_isOn = configuration.adjustPopButtomOrigin;
    [self.languageDetectOptimizePopUpButton selectItemAtIndex:configuration.languageDetectOptimize];
    [self.fixedWindowPositionPopUpButton selectItemAtIndex:configuration.fixedWindowPosition];
    self.autoPlayAudioButton.mm_isOn = configuration.autoPlayAudio;
    self.launchAtStartupButton.mm_isOn = configuration.launchAtStartup;
    self.hideMainWindowButton.mm_isOn = configuration.hideMainWindow;
    self.autoQueryOCRTextButton.mm_isOn = configuration.autoQueryOCRText;
    self.autoQuerySelectedTextButton.mm_isOn = configuration.autoQuerySelectedText;
    self.autoCopySelectedTextButton.mm_isOn = configuration.autoCopySelectedText;
    self.autoCopyOCRTextButton.mm_isOn = configuration.autoCopyOCRText;
    self.showGoogleQuickLinkButton.mm_isOn = configuration.showGoogleQuickLink;
    self.showEudicQuickLinkButton.mm_isOn = configuration.showEudicQuickLink;
    self.hideMenuBarIconButton.mm_isOn = configuration.hideMenuBarIcon;
    self.disableEmptyCopyBeepButton.mm_isOn = configuration.disableEmptyCopyBeep;
}

- (void)updateViewConstraints {
    CGFloat separatorMargin = 40;
    
    [self.inputLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.contentView).offset(self.topMargin).priorityLow();
    }];
    [self.inputShortcutView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.inputLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.inputLabel);
        make.height.equalTo(self.selectionShortcutView);
    }];
    
    [self.snipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.inputShortcutView.mas_bottom).offset(self.verticalPadding);
    }];
    [self.snipShortcutView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.snipLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.snipLabel);
        make.height.equalTo(self.selectionShortcutView);
    }];
    
    [self.selectLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(self.leftMargin).priorityLow();
        make.top.equalTo(self.snipShortcutView.mas_bottom).offset(self.verticalPadding);
    }];
    [self.selectionShortcutView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.selectLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.selectLabel);
        make.height.mas_equalTo(25);
    }];
    
    [self.showMiniLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.selectionShortcutView.mas_bottom).offset(self.verticalPadding);
    }];
    [self.showMiniShortcutView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.showMiniLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.showMiniLabel);
        make.height.equalTo(self.selectionShortcutView);
    }];
    
    [self.separatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.inset(separatorMargin);
        make.top.equalTo(self.showMiniLabel.mas_bottom).offset(1.5 * self.verticalPadding);
        make.height.mas_equalTo(1);
    }];
    
    [self.showQueryIconLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.separatorView.mas_bottom).offset(1.5 * self.verticalPadding);
    }];
    [self.showQueryIconButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.showQueryIconLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.showQueryIconLabel);
    }];
    
    [self.adjustQueryIconPostionLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.showQueryIconButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.adjustQueryIconPostionButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.adjustQueryIconPostionLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.adjustQueryIconPostionLabel);
    }];
    
    [self.languageDetectLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.adjustQueryIconPostionButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.languageDetectOptimizePopUpButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.languageDetectLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.languageDetectLabel);
    }];
    
    [self.fixedWindowPositionLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.languageDetectOptimizePopUpButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.fixedWindowPositionPopUpButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.fixedWindowPositionLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.fixedWindowPositionLabel);
    }];
    
    [self.playAudioLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.fixedWindowPositionPopUpButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.autoPlayAudioButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playAudioLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.playAudioLabel);
    }];
    
    [self.autoQueryLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.autoPlayAudioButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.autoQueryOCRTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoQueryLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.autoQueryLabel);
    }];
    [self.autoQuerySelectedTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoQueryOCRTextButton);
        make.top.equalTo(self.autoQueryOCRTextButton.mas_bottom).offset(self.verticalPadding);
    }];
    
    
    
    [self.autoCopyTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.autoQuerySelectedTextButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.autoCopyOCRTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoQueryOCRTextButton);
        make.centerY.equalTo(self.autoCopyTextLabel);
    }];
    [self.autoCopySelectedTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoCopyOCRTextButton);
        make.top.equalTo(self.autoCopyOCRTextButton.mas_bottom).offset(self.verticalPadding);
    }];
    
    [self.showQuickLinkLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.autoCopySelectedTextButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.showGoogleQuickLinkButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.showQuickLinkLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.showQuickLinkLabel);
    }];
    [self.showEudicQuickLinkButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.showGoogleQuickLinkButton);
        make.top.equalTo(self.showGoogleQuickLinkButton.mas_bottom).offset(self.verticalPadding);
    }];
    
    [self.disableEmptyCopyBeepLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.showEudicQuickLinkButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.disableEmptyCopyBeepButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.disableEmptyCopyBeepLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.disableEmptyCopyBeepLabel);
    }];
    
    
    [self.separatorView2 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.separatorView);
        make.top.equalTo(self.disableEmptyCopyBeepButton.mas_bottom).offset(1.5 * self.verticalPadding);
        make.height.equalTo(self.separatorView);
    }];
    
    [self.hideMainWindowLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.separatorView2.mas_bottom).offset(1.5 * self.verticalPadding);
    }];
    [self.hideMainWindowButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.hideMainWindowLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.hideMainWindowLabel);
    }];
    
    [self.launchLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.hideMainWindowButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.launchAtStartupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.launchLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.launchLabel);
    }];
    
    [self.menuBarIconLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.showQueryIconLabel);
        make.top.equalTo(self.launchAtStartupButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.hideMenuBarIconButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.menuBarIconLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.menuBarIconLabel);
    }];
    
    self.topmostView = self.inputLabel;
    self.bottommostView = self.hideMenuBarIconButton;
    
    if ([EZLanguageManager isChineseFirstLanguage]) {
        self.leftmostView = self.adjustQueryIconPostionLabel;
        self.rightmostView = self.showQueryIconButton;
    }
    
    if ([EZLanguageManager isEnglishFirstLanguage]) {
        self.leftmostView = self.adjustQueryIconPostionLabel;
        self.rightmostView = self.languageDetectOptimizePopUpButton;
    }
    
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

- (void)hideMainWindowButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.hideMainWindow = sender.mm_isOn;
    
    [[EZWindowManager shared] showOrHideDockAppAndMainWindow];
}

- (void)autoQueryOCRTextButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.autoQueryOCRText = sender.mm_isOn;
}

- (void)autoQuerySelectedTextButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.autoQuerySelectedText = sender.mm_isOn;
}

- (void)autoPlayAudioButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.autoPlayAudio = sender.mm_isOn;
}

- (void)autoCopySelectedTextButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.autoCopySelectedText = sender.mm_isOn;
}

- (void)autoCopyOCRTextButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.autoCopyOCRText = sender.mm_isOn;
}

- (void)showGoogleQuickLinkButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.showGoogleQuickLink = sender.mm_isOn;
}

- (void)showEudicQuickLinkButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.showEudicQuickLink = sender.mm_isOn;
}

- (void)hideMenuBarIconButtonClicked:(NSButton *)sender {
    // !!!: EZFloatingWindowLevel shouldn't be higher than kCGModalPanelWindowLevel (8)
    if (sender.mm_isOn) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"ok", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"cancel", nil)];
        alert.messageText = NSLocalizedString(@"hide_menu_bar_icon_info", nil);
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            // ok, hide icon
            if (returnCode == NSAlertFirstButtonReturn) {
                sender.mm_isOn = YES;
            } else {
                sender.mm_isOn = NO;
            }
            EZConfiguration.shared.hideMenuBarIcon = sender.mm_isOn;
        }];
    } else {
        EZConfiguration.shared.hideMenuBarIcon = NO;
    }
}

- (void)fixedWindowPositionPopUpButtonClicked:(NSPopUpButton *)button {
    NSInteger selectedIndex = button.indexOfSelectedItem;
    EZConfiguration.shared.fixedWindowPosition = selectedIndex;
}

- (void)languageDetectOptimizePopUpButtonClicked:(NSPopUpButton *)button {
    NSInteger selectedIndex = button.indexOfSelectedItem;
    EZConfiguration.shared.languageDetectOptimize = selectedIndex;
}

- (void)adjustQueryIconPostionButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.adjustPopButtomOrigin = sender.mm_isOn;
}

- (void)disableEmptyCopyBeepButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.disableEmptyCopyBeep = sender.mm_isOn;
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
