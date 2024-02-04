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
#import "NSViewController+EZWindow.h"
#import "EZMenuItemManager.h"
#import "EZEnumTypes.h"
#import <KVOController/NSObject+FBKVOController.h>
#import "Easydict-Swift.h"

@interface EZSettingViewController () <NSComboBoxDelegate>

@property (nonatomic, strong) Configuration *config;

@property (nonatomic, strong) NSTextField *selectLabel;
@property (nonatomic, strong) NSTextField *inputLabel;
@property (nonatomic, strong) NSTextField *snipLabel;
@property (nonatomic, strong) NSTextField *showMiniLabel;
@property (nonatomic, strong) NSTextField *screenshotOCRLabel;

@property (nonatomic, strong) MASShortcutView *selectionShortcutView;
@property (nonatomic, strong) MASShortcutView *snipShortcutView;
@property (nonatomic, strong) MASShortcutView *inputShortcutView;
@property (nonatomic, strong) MASShortcutView *showMiniShortcutView;
@property (nonatomic, strong) MASShortcutView *screenshotOCRShortcutView;

@property (nonatomic, strong) NSView *separatorView;

@property (nonatomic, strong) MMOrderedDictionary<EZLanguage, NSString *> *allLanguageDict;

@property (nonatomic, strong) NSTextField *apperanceLabel;
@property (nonatomic, strong) NSPopUpButton *apperancePopUpButton;

@property (nonatomic, strong) NSTextField *firstLanguageLabel;
@property (nonatomic, strong) NSPopUpButton *firstLanguagePopUpButton;
@property (nonatomic, strong) NSTextField *secondLanguageLabel;
@property (nonatomic, strong) NSPopUpButton *secondLanguagePopUpButton;

@property (nonatomic, strong) NSTextField *autoGetSelectedTextLabel;
@property (nonatomic, strong) NSButton *showQueryIconButton;
@property (nonatomic, strong) NSButton *forceGetSelectedTextButton;

@property (nonatomic, strong) NSTextField *disableEmptyCopyBeepLabel;
@property (nonatomic, strong) NSButton *disableEmptyCopyBeepButton;

@property (nonatomic, strong) NSTextField *clickQueryLabel;
@property (nonatomic, strong) NSButton *clickQueryButton;

@property (nonatomic, strong) NSTextField *adjustQueryIconPostionLabel;
@property (nonatomic, strong) NSButton *adjustQueryIconPostionButton;

@property (nonatomic, strong) NSTextField *languageDetectLabel;
@property (nonatomic, strong) NSPopUpButton *languageDetectOptimizePopUpButton;

@property (nonatomic, strong) NSTextField *defaultTTSServiceLabel;
@property (nonatomic, strong) NSPopUpButton *defaultTTSServicePopUpButton;

@property (nonatomic, strong) NSTextField *mouseSelectTranslateWindowTypeLabel;
@property (nonatomic, strong) NSPopUpButton *mouseSelectTranslateWindowTypePopUpButton;

@property (nonatomic, strong) NSTextField *shortcutSelectTranslateWindowTypeLabel;
@property (nonatomic, strong) NSPopUpButton *shortcutSelectTranslateWindowTypePopUpButton;

@property (nonatomic, strong) NSTextField *fixedWindowPositionLabel;
@property (nonatomic, strong) NSPopUpButton *fixedWindowPositionPopUpButton;

@property (nonatomic, strong) NSTextField *playAudioLabel;
@property (nonatomic, strong) NSButton *autoPlayAudioButton;

@property (nonatomic, strong) NSTextField *inputFieldLabel;
@property (nonatomic, strong) NSButton *clearInputButton;
@property (nonatomic, strong) NSButton *keepPrevResultButton;
@property (nonatomic, strong) NSButton *selectQueryTextWhenWindowActivateButton;

@property (nonatomic, strong) NSTextField *autoQueryLabel;
@property (nonatomic, strong) NSButton *autoQueryOCRTextButton;
@property (nonatomic, strong) NSButton *autoQuerySelectedTextButton;
@property (nonatomic, strong) NSButton *autoQueryPastedTextButton;

@property (nonatomic, strong) NSTextField *autoCopyTextLabel;
@property (nonatomic, strong) NSButton *autoCopySelectedTextButton;
@property (nonatomic, strong) NSButton *autoCopyOCRTextButton;
@property (nonatomic, strong) NSButton *autoCopyFirstTranslatedTextButton;

@property (nonatomic, strong) NSTextField *showQuickLinkLabel;
@property (nonatomic, strong) NSButton *showGoogleQuickLinkButton;
@property (nonatomic, strong) NSButton *showEudicQuickLinkButton;
@property (nonatomic, strong) NSButton *showAppleDictionaryQuickLinkButton;

@property (nonatomic, strong) NSView *separatorView2;

@property (nonatomic, strong) NSTextField *hideMainWindowLabel;
@property (nonatomic, strong) NSButton *hideMainWindowButton;

@property (nonatomic, strong) NSTextField *launchLabel;
@property (nonatomic, strong) NSButton *launchAtStartupButton;

@property (nonatomic, strong) NSTextField *menuBarIconLabel;
@property (nonatomic, strong) NSButton *hideMenuBarIconButton;

@property (nonatomic, strong) NSTextField *betaNewAppLabel;
@property (nonatomic, strong) NSButton *enableBetaNewAppButton;

@property (nonatomic, strong) NSTextField *fontSizeLabel;
@property (nonatomic, strong) ChangeFontSizeView *changeFontSizeView;
@property (nonatomic, strong) FontSizeHintView *fontSizeHintView;

@property (nonatomic, strong) NSArray<NSString *> *enabledTTSServiceTypes;

@end


@implementation EZSettingViewController

- (MMOrderedDictionary<EZLanguage, NSString *> *)allLanguageDict {
    if (!_allLanguageDict) {
        MMOrderedDictionary *languageDict = [[MMOrderedDictionary alloc] init];
        for (EZLanguage language in EZLanguageManager.shared.allLanguages) {
            NSArray *disableLanguages = @[
                EZLanguageAuto,
                EZLanguageClassicalChinese,
            ];
            if (![disableLanguages containsObject:language]) {
                NSString *showingLanguageName = [EZLanguageManager.shared showingLanguageNameWithFlag:language];
                [languageDict setObject:showingLanguageName forKey:language];
            }
        }
        _allLanguageDict = languageDict;
    }
    return _allLanguageDict;
}

- (NSArray<NSString *> *)enabledTTSServiceTypes {
    if (!_enabledTTSServiceTypes) {
        // Note: Bing API has frequency limit
        _enabledTTSServiceTypes = @[
            EZServiceTypeYoudao,
            EZServiceTypeBing,
            EZServiceTypeGoogle,
            EZServiceTypeBaidu,
            EZServiceTypeApple,
        ];
    }
    return _enabledTTSServiceTypes;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

    self.config = [Configuration shared];

    [self setupUI];

    self.leftMargin = 110;
    self.rightMargin = 100;
    self.maxViewHeightRatio = 0.7;

    [self updateViewSize];

    // Observe selectionShortcutView.recording status.
    [self.KVOController observe:self.selectionShortcutView keyPath:@"recording" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(EZSettingViewController *settingVC, MASShortcutView *selectionShortcutView, NSDictionary<NSString *, id> *_Nonnull change) {
        Configuration.shared.isRecordingSelectTextShortcutKey = [change[NSKeyValueChangeNewKey] boolValue];
    }];
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

    if ([EZLanguageManager.shared isSystemEnglishFirstLanguage]) {
        self.leftmostView = self.showMiniLabel;
    }

    NSTextField *screenshotOCRLabel = [NSTextField labelWithString:NSLocalizedString(@"silent_screenshot_ocr", nil)];
    screenshotOCRLabel.font = font;
    [self.contentView addSubview:screenshotOCRLabel];
    self.screenshotOCRLabel = screenshotOCRLabel;
    self.screenshotOCRShortcutView = [[MASShortcutView alloc] init];
    [self.contentView addSubview:self.screenshotOCRShortcutView];


    [self.inputShortcutView setAssociatedUserDefaultsKey:EZInputShortcutKey];
    [self.snipShortcutView setAssociatedUserDefaultsKey:EZSnipShortcutKey];
    [self.selectionShortcutView setAssociatedUserDefaultsKey:EZSelectionShortcutKey];
    [self.showMiniShortcutView setAssociatedUserDefaultsKey:EZShowMiniShortcutKey];
    [self.screenshotOCRShortcutView setAssociatedUserDefaultsKey:EZScreenshotOCRShortcutKey];


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

    NSTextField *firstLanguageLabel = [NSTextField labelWithString:NSLocalizedString(@"first_language", nil)];
    firstLanguageLabel.font = font;
    [self.contentView addSubview:firstLanguageLabel];
    self.firstLanguageLabel = firstLanguageLabel;

    self.firstLanguagePopUpButton = [[NSPopUpButton alloc] init];
    [self.contentView addSubview:self.firstLanguagePopUpButton];
    [self.firstLanguagePopUpButton addItemsWithTitles:[self.allLanguageDict sortedValues]];
    self.firstLanguagePopUpButton.target = self;
    self.firstLanguagePopUpButton.action = @selector(firstLangaugePopUpButtonClicked:);

    NSTextField *apperanceLabel = [NSTextField labelWithString:NSLocalizedString(@"app_appearance", nil)];
    apperanceLabel.font = font;
    [self.contentView addSubview:apperanceLabel];
    self.apperanceLabel = apperanceLabel;
    
    self.apperancePopUpButton = [[NSPopUpButton alloc] init];
    [self.contentView addSubview:self.apperancePopUpButton];
    [self.apperancePopUpButton addItemsWithTitles:[AppearenceHelper shared].titles];
    [self.apperancePopUpButton selectItemAtIndex:self.config.appearance];
    self.apperancePopUpButton.target = self;
    self.apperancePopUpButton.action = @selector(appearancePopUpButtonClicked:);
    
    NSTextField *secondLanguageLabel = [NSTextField labelWithString:NSLocalizedString(@"second_language", nil)];
    secondLanguageLabel.font = font;
    [self.contentView addSubview:secondLanguageLabel];
    self.secondLanguageLabel = secondLanguageLabel;

    self.secondLanguagePopUpButton = [[NSPopUpButton alloc] init];
    [self.contentView addSubview:self.secondLanguagePopUpButton];
    [self.secondLanguagePopUpButton addItemsWithTitles:[self.allLanguageDict sortedValues]];
    self.secondLanguagePopUpButton.target = self;
    self.secondLanguagePopUpButton.action = @selector(secondLangaugePopUpButtonClicked:);


    NSTextField *showQueryIconLabel = [NSTextField labelWithString:NSLocalizedString(@"auto_get_selected_text", nil)];
    showQueryIconLabel.font = font;
    [self.contentView addSubview:showQueryIconLabel];
    self.autoGetSelectedTextLabel = showQueryIconLabel;

    NSString *showQueryIconTitle = NSLocalizedString(@"auto_show_query_icon", nil);
    self.showQueryIconButton = [NSButton checkboxWithTitle:showQueryIconTitle target:self action:@selector(autoSelectTextButtonClicked:)];
    [self.contentView addSubview:self.showQueryIconButton];

    NSString *forceGetSelectedText = NSLocalizedString(@"force_auto_get_selected_text", nil);
    self.forceGetSelectedTextButton = [NSButton checkboxWithTitle:forceGetSelectedText target:self action:@selector(forceGetSelectedTextButtonClicked:)];
    [self.contentView addSubview:self.forceGetSelectedTextButton];


    NSTextField *disableEmptyCopyBeepLabel = [NSTextField labelWithString:NSLocalizedString(@"disable_empty_copy_beep", nil)];
    disableEmptyCopyBeepLabel.font = font;
    [self.contentView addSubview:disableEmptyCopyBeepLabel];
    self.disableEmptyCopyBeepLabel = disableEmptyCopyBeepLabel;

    NSString *disableEmptyCopyBeepTitle = NSLocalizedString(@"disable_empty_copy_beep_msg", nil);
    self.disableEmptyCopyBeepButton = [NSButton checkboxWithTitle:disableEmptyCopyBeepTitle target:self action:@selector(disableEmptyCopyBeepButtonClicked:)];
    [self.contentView addSubview:self.disableEmptyCopyBeepButton];

    NSTextField *clickQueryLabel = [NSTextField labelWithString:NSLocalizedString(@"click_icon_query", nil)];
    clickQueryLabel.font = font;
    [self.contentView addSubview:clickQueryLabel];
    self.clickQueryLabel = clickQueryLabel;

    NSString *clickQueryTitle = NSLocalizedString(@"click_icon_query_info", nil);
    self.clickQueryButton = [NSButton checkboxWithTitle:clickQueryTitle target:self action:@selector(clickQueryButtonClicked:)];
    [self.contentView addSubview:self.clickQueryButton];


    NSTextField *adjustQueryIconPostionLabel = [NSTextField labelWithString:NSLocalizedString(@"adjust_pop_button_origin", nil)];
    adjustQueryIconPostionLabel.font = font;
    [self.contentView addSubview:adjustQueryIconPostionLabel];
    self.adjustQueryIconPostionLabel = adjustQueryIconPostionLabel;

    NSString *adjustQueryIconPostionTitle = NSLocalizedString(@"avoid_conflict_with_PopClip_display", nil);
    self.adjustQueryIconPostionButton = [NSButton checkboxWithTitle:adjustQueryIconPostionTitle target:self action:@selector(adjustQueryIconPostionButtonClicked:)];
    [self.contentView addSubview:self.adjustQueryIconPostionButton];

    // language detect
    NSTextField *usesLanguageCorrectionLabel = [NSTextField labelWithString:NSLocalizedString(@"language_detect_optimize", nil)];
    usesLanguageCorrectionLabel.font = font;
    [self.contentView addSubview:usesLanguageCorrectionLabel];
    self.languageDetectLabel = usesLanguageCorrectionLabel;
    self.languageDetectOptimizePopUpButton = [[NSPopUpButton alloc] init];
    [self.contentView addSubview:self.languageDetectOptimizePopUpButton];

    NSArray *languageDetectOptimizeItems = @[
        NSLocalizedString(@"language_detect_optimize_none", nil),
        NSLocalizedString(@"language_detect_optimize_baidu", nil),
        NSLocalizedString(@"language_detect_optimize_google", nil),
    ];
    [self.languageDetectOptimizePopUpButton addItemsWithTitles:languageDetectOptimizeItems];
    self.languageDetectOptimizePopUpButton.target = self;
    self.languageDetectOptimizePopUpButton.action = @selector(languageDetectOptimizePopUpButtonClicked:);

    // default tts service
    NSTextField *defaultTTSServiceLabel = [NSTextField labelWithString:NSLocalizedString(@"default_tts_service", nil)];
    defaultTTSServiceLabel.font = font;
    [self.contentView addSubview:defaultTTSServiceLabel];
    self.defaultTTSServiceLabel = defaultTTSServiceLabel;

    self.defaultTTSServicePopUpButton = [[NSPopUpButton alloc] init];
    [self.contentView addSubview:self.defaultTTSServicePopUpButton];

    NSMutableArray *localizedTTSTitles = [NSMutableArray array];
    for (NSString *ttsType in self.enabledTTSServiceTypes) {
        NSString *localizedTitle = NSLocalizedString(ttsType, nil);
        [localizedTTSTitles addObject:localizedTitle];
    }

    [self.defaultTTSServicePopUpButton addItemsWithTitles:localizedTTSTitles];
    self.defaultTTSServicePopUpButton.target = self;
    self.defaultTTSServicePopUpButton.action = @selector(defaultTTSServicePopUpButtonClicked:);

    NSTextField *mouseSelectTranslateWindowTypeLabel = [NSTextField labelWithString:NSLocalizedString(@"mouse_select_translate_window_type", nil)];
    mouseSelectTranslateWindowTypeLabel.font = font;
    [self.contentView addSubview:mouseSelectTranslateWindowTypeLabel];
    self.mouseSelectTranslateWindowTypeLabel = mouseSelectTranslateWindowTypeLabel;

    self.mouseSelectTranslateWindowTypePopUpButton = [[NSPopUpButton alloc] init];
    [self.contentView addSubview:self.mouseSelectTranslateWindowTypePopUpButton];
    MMOrderedDictionary *mouseSelectTranslateWindowTypeDict = [EZEnumTypes translateWindowTypeDict];
    NSArray *mouseSelectTranslateWindowTypeItems = [mouseSelectTranslateWindowTypeDict sortedValues];
    [self.mouseSelectTranslateWindowTypePopUpButton addItemsWithTitles:mouseSelectTranslateWindowTypeItems];
    self.mouseSelectTranslateWindowTypePopUpButton.target = self;
    self.mouseSelectTranslateWindowTypePopUpButton.action = @selector(mouseSelectTranslateWindowTypePopUpButtonClicked:);

    NSTextField *shortcutSelectTranslateWindowTypeLabel = [NSTextField labelWithString:NSLocalizedString(@"shortcut_select_translate_window_type", nil)];
    shortcutSelectTranslateWindowTypeLabel.font = font;
    [self.contentView addSubview:shortcutSelectTranslateWindowTypeLabel];
    self.shortcutSelectTranslateWindowTypeLabel = shortcutSelectTranslateWindowTypeLabel;

    self.shortcutSelectTranslateWindowTypePopUpButton = [[NSPopUpButton alloc] init];
    [self.contentView addSubview:self.shortcutSelectTranslateWindowTypePopUpButton];
    MMOrderedDictionary *shortcutSelectTranslateWindowTypeDict = [EZEnumTypes translateWindowTypeDict];
    NSArray *shortcutSelectTranslateWindowTypeItems = [shortcutSelectTranslateWindowTypeDict sortedValues];
    [self.shortcutSelectTranslateWindowTypePopUpButton addItemsWithTitles:shortcutSelectTranslateWindowTypeItems];
    self.shortcutSelectTranslateWindowTypePopUpButton.target = self;
    self.shortcutSelectTranslateWindowTypePopUpButton.action = @selector(shortcutSelectTranslateWindowTypePopUpButtonClicked:);


    NSTextField *fixedWindowPositionLabel = [NSTextField labelWithString:NSLocalizedString(@"fixed_window_position", nil)];
    fixedWindowPositionLabel.font = font;
    [self.contentView addSubview:fixedWindowPositionLabel];
    self.fixedWindowPositionLabel = fixedWindowPositionLabel;

    self.fixedWindowPositionPopUpButton = [[NSPopUpButton alloc] init];
    [self.contentView addSubview:self.fixedWindowPositionPopUpButton];
    MMOrderedDictionary *fixedWindowPostionDict = [EZEnumTypes fixedWindowPositionDict];
    NSArray *fixedWindowPositionItems = [fixedWindowPostionDict sortedValues];
    [self.fixedWindowPositionPopUpButton addItemsWithTitles:fixedWindowPositionItems];
    self.fixedWindowPositionPopUpButton.target = self;
    self.fixedWindowPositionPopUpButton.action = @selector(fixedWindowPositionPopUpButtonClicked:);


    NSTextField *playAudioLabel = [NSTextField labelWithString:NSLocalizedString(@"play_word_audio", nil)];
    playAudioLabel.font = font;
    [self.contentView addSubview:playAudioLabel];
    self.playAudioLabel = playAudioLabel;

    NSString *autoPlayAudioTitle = NSLocalizedString(@"auto_play_word_audio", nil);
    self.autoPlayAudioButton = [NSButton checkboxWithTitle:autoPlayAudioTitle target:self action:@selector(autoPlayAudioButtonClicked:)];
    [self.contentView addSubview:self.autoPlayAudioButton];

    NSString *inputFieldLabelTitle = [NSString stringWithFormat:@"%@:", NSLocalizedString(@"setting.general.input.header", nil)];
    NSTextField *inputFieldLabel = [NSTextField labelWithString:inputFieldLabelTitle];
    inputFieldLabel.font = font;
    [self.contentView addSubview:inputFieldLabel];
    self.inputFieldLabel = inputFieldLabel;

    NSString *clearInputTitle = NSLocalizedString(@"clear_input_when_translating", nil);
    self.clearInputButton = [NSButton checkboxWithTitle:clearInputTitle target:self action:@selector(clearInputButtonClicked:)];
    [self.contentView addSubview:self.clearInputButton];
    
    NSString *keepPrevResultTitle = NSLocalizedString(@"keep_prev_result_when_selected_text_is_empty", nil);
    self.keepPrevResultButton = [NSButton checkboxWithTitle:keepPrevResultTitle target:self action:@selector(keepPrevResultButtonClicked:)];
    [self.contentView addSubview:self.keepPrevResultButton];
    
    NSString *selectQueryTextWhenWindowActivateTitle = NSLocalizedString(@"select_query_text_when_window_activate", nil);
    self.selectQueryTextWhenWindowActivateButton = [NSButton checkboxWithTitle:selectQueryTextWhenWindowActivateTitle target:self action:@selector(selectQueryTextWhenWindowActivateButtonClicked:)];
    [self.contentView addSubview:self.selectQueryTextWhenWindowActivateButton];

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

    NSString *autoQueryPastedTextButton = NSLocalizedString(@"auto_query_pasted_text", nil);
    self.autoQueryPastedTextButton = [NSButton checkboxWithTitle:autoQueryPastedTextButton target:self action:@selector(autoQueryPastedTextButtonClicked:)];
    [self.contentView addSubview:self.autoQueryPastedTextButton];


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

    NSString *autoCopyFirstTranslatedText = NSLocalizedString(@"auto_copy_first_translated_text", nil);
    self.autoCopyFirstTranslatedTextButton = [NSButton checkboxWithTitle:autoCopyFirstTranslatedText target:self action:@selector(autoCopyFirstTranslatedTextButtonClicked:)];
    [self.contentView addSubview:self.autoCopyFirstTranslatedTextButton];


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

    NSString *showAppleDictionaryQuickLink = NSLocalizedString(@"show_apple_dictionary_quick_link", nil);
    self.showAppleDictionaryQuickLinkButton = [NSButton checkboxWithTitle:showAppleDictionaryQuickLink target:self action:@selector(showAppleDictionaryQuickLinkButtonClicked:)];
    [self.contentView addSubview:self.showAppleDictionaryQuickLinkButton];


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

    if (@available(macOS 13.0, *)) {
        NSTextField *betaNewAppLabel = [NSTextField labelWithString:NSLocalizedString(@"beta_new_app", nil)];
        betaNewAppLabel.font = font;
        [self.contentView addSubview:betaNewAppLabel];
        self.betaNewAppLabel = betaNewAppLabel;
        
        NSString *enableBetaNewApp = NSLocalizedString(@"enable_beta_new_app", nil);
        self.enableBetaNewAppButton = [NSButton checkboxWithTitle:enableBetaNewApp target:self action:@selector(enableBetaNewAppButtonClicked:)];
        [self.contentView addSubview:self.enableBetaNewAppButton];
    }
    
    NSTextField *fontSizeLabel = [NSTextField labelWithString:NSLocalizedString(@"font_size", nil)];
    fontSizeLabel.font = font;
    [self.contentView addSubview:fontSizeLabel];
    self.fontSizeLabel = fontSizeLabel;

    ChangeFontSizeView *changeFontSizeView = [[ChangeFontSizeView alloc] initWithFontSizes:self.config.fontSizes initialIndex:self.config.fontSizeIndex];

    mm_weakify(self);
    changeFontSizeView.didSelectIndex = ^(NSInteger index) {
        mm_strongify(self);
        self.config.fontSizeIndex = index;
    };

    [self.contentView addSubview:changeFontSizeView];
    self.changeFontSizeView = changeFontSizeView;

    self.fontSizeHintView = [FontSizeHintView new];
    [self.contentView addSubview:self.fontSizeHintView];

    [self updatePreferredLanguagesPopUpButton];

    self.showQueryIconButton.mm_isOn = self.config.autoSelectText;
    self.forceGetSelectedTextButton.mm_isOn = self.config.forceAutoGetSelectedText;
    self.disableEmptyCopyBeepButton.mm_isOn = self.config.disableEmptyCopyBeep;
    self.clickQueryButton.mm_isOn = self.config.clickQuery;
    self.adjustQueryIconPostionButton.mm_isOn = self.config.adjustPopButtomOrigin;
    [self.languageDetectOptimizePopUpButton selectItemAtIndex:self.config.languageDetectOptimize];
    [self.defaultTTSServicePopUpButton selectItemWithTitle:NSLocalizedString(self.config.defaultTTSServiceType, nil)];

    MMOrderedDictionary *translateWindowTypeDict = [EZEnumTypes translateWindowTypeDict];
    NSString *mouseWindowTitle = [translateWindowTypeDict objectForKey:@(self.config.mouseSelectTranslateWindowType)];
    NSString *shortcutWindowTitle = [translateWindowTypeDict objectForKey:@(self.config.shortcutSelectTranslateWindowType)];

    [self.mouseSelectTranslateWindowTypePopUpButton selectItemWithTitle:mouseWindowTitle];
    [self.shortcutSelectTranslateWindowTypePopUpButton selectItemWithTitle:shortcutWindowTitle];

    [self.fixedWindowPositionPopUpButton selectItemAtIndex:self.config.fixedWindowPosition];

    self.autoPlayAudioButton.mm_isOn = self.config.autoPlayAudio;
    self.clearInputButton.mm_isOn = self.config.clearInput;
    self.keepPrevResultButton.mm_isOn = self.config.keepPrevResultWhenEmpty;
    self.selectQueryTextWhenWindowActivateButton.mm_isOn = self.config.selectQueryTextWhenWindowActivate;
    self.launchAtStartupButton.mm_isOn = self.config.launchAtStartup;
    self.hideMainWindowButton.mm_isOn = self.config.hideMainWindow;
    self.autoQueryOCRTextButton.mm_isOn = self.config.autoQueryOCRText;
    self.autoQuerySelectedTextButton.mm_isOn = self.config.autoQuerySelectedText;
    self.autoQueryPastedTextButton.mm_isOn = self.config.autoQueryPastedText;
    self.autoCopySelectedTextButton.mm_isOn = self.config.autoCopySelectedText;
    self.autoCopyOCRTextButton.mm_isOn = self.config.autoCopyOCRText;
    self.autoCopyFirstTranslatedTextButton.mm_isOn = self.config.autoCopyFirstTranslatedText;
    self.showGoogleQuickLinkButton.mm_isOn = self.config.showGoogleQuickLink;
    self.showEudicQuickLinkButton.mm_isOn = self.config.showEudicQuickLink;
    self.showAppleDictionaryQuickLinkButton.mm_isOn = self.config.showAppleDictionaryQuickLink;
    self.hideMenuBarIconButton.mm_isOn = self.config.hideMenuBarIcon;
    if (@available(macOS 13.0, *)) {
        self.enableBetaNewAppButton.mm_isOn = self.config.enableBetaNewApp;
    }
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

    [self.screenshotOCRLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.showMiniShortcutView.mas_bottom).offset(self.verticalPadding);
    }];
    [self.screenshotOCRShortcutView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.screenshotOCRLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.screenshotOCRLabel);
        make.height.equalTo(self.selectionShortcutView);
    }];


    [self.separatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.inset(separatorMargin);
        make.top.equalTo(self.screenshotOCRLabel.mas_bottom).offset(1.5 * self.verticalPadding);
        make.height.mas_equalTo(1);
    }];
    
    [self.apperanceLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.separatorView.mas_bottom).offset(1.5 * self.verticalPadding);
    }];
    [self.apperancePopUpButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.apperanceLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.apperanceLabel);
    }];
    
    [self.firstLanguageLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.apperanceLabel.mas_bottom).offset(self.verticalPadding);
    }];
    [self.firstLanguagePopUpButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.firstLanguageLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.firstLanguageLabel);
    }];

    [self.secondLanguageLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.firstLanguagePopUpButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.secondLanguagePopUpButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.secondLanguageLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.secondLanguageLabel);
    }];

    [self.autoGetSelectedTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.selectLabel);
        make.top.equalTo(self.secondLanguagePopUpButton.mas_bottom).offset(1.5 * self.verticalPadding);
    }];
    [self.showQueryIconButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoGetSelectedTextLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.autoGetSelectedTextLabel);
    }];
    [self.forceGetSelectedTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.showQueryIconButton);
        make.top.equalTo(self.showQueryIconButton.mas_bottom).offset(self.verticalPadding);
    }];

    [self.disableEmptyCopyBeepLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.forceGetSelectedTextButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.disableEmptyCopyBeepButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.disableEmptyCopyBeepLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.disableEmptyCopyBeepLabel);
    }];

    [self.clickQueryLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.disableEmptyCopyBeepButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.clickQueryButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.clickQueryLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.clickQueryLabel);
    }];


    [self.adjustQueryIconPostionLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.clickQueryLabel);
        make.top.equalTo(self.clickQueryButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.adjustQueryIconPostionButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.adjustQueryIconPostionLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.adjustQueryIconPostionLabel);
    }];

    [self.languageDetectLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.adjustQueryIconPostionButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.languageDetectOptimizePopUpButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.languageDetectLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.languageDetectLabel);
    }];

    [self.defaultTTSServiceLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.languageDetectOptimizePopUpButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.defaultTTSServicePopUpButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.defaultTTSServiceLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.defaultTTSServiceLabel);
    }];


    [self.mouseSelectTranslateWindowTypeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.defaultTTSServicePopUpButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.mouseSelectTranslateWindowTypePopUpButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mouseSelectTranslateWindowTypeLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.mouseSelectTranslateWindowTypeLabel);
    }];

    [self.shortcutSelectTranslateWindowTypeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.mouseSelectTranslateWindowTypePopUpButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.shortcutSelectTranslateWindowTypePopUpButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.shortcutSelectTranslateWindowTypeLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.shortcutSelectTranslateWindowTypeLabel);
    }];

    [self.fixedWindowPositionLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.shortcutSelectTranslateWindowTypePopUpButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.fixedWindowPositionPopUpButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.fixedWindowPositionLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.fixedWindowPositionLabel);
    }];

    [self.playAudioLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.fixedWindowPositionPopUpButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.autoPlayAudioButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playAudioLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.playAudioLabel);
    }];


    [self.inputFieldLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.autoPlayAudioButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.clearInputButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.inputFieldLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.inputFieldLabel);
    }];
    [self.keepPrevResultButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.clearInputButton);
        make.top.equalTo(self.clearInputButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.selectQueryTextWhenWindowActivateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.clearInputButton);
        make.top.equalTo(self.keepPrevResultButton.mas_bottom).offset(self.verticalPadding);
    }];

    [self.autoQueryLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.selectQueryTextWhenWindowActivateButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.autoQueryOCRTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoQueryLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.autoQueryLabel);
    }];
    [self.autoQuerySelectedTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoQueryOCRTextButton);
        make.top.equalTo(self.autoQueryOCRTextButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.autoQueryPastedTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoQuerySelectedTextButton);
        make.top.equalTo(self.autoQuerySelectedTextButton.mas_bottom).offset(self.verticalPadding);
    }];


    [self.autoCopyTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.autoQueryPastedTextButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.autoCopyOCRTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoQueryOCRTextButton);
        make.centerY.equalTo(self.autoCopyTextLabel);
    }];
    [self.autoCopySelectedTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoCopyOCRTextButton);
        make.top.equalTo(self.autoCopyOCRTextButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.autoCopyFirstTranslatedTextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.autoCopySelectedTextButton);
        make.top.equalTo(self.autoCopySelectedTextButton.mas_bottom).offset(self.verticalPadding);
    }];


    [self.showQuickLinkLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.autoCopyFirstTranslatedTextButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.showGoogleQuickLinkButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.showQuickLinkLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.showQuickLinkLabel);
    }];
    [self.showEudicQuickLinkButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.showGoogleQuickLinkButton);
        make.top.equalTo(self.showGoogleQuickLinkButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.showAppleDictionaryQuickLinkButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.showEudicQuickLinkButton);
        make.top.equalTo(self.showEudicQuickLinkButton.mas_bottom).offset(self.verticalPadding);
    }];

    [self.fontSizeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.showAppleDictionaryQuickLinkButton.mas_bottom).offset(20);
        make.top.equalTo(self.showAppleDictionaryQuickLinkButton.mas_bottom).offset(20);
    }];

    CGFloat changeFontSizeViewWidth = 220;
    [self.changeFontSizeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.fontSizeLabel.mas_right).offset(self.horizontalPadding + 2);
        make.centerY.equalTo(self.fontSizeLabel);
        make.width.mas_equalTo(changeFontSizeViewWidth);
        make.width.mas_equalTo(changeFontSizeViewWidth);
        make.height.mas_equalTo(30);
    }];

    [self.fontSizeHintView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.fontSizeLabel.mas_right).offset(self.horizontalPadding);
        make.top.equalTo(self.changeFontSizeView.mas_bottom).mas_offset(8);
        make.width.mas_equalTo(changeFontSizeViewWidth + 5);
        make.height.mas_equalTo(45);
        make.top.equalTo(self.changeFontSizeView.mas_bottom).mas_offset(8);
        make.width.mas_equalTo(changeFontSizeViewWidth + 5);
        make.height.mas_equalTo(45);
    }];

    [self.separatorView2 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.separatorView);
        make.top.equalTo(self.fontSizeHintView.mas_bottom).offset(1.5 * self.verticalPadding);
        make.height.equalTo(self.separatorView);
    }];

    [self.hideMainWindowLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.separatorView2.mas_bottom).offset(1.5 * self.verticalPadding);
    }];
    [self.hideMainWindowButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.hideMainWindowLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.hideMainWindowLabel);
    }];

    [self.launchLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.hideMainWindowButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.launchAtStartupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.launchLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.launchLabel);
    }];

    [self.menuBarIconLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.autoGetSelectedTextLabel);
        make.top.equalTo(self.launchAtStartupButton.mas_bottom).offset(self.verticalPadding);
    }];
    [self.hideMenuBarIconButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.menuBarIconLabel.mas_right).offset(self.horizontalPadding);
        make.centerY.equalTo(self.menuBarIconLabel);
    }];
    
    if (@available(macOS 13.0, *)) {
        [self.betaNewAppLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.autoGetSelectedTextLabel);
            make.top.equalTo(self.hideMenuBarIconButton.mas_bottom).offset(self.verticalPadding);
        }];
        [self.enableBetaNewAppButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.betaNewAppLabel.mas_right).offset(self.horizontalPadding);
            make.centerY.equalTo(self.betaNewAppLabel);
        }];
        self.bottommostView = self.enableBetaNewAppButton;
    } else {
        self.bottommostView = self.hideMenuBarIconButton;
    }

    self.topmostView = self.inputLabel;
    
    if ([EZLanguageManager.shared isSystemChineseFirstLanguage]) {
        self.leftmostView = self.adjustQueryIconPostionLabel;
        self.rightmostView = self.forceGetSelectedTextButton;
    }

    if ([EZLanguageManager.shared isSystemEnglishFirstLanguage]) {
        self.leftmostView = self.adjustQueryIconPostionLabel;
        self.rightmostView = self.forceGetSelectedTextButton;
    }

    [super updateViewConstraints];
}

#pragma mark - event

- (BOOL)checkAppIsTrusted {
    BOOL isTrusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef) @{(__bridge NSString *)kAXTrustedCheckOptionPrompt : @YES});
    NSLog(@"isTrusted: %d", isTrusted);

    return isTrusted == YES;
}

- (void)autoSelectTextButtonClicked:(NSButton *)sender {
    self.config.autoSelectText = sender.mm_isOn;

    if (sender.mm_isOn) {
        [self checkAppIsTrusted];
    }
}

- (void)forceGetSelectedTextButtonClicked:(NSButton *)sender {
    if (sender.mm_isOn) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"ok", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"cancel", nil)];
        alert.messageText = NSLocalizedString(@"force_auto_get_selected_text_title", nil);
        alert.informativeText = NSLocalizedString(@"force_auto_get_selected_text_msg", nil);
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                sender.mm_isOn = YES;
            } else {
                sender.mm_isOn = NO;
            }
            self.config.forceAutoGetSelectedText = sender.mm_isOn;
        }];
    } else {
        self.config.forceAutoGetSelectedText = NO;
    }
}

- (void)clickQueryButtonClicked:(NSButton *)sender {
    self.config.clickQuery = sender.mm_isOn;
}


- (void)launchAtStartupButtonClicked:(NSButton *)sender {
    self.config.launchAtStartup = sender.mm_isOn;
}

- (void)hideMainWindowButtonClicked:(NSButton *)sender {
    self.config.hideMainWindow = sender.mm_isOn;
}

- (void)autoQueryOCRTextButtonClicked:(NSButton *)sender {
    self.config.autoQueryOCRText = sender.mm_isOn;
}

- (void)autoQuerySelectedTextButtonClicked:(NSButton *)sender {
    self.config.autoQuerySelectedText = sender.mm_isOn;
}

- (void)autoQueryPastedTextButtonClicked:(NSButton *)sender {
    self.config.autoQueryPastedText = sender.mm_isOn;
}

- (void)autoPlayAudioButtonClicked:(NSButton *)sender {
    self.config.autoPlayAudio = sender.mm_isOn;
}

- (void)clearInputButtonClicked:(NSButton *)sender {
    self.config.clearInput = sender.mm_isOn;
}

- (void)keepPrevResultButtonClicked:(NSButton *)sender {
    self.config.keepPrevResultWhenEmpty = sender.mm_isOn;
}

- (void)selectQueryTextWhenWindowActivateButtonClicked:(NSButton *)sender {
    self.config.selectQueryTextWhenWindowActivate = sender.mm_isOn;
}

- (void)autoCopySelectedTextButtonClicked:(NSButton *)sender {
    self.config.autoCopySelectedText = sender.mm_isOn;
}

- (void)autoCopyOCRTextButtonClicked:(NSButton *)sender {
    self.config.autoCopyOCRText = sender.mm_isOn;
}

- (void)autoCopyFirstTranslatedTextButtonClicked:(NSButton *)sender {
    self.config.autoCopyFirstTranslatedText = sender.mm_isOn;
}

- (void)showGoogleQuickLinkButtonClicked:(NSButton *)sender {
    self.config.showGoogleQuickLink = sender.mm_isOn;
}

- (void)showEudicQuickLinkButtonClicked:(NSButton *)sender {
    self.config.showEudicQuickLink = sender.mm_isOn;
}

- (void)showAppleDictionaryQuickLinkButtonClicked:(NSButton *)sender {
    self.config.showAppleDictionaryQuickLink = sender.mm_isOn;
}


- (void)hideMenuBarIconButtonClicked:(NSButton *)sender {
    // !!!: EZFloatingWindowLevel shouldn't be higher than kCGModalPanelWindowLevel (8)
    if (sender.mm_isOn) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"ok", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"cancel", nil)];
        alert.messageText = NSLocalizedString(@"hide_menu_bar_icon", nil);
        alert.informativeText = NSLocalizedString(@"hide_menu_bar_icon_msg", nil);
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            // ok, hide icon
            if (returnCode == NSAlertFirstButtonReturn) {
                sender.mm_isOn = YES;
            } else {
                sender.mm_isOn = NO;
            }
            self.config.hideMenuBarIcon = sender.mm_isOn;
        }];
    } else {
        self.config.hideMenuBarIcon = NO;
    }
}

- (void)enableBetaNewAppButtonClicked:(NSButton *)sender {
    self.config.enableBetaNewApp = sender.mm_isOn;
}

- (void)mouseSelectTranslateWindowTypePopUpButtonClicked:(NSPopUpButton *)button {
    NSInteger selectedIndex = button.indexOfSelectedItem;
    MMOrderedDictionary *translateWindowTypeDict = [EZEnumTypes translateWindowTypeDict];
    self.config.mouseSelectTranslateWindowType = [[translateWindowTypeDict keyAtIndex:selectedIndex] integerValue];
}

- (void)shortcutSelectTranslateWindowTypePopUpButtonClicked:(NSPopUpButton *)button {
    NSInteger selectedIndex = button.indexOfSelectedItem;
    MMOrderedDictionary *translateWindowTypeDict = [EZEnumTypes translateWindowTypeDict];
    self.config.shortcutSelectTranslateWindowType = [[translateWindowTypeDict keyAtIndex:selectedIndex] integerValue];
}

- (void)fixedWindowPositionPopUpButtonClicked:(NSPopUpButton *)button {
    NSInteger selectedIndex = button.indexOfSelectedItem;
    self.config.fixedWindowPosition = selectedIndex;
}

- (void)languageDetectOptimizePopUpButtonClicked:(NSPopUpButton *)button {
    NSInteger selectedIndex = button.indexOfSelectedItem;
    self.config.languageDetectOptimize = selectedIndex;
}

- (void)defaultTTSServicePopUpButtonClicked:(NSPopUpButton *)button {
    NSInteger selectedIndex = button.indexOfSelectedItem;
    self.config.defaultTTSServiceType = self.enabledTTSServiceTypes[selectedIndex];
}

- (void)adjustQueryIconPostionButtonClicked:(NSButton *)sender {
    self.config.adjustPopButtomOrigin = sender.mm_isOn;
}

- (void)disableEmptyCopyBeepButtonClicked:(NSButton *)sender {
    self.config.disableEmptyCopyBeep = sender.mm_isOn;
}

#pragma mark - Preferred Languages

- (void)firstLangaugePopUpButtonClicked:(NSPopUpButton *)button {
    NSInteger selectedIndex = button.indexOfSelectedItem;
    EZLanguage language = self.allLanguageDict.sortedKeys[selectedIndex];
    self.config.firstLanguage = language;

    [self checkIfEqualFirstLanguage:YES];
}
- (void)secondLangaugePopUpButtonClicked:(NSPopUpButton *)button {
    NSInteger selectedIndex = button.indexOfSelectedItem;
    EZLanguage language = self.allLanguageDict.sortedKeys[selectedIndex];
    self.config.secondLanguage = language;

    [self checkIfEqualFirstLanguage:NO];
}

- (void)checkIfEqualFirstLanguage:(BOOL)fistLanguageFlag {
    if ([self.config.firstLanguage isEqualToString:self.config.secondLanguage]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"ok", nil)];

        NSString *warningText = NSLocalizedString(@"equal_first_and_second_language", nil);
        NSString *showingLanguage = [EZLanguageManager.shared showingLanguageName:self.config.firstLanguage];
        alert.messageText = [NSString stringWithFormat:@"%@: %@", warningText, showingLanguage];
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                // If isFistLanguage is YES, means we need to auto correct second language according to first language.
                EZLanguage sourceLanguage = fistLanguageFlag ? self.config.firstLanguage : self.config.secondLanguage;
                EZLanguage autoTargetLanguage = [EZLanguageManager.shared userTargetLanguageWithSourceLanguage:sourceLanguage];

                if (fistLanguageFlag) {
                    self.config.secondLanguage = autoTargetLanguage;
                } else {
                    self.config.firstLanguage = autoTargetLanguage;
                }

                [self updatePreferredLanguagesPopUpButton];
            }
        }];
    }
}

- (void)updatePreferredLanguagesPopUpButton {
    NSInteger firstLanguageIndex = [self.allLanguageDict.sortedKeys indexOfObject:self.config.firstLanguage];
    [self.firstLanguagePopUpButton selectItemAtIndex:firstLanguageIndex];

    NSInteger secondLanguageIndex = [self.allLanguageDict.sortedKeys indexOfObject:self.config.secondLanguage];
    [self.secondLanguagePopUpButton selectItemAtIndex:secondLanguageIndex];
}

#pragma mark - Appearance
- (void)appearancePopUpButtonClicked:(NSPopUpButton *)button {
    NSInteger selectedIndex = button.indexOfSelectedItem;
    self.config.appearance = selectedIndex;
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"setting_general", nil);
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:@"toolbar_setting_general"];
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
