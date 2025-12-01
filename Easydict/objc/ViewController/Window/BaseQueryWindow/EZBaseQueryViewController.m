//
//  MainTabViewController.m
//  Easydict
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZBaseQueryViewController.h"
#import "EZDetectManager.h"
#import "EZQueryView.h"
#import "EZResultView.h"
#import "EZSelectLanguageCell.h"
#import <KVOController/KVOController.h>
#import "EZCoordinateUtils.h"
#import "EZServiceTypes.h"
#import "EZAudioPlayer.h"
#import "EZLog.h"
#import "EZLocalStorage.h"
#import "EZTableRowView.h"
#import "EZSchemeParser.h"
#import "EZBaiduTranslate.h"
#import "EZToast.h"
#import "DictionaryKit.h"
#import "EZEventMonitor.h"
#import "Easydict-Swift.h"

static NSString *const EZQueryViewId = @"EZQueryViewId";
static NSString *const EZSelectLanguageCellId = @"EZSelectLanguageCellId";
static NSString *const EZTableTipsCellId = @"EZTableTipsCellId";
static NSString *const EZResultViewId = @"EZResultViewId";

static NSString *const EZColumnId = @"EZColumnId";

static NSString *const kDCSActiveDictionariesChangedDistributedNotification = @"kDCSActiveDictionariesChangedDistributedNotification";

/// Execute block on main thread safely.
static void dispatch_block_on_main_safely(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@interface EZBaseQueryViewController () <NSTableViewDelegate, NSTableViewDataSource, WKNavigationDelegate>

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSTableColumn *column;

@property (nonatomic, strong) EZQueryView *queryView;
@property (nonatomic, strong) EZSelectLanguageCell *selectLanguageCell;
@property (nonatomic, strong) EZTableTipsCell *tipsCell;

// queryText is self.queryModel.queryText;
@property (nonatomic, copy, readonly) NSString *queryText;
@property (nonatomic, strong) NSArray<NSString *> *serviceTypeIds;
@property (nonatomic, strong) NSArray<EZQueryService *> *services;
@property (nonatomic, strong) EZQueryModel *queryModel;

@property (nonatomic, strong) EZQueryService *firstService;

@property (nonatomic, strong) EZQueryService *defaultTTSService;
@property (nonatomic, strong) EZQueryService *youdaoService;

@property (nonatomic, strong) EZDetectManager *detectManager;
@property (nonatomic, strong) EZAudioPlayer *audioPlayer;
@property (nonatomic, strong) EZSchemeParser *schemeParser;

@property (nonatomic, strong) FBKVOController *kvo;

@property (nonatomic, assign) BOOL lockResizeWindow;

@property (nonatomic, assign) EZTipsCellType tipsCellType;

@property (nonatomic, copy) NSString *tipsCellContent;

@property (nonatomic, assign) BOOL isInputFieldCellVisible;
@property (nonatomic, assign) BOOL isSelectLanguageCellVisible;
@property (nonatomic, assign) BOOL isTipsViewVisible;

@property (nonatomic, assign) NSInteger inputFieldCellIndex;     // always 0
@property (nonatomic, assign) NSInteger selectLanguageCellIndex; // 0 or 1
@property (nonatomic, assign) NSInteger tipsCellIndex;           // 0 or 1 or 2

@property (nonatomic, strong) Configuration *config;

@end

@implementation EZBaseQueryViewController

/// !!!: Must init with a type, update NSNotification need window type.
- (instancetype)init {
    return [self initWithWindowType:EZWindowTypeFixed];
}

- (instancetype)initWithWindowType:(EZWindowType)type {
    if (self = [super init]) {
        self.windowType = type;
        [self setupUI];
        [self setupData];
        [self updateWindowHeight];
    }
    return self;
}

/// 用代码创建 NSViewController 貌似不会自动创建 view，需要手动初始化
- (void)loadView {
    CGRect frame = [[EZLayoutManager shared] windowFrameWithType:self.windowType];
    self.view = [[NSView alloc] initWithFrame:frame];
    self.view.wantsLayer = YES;
    self.view.layer.cornerRadius = EZCornerRadius_8;
    self.view.layer.masksToBounds = YES;
    [self.view excuteLight:^(NSView *_Nonnull x) {
        x.layer.backgroundColor = [NSColor ez_mainViewBgLightColor].CGColor;
    } dark:^(NSView *_Nonnull x) {
        x.layer.backgroundColor = [NSColor ez_mainViewBgDarkColor].CGColor;
    }];
}


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear {
    [super viewWillAppear];

    [EZLog logWindowAppear:self.windowType];
}


- (void)setupData {
    self.queryModel = [[EZQueryModel alloc] init];
    self.config = Configuration.shared;

    self.detectManager = [EZDetectManager managerWithModel:self.queryModel];

    [self setupServices:[self latestServices]];
    [self resetQueryAndResults];

    [self updateWindowConfiguration:nil];
}

- (void)setupUI {
    [self tableView];

    mm_weakify(self);
    [self setResizeWindowBlock:^{
        mm_strongify(self);

        // Avoid recycling call, resize window --> update window height --> resize window
        if (self.lockResizeWindow) {
            //            MMLogInfo(@"lockResizeWindow");
            return;
        }

        [self setNeedUpdateIframeHeightForAllResults];

        [self reloadTableViewDataWithLock:NO completion:^{
            // Update query view height manually, and update cell height.
            CGFloat queryViewHeight = [self.queryView heightOfQueryView];
            if (queryViewHeight) {
                self.queryModel.queryViewHeight = queryViewHeight;

                if (self.isInputFieldCellVisible) {
                    NSIndexSet *firstIndexSet = [NSIndexSet indexSetWithIndex:0];
                    [self.tableView noteHeightOfRowsWithIndexesChanged:firstIndexSet];
                }
            }

            [self updateWindowHeight];
        }];
    }];


    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self
                      selector:@selector(handleServiceUpdate:)
                          name:EZServiceHasUpdatedNotification
                        object:nil];

    [defaultCenter addObserver:self
                      selector:@selector(boundsDidChangeNotification:)
                          name:NSViewBoundsDidChangeNotification
                        object:[self.scrollView contentView]];

    // ???: FIX [dcs_error] kDCSActiveDictionariesChangedDistributedNotification catched, but it seems does not work.
    [defaultCenter addObserver:self
                      selector:@selector(activeDictionariesChanged:)
                          name:kDCSActiveDictionariesChangedDistributedNotification
                        object:nil];

    [defaultCenter addObserverForName:NSNotification.didChangeFontSize
                               object:nil
                                queue:NSOperationQueue.mainQueue
                           usingBlock:^(NSNotification *_Nonnull notification) {
                               mm_strongify(self);
                               [self reloadTableViewData:^{
                                   [self updateTableViewHeight];
                               }];
                           }];

    [defaultCenter addObserver:self
                      selector:@selector(modifyAppLanguage:)
                          name:NSNotification.languagePreferenceChanged
                        object:nil];

    [defaultCenter addObserver:self
                      selector:@selector(updateWindowConfiguration:)
                          name:NSNotification.didChangeWindowConfiguration
                        object:nil];

    // Observe for max window height settings changes
    [defaultCenter addObserver:self
                      selector:@selector(updateWindowHeight)
                          name:NSNotification.maxWindowHeightSettingsChanged
                        object:nil];
}

- (void)updateWindowConfiguration:(NSNotification *)notification {
    UpdateNotificationInfo *info = notification.object;
    if (info && info.windowType != self.windowType) {
        return;
    }

    self.queryModel.queryViewHeight = [self miniQueryViewHeight];

    self.isInputFieldCellVisible = [self.config showInputTextFieldWithKey:WindowConfigurationKeyInputFieldCellVisible
                                                               windowType:self.windowType];
    self.isSelectLanguageCellVisible = [self.config showInputTextFieldWithKey:WindowConfigurationKeySelectLanguageCellVisible
                                                                   windowType:self.windowType];

    self.inputFieldCellIndex = 0;

    if (self.isInputFieldCellVisible) {
        if (self.isSelectLanguageCellVisible) {
            self.selectLanguageCellIndex = 1;
            self.tipsCellIndex = 2;
        } else {
            self.tipsCellIndex = 1;
        }
    } else {
        if (self.isSelectLanguageCellVisible) {
            self.selectLanguageCellIndex = 0;
            self.tipsCellIndex = 1;
        } else {
            self.tipsCellIndex = 0;
        }
    }

    [self reloadTableViewData:nil];
}

- (void)modifyAppLanguage:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)setupServices:(NSArray *)allServices {
    NSMutableArray *serviceTypeIds = [NSMutableArray array];
    NSMutableArray *services = [NSMutableArray array];

    self.youdaoService = nil;
    EZServiceType defaultTTSServiceType = self.config.defaultTTSServiceType;

    for (EZQueryService *service in allServices) {
        if (service.enabled) {
            [self resetService:service];

            [services addObject:service];
            [serviceTypeIds addObject:service.serviceTypeWithUniqueIdentifier];
        }

        EZServiceType serviceType = service.serviceType;
        if ([serviceType isEqualToString:EZServiceTypeYoudao]) {
            self.youdaoService = service;
        }

        if ([serviceType isEqualToString:defaultTTSServiceType]) {
            _defaultTTSService = service;
        }
    }
    self.services = services;
    self.serviceTypeIds = serviceTypeIds;

    self.audioPlayer = [[EZAudioPlayer alloc] init];
    if (!self.youdaoService) {
        self.youdaoService = [self serviceWithType:EZServiceTypeYoudao];
    }
}

- (void)dealloc {
    MMLogInfo(@"dealloc: %@", self);

    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - NSNotificationCenter

- (void)activeDictionariesChanged:(NSNotification *)notification {
    MMLogInfo(@"Active dictionaries changed: %@", notification);
}

- (void)handleServiceUpdate:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    EZWindowType windowType = [userInfo[EZWindowTypeKey] integerValue];
    NSString *serviceType = userInfo[EZServiceTypeKey];
    BOOL autoQuery = [userInfo[EZAutoQueryKey] boolValue];

    MMLogInfo(@"handle service update notification: %@, userInfo: %@", serviceType, userInfo);

    if ([serviceType length] != 0) {
        [self updateService:serviceType autoQuery:autoQuery];
        return;
    }

    if (!userInfo || windowType == self.windowType || windowType == EZWindowTypeNone) {
        [self resetAllCellWithServices:[self latestServices] completion:^{
            if (autoQuery) {
                [self queryCurrentModel];
            }
        }];
    }
}

- (void)boundsDidChangeNotification:(NSNotification *)notification {
    // TODO: need to optimize. Manually update the cell height, because the reused cell will not self-adjust the height.
    //    [self updateAllResultCellHeightIfNeed];
    [self updateTableViewHeight];
}

#pragma mark - Getter && Setter

- (NSScrollView *)scrollView {
    if (!_scrollView) {
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:scrollView];
        _scrollView = scrollView;

        scrollView.wantsLayer = YES;
        scrollView.layer.cornerRadius = EZCornerRadius_8;
        [scrollView excuteLight:^(NSScrollView *scrollView) {
            scrollView.backgroundColor = [NSColor ez_mainViewBgLightColor];
        } dark:^(NSScrollView *scrollView) {
            scrollView.backgroundColor = [NSColor ez_mainViewBgDarkColor];
        }];

        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(0);
            make.left.right.bottom.equalTo(self.view);

            CGSize miniWindowSize = [EZLayoutManager.shared minimumWindowSize:self.windowType];
            make.width.mas_greaterThanOrEqualTo(miniWindowSize.width);
            make.height.mas_greaterThanOrEqualTo(miniWindowSize.height);
        }];

        scrollView.hasVerticalScroller = YES;
        scrollView.verticalScroller.controlSize = NSControlSizeSmall;
        [scrollView setAutomaticallyAdjustsContentInsets:NO];

        CGFloat bottomInset = EZHorizontalCellSpacing_10 - EZVerticalCellSpacing_7 / 2;
        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, bottomInset, 0);
    }
    return _scrollView;
}

- (NSTableView *)tableView {
    if (!_tableView) {
        NSTableView *tableView = [[NSTableView alloc] initWithFrame:self.scrollView.bounds];
        _tableView = tableView;

        [tableView excuteLight:^(NSTableView *tableView) {
            tableView.backgroundColor = [NSColor ez_mainViewBgLightColor];
        } dark:^(NSTableView *tableView) {
            tableView.backgroundColor = [NSColor ez_mainViewBgDarkColor];
        }];

        tableView.style = NSTableViewStylePlain;

        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:EZColumnId];
        self.column = column;
        column.resizingMask = NSTableColumnUserResizingMask | NSTableColumnAutoresizingMask;
        [tableView addTableColumn:column];

        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 40;
        [tableView setAutoresizesSubviews:YES];
        [tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];

        tableView.headerView = nil;
        tableView.intercellSpacing = CGSizeMake(2 * EZHorizontalCellSpacing_10, EZVerticalCellSpacing_7);
        tableView.gridColor = NSColor.clearColor;
        self.scrollView.documentView = tableView;
        [tableView sizeLastColumnToFit]; // must put in the end
    }
    return _tableView;
}

- (EZSchemeParser *)schemeParser {
    if (!_schemeParser) {
        _schemeParser = [[EZSchemeParser alloc] init];
    }
    return _schemeParser;
}

- (EZAudioPlayer *)audioPlayer {
    if (!_audioPlayer) {
        _audioPlayer = [[EZAudioPlayer alloc] init];
    }
    return _audioPlayer;
}

- (void)setInputText:(NSString *)inputText {
    // !!!: Rewrite property copy setter. Avoid text being affected.
    _inputText = [inputText copy];

    self.queryModel.inputText = _inputText;


    [self updateQueryViewModelAndDetectedLanguage:self.queryModel];
}

- (NSString *)queryText {
    NSString *queryText = self.queryModel.queryText;
    return queryText;
}

- (EZQueryService *)defaultTTSService {
    EZServiceType defaultTTSServiceType = self.config.defaultTTSServiceType;
    if (![_defaultTTSService.serviceType isEqualToString:defaultTTSServiceType]) {
        _defaultTTSService = [EZServiceTypes.shared serviceWithTypeId:defaultTTSServiceType];
    }
    return _defaultTTSService;
}
#pragma mark - Public Methods

/// Before starting query text, close all result view.
- (void)startQueryText:(NSString *)text {
    [self startQueryText:text actionType:self.queryModel.actionType];
}

- (void)startQueryText:(NSString *)text actionType:(EZActionType)actionType {
    MMLogInfo(@"query actionType: %@", actionType);

    if (text.trim.length == 0) {
        MMLogWarn(@"query text is empty");
        return;
    }

    self.inputText = text;
    self.queryModel.actionType = actionType;
    self.queryView.isTypingChinese = NO;

    if ([self handleEasydictScheme:text]) {
        return;
    }

    // Before starting new query, we should stop the previous query.
    [self.queryModel stopAllService];

    // Close all resultView before querying new text.
    [self closeAllResultView:^{
        self.inputText = text;
        [self queryCurrentModel];
    }];
}

/// Handle Easydict scheme.
- (BOOL)handleEasydictScheme:(NSString *)text {
    BOOL isEasydictScheme = [self.schemeParser isEasydictScheme:text];
    if (!isEasydictScheme) {
        return NO;
    }

    [self.schemeParser openURLScheme:text completion:^(BOOL isSuccess, NSString *_Nullable returnValue, NSString *_Nullable actionKey) {
        NSString *message = isSuccess ? @"Success" : @"Failed";
        if (returnValue.length > 0) {
            message = returnValue;
        }

        [EZToast showToast:message];

        if (!isSuccess) {
            return;
        }

        [self clearInput];

        // If write, need to update.
        if (actionKey && [self.schemeParser isWriteActionKey:actionKey]) {
            // Besides current window, other pages need to be notified, such as the settings service page.
            [NSNotificationCenter.defaultCenter postServiceUpdateNotification];
        }
    }];

    return YES;
}

- (void)startOCRImage:(NSImage *)image
           actionType:(EZActionType)actionType
            autoQuery:(BOOL)autoQuery {
    MMLogInfo(@"start OCR Image: %@, actionType: %@", @(image.size), actionType);

    self.queryModel.actionType = actionType;
    self.queryModel.ocrImage = image;

    self.queryView.isTypingChinese = NO;
    [self.queryView startLoadingAnimation:YES];

    // Hide previous tips view first.
    [self showTipsView:NO completion:nil];

    mm_weakify(self);
    [self.detectManager ocrAndDetectText:^(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error) {
        mm_strongify(self);
        // !!!: inputText should be used here, not queryText, queryText may be modified, such as easydict://query?text=xxx
        NSString *inputText = queryModel.inputText;
        MMLogInfo(@"ocr result: %@", inputText);

        NSDictionary *dict = @{
            @"detectedLanguage" : queryModel.detectedLanguage,
            @"actionType" : actionType,
        };
        [EZLog logEventWithName:@"ocr" parameters:dict];


        if (actionType == EZActionTypeScreenshotOCR) {
            [inputText copyToPasteboard];

            dispatch_block_on_main_safely(^{
                [EZToast showSuccessToast];
            });

            return;
        }


        if (actionType != EZActionTypeScreenshotOCR) {
            [self.queryView startLoadingAnimation:NO];

            self.inputText = inputText;

            // Show detected language, even auto
            self.queryModel.showAutoLanguage = YES;

            [self updateQueryTextAndParagraphStyle:inputText actionType:actionType];

            if (error) {
                NSString *errorMsg = [error localizedDescription];
                [self showTipsView:YES content:errorMsg type:EZTipsCellTypeErrorTips];
                return;
            }

            if (self.config.autoCopyOCRText) {
                [inputText copyToPasteboard];
            }

            [self.queryView highlightAllLinks];

            if ([self.inputText isURL]) {
                // Append a whitespace to beautify the link.
                self.inputText = [self.inputText stringByAppendingString:@" "];

                return;
            }

            if (autoQuery) {
                [self startQueryText];
            }
        }
    }];
}

- (void)retryQueryWithLanguage:(EZLanguage)language {
    MMLogInfo(@"Retry query with language: %@", language);

    [self.audioPlayer stop];

    // Reset query view height if we are retrying OCR query
    if (self.queryModel.ocrImage) {
        self.inputText = @"";
    }

    // If has designated language, we don't need to detect language again.
    if (language == EZLanguageAuto) {
        self.queryModel.detectedLanguage = EZLanguageAuto;
        self.queryModel.needDetectLanguage = YES;
    } else {
        self.queryModel.detectedLanguage = language;
        self.queryModel.needDetectLanguage = NO;
    }

    [self closeAllResultView:^{
        [self startQueryWithType:self.queryModel.actionType];
    }];
}

- (void)focusInputTextView {
    // Fix ⚠️: ERROR: Setting <EZTextView: 0x13d82c5d0> as the first responder for window <EZFixedQueryWindow: 0x11c607800>, but it is in a different window ((null))! This would eventually crash when the view is freed. The first responder will be set to nil.
    if (self.queryView.window == self.baseQueryWindow) {
        // Need to activate the current application first.
        [NSApp activateIgnoringOtherApps:YES];

        // Delay to make textView the first responder.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.baseQueryWindow makeFirstResponder:self.queryView.textView];
            if (self.config.selectQueryTextWhenWindowActivate) {
                self.queryView.textView.selectedRange = NSMakeRange(0, self.inputText.length);
            }
        });
    }
}

- (void)clearInput {
    // Clear query text, detect language and clear button right now;
    self.inputText = @"";
    self.queryModel.ocrImage = nil;
    [self.queryView setAlertTextHidden:YES];

    [self.audioPlayer stop];
}

- (void)clearAll {
    [self clearInput];

    [self updateQueryCellWithCompletionHandler:^{
        // !!!: To show closing animation, we cannot reset result directly.
        [self closeAllResultView:^{
            [self resetQueryAndResults];
        }];
    }];

    self.queryView.clearButtonHidden = YES;
}

- (void)copyQueryText {
    [self.inputText copyAndShowToast:YES];
}

- (void)copyFirstTranslatedText {
    if (self.firstService) {
        [self.firstService.result.copiedText copyAndShowToast:YES];
    }
}

- (void)toggleTranslationLanguages {
    [self.selectLanguageCell toggleTranslationLanguages];
}

- (void)stopPlayingQueryText {
    [self togglePlayQueryText:NO];
    [self stopAllResultAudio];
}

- (void)togglePlayQueryText {
    BOOL isPlaying = self.audioPlayer.isPlaying;
    [self togglePlayQueryText:!isPlaying];
}

- (void)togglePlayQueryText:(BOOL)play {
    if (!play) {
        [self.audioPlayer stop];
        return;
    }

    void (^playAudioBlock)(void) = ^{
        NSString *queryText = self.queryText;
        NSString *textLanguage = self.queryModel.queryFromLanguage;
        BOOL isEnglishWord = [queryText isEnglishWordWithLanguage:textLanguage];

        // If query text is an English word, use Youdao TTS to play.
        EZQueryService *ttsService = isEnglishWord ? self.youdaoService : self.defaultTTSService;
        NSString *accent = self.config.pronunciation == EnglishPronunciationUk ? @"uk" : @"us";

        [self.audioPlayer playTextAudio:queryText
                               language:textLanguage
                                 accent:accent
                               audioURL:nil
                      designatedService:ttsService];
    };

    // Before playing audio, we should detect the query text language.
    if (self.queryModel.hasQueryFromLanguage) {
        playAudioBlock();
    } else {
        [self detectQueryText:^(NSString *_Nonnull language) {
            playAudioBlock();
        }];
    }
}

- (void)stopAllResultAudio {
    for (EZQueryService *service in self.services) {
        [service.audioPlayer stop];
    }
}

/// Update query text, auto adjust ParagraphStyle, and scroll to end of textView.
- (void)updateQueryTextAndParagraphStyle:(NSString *)text actionType:(EZActionType)queryType {
    [self.queryView.textView updateTextAndParagraphStyle:text];
    self.queryModel.actionType = queryType;

    if (text) {
        /**
         If user disabled auto query when getting selected text, we should close tips view after updating query text.
         But reloadTableViewData will lost focus, we need to recover input focus.
         */
        [self showTipsView:NO completion:^{
            [self focusInputTextView];
        }];
    }
}

- (void)updateActionType:(EZActionType)actionType {
    self.queryModel.actionType = actionType;
}

- (void)showTipsView:(BOOL)isVisible {
    [self showTipsView:isVisible content:@"" type:EZTipsCellTypeTextEmpty];
}

- (void)showTipsView:(BOOL)isVisible
             content:(NSString *)content
                type:(EZTipsCellType)type {
    self.tipsCellType = type;
    self.tipsCellContent = content;
    [self.tipsCell updateTipsContent:content type:type];
    [self showTipsView:isVisible completion:nil];
}

- (void)showTipsView:(BOOL)isVisible completion:(void (^)(void))completion {
    // when queryModel.queryText is Empty show tips

    if (!isVisible && !self.isTipsViewVisible) {
        if (completion) {
            completion();
        }
        return;
    }

    self.isTipsViewVisible = isVisible;

    if (isVisible) {
        [self resetQueryAndResults];
    }

    [self reloadTableViewData:completion];
}

- (void)scrollToEndOfTextView {
    [self.queryView scrollToEndOfTextView];
}

- (void)receiveTitlebarAction:(EZTitlebarQuickAction)action {
    switch (action) {
        case EZTitlebarQuickActionWordsSegmentation: {
            self.inputText = [self.inputText segmentWords];
            break;
        }
        case EZTitlebarQuickActionRemoveCommentBlockSymbols: {
            self.inputText = [self.inputText removeCommentBlockSymbols];
            break;
        }
        case EZTitlebarQuickActionReplaceNewlineWithSpace: {
            self.inputText = [self.inputText replacingNewlinesWithWhitespace];
        }
        default:
            break;
    }
}

#pragma mark - Query Methods

- (void)startQueryText {
    [self startQueryText:self.inputText actionType:self.queryModel.actionType];
}

- (void)startQueryWithType:(EZActionType)actionType {
    NSImage *ocrImage = self.queryModel.ocrImage;

    if (ocrImage && (actionType == EZActionTypeOCRQuery || actionType == EZActionTypePasteboardOCR)) {
        BOOL autoQuery = self.config.autoCopyOCRText || self.config.autoQueryPastedText || self.queryModel.autoQuery;
        [self startOCRImage:ocrImage actionType:actionType autoQuery:autoQuery];
    } else {
        [self startQueryText:self.inputText actionType:actionType];
    }
}

/// Directly query model.
- (void)queryCurrentModel {
    if (self.queryText.length == 0) {
        MMLogWarn(@"query text is empty");
        return;
    }

    MMLogInfo(@"query text: %@", self.queryText.truncated);

    // !!!: Reset all result before new query.
    [self resetAllResults];

    if (self.queryModel.needDetectLanguage) {
        [self detectQueryText:^(NSString *_Nonnull language) {
            [self queryAllSerives:self.queryModel];
        }];
    } else {
        [self queryAllSerives:self.queryModel];
    }
}

- (void)queryAllSerives:(EZQueryModel *)queryModel {
    MMLogInfo(@"query: %@ --> %@", queryModel.queryFromLanguage, queryModel.queryTargetLanguage);

    self.firstService = nil;
    for (EZQueryService *service in self.services) {
        BOOL enableAutoQuery = service.enabledQuery && service.enabledAutoQuery && service.supportedQueryType != EZQueryTextTypeNone;
        if (!enableAutoQuery) {
            MMLogInfo(@"service disabled: %@", service.serviceTypeWithUniqueIdentifier);
            continue;
        }

        [self queryWithModel:queryModel service:service];

        if (!self.firstService) {
            self.firstService = service;
            [self autoCopyTranslatedTextOfService:service];
        }
    }

    [[EZLocalStorage shared] increaseQueryCount:self.inputText];

    // Auto play query text if it is an English word.
    [self autoPlayEnglishWordAudio];
}

- (void)queryWithModel:(EZQueryModel *)queryModel service:(EZQueryService *)service {
    [self queryWithModel:queryModel service:service completion:^(EZQueryResult *result, NSError *_Nullable error) {
        if (error) {
            MMLogError(@"service: %@, query error: %@", service.serviceType, error);
        }
        result.error = [EZQueryError queryErrorFrom:error];

        // Auto convert to traditional Chinese if needed.
        if (service.autoConvertTraditionalChinese &&
            [self.queryModel.queryTargetLanguage isEqualToString:EZLanguageTraditionalChinese]) {
            [service.result convertToTraditionalChineseResult];
        }

        BOOL hideResult = !result.manualShow && !result.hasTranslatedResult && result.isWarningErrorType;
        if (hideResult) {
            result.isShowing = NO;
        }

        //        MMLogInfo(@"update service: %@, %@", service.serviceType, result);
        [self updateCellWithResult:result reloadData:YES];

        if (service.autoCopyTranslatedTextBlock) {
            service.autoCopyTranslatedTextBlock(result, error);
        }
    }];
}

// TODO: service already has the model property.
- (void)queryWithModel:(EZQueryModel *)queryModel
               service:(EZQueryService *)service
            completion:(nonnull void (^)(EZQueryResult *result, NSError *_Nullable error))completion {
    if (!service.enabledQuery) {
        MMLogWarn(@"service disabled: %@", service.serviceTypeWithUniqueIdentifier);
        return;
    }
    if (queryModel.queryText.length == 0) {
        MMLogWarn(@"queryText is empty");
        return;
    }

    //    MMLogInfo(@"query service: %@", service.serviceType);

    EZQueryResult *result = service.result;

    // Show result if it has been queried.
    result.isShowing = YES;
    result.isLoading = YES;

    [self updateResultLoadingAnimation:result];

    [service startQuery:queryModel completion:completion];

    [EZLocalStorage.shared increaseQueryService:service];
}

- (void)updateResultLoadingAnimation:(EZQueryResult *)result {
    EZResultView *resultView = [self resultCellOfResult:result];
    [resultView updateLoadingAnimation];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.services.count + [self resultCellOffset];
}

#pragma mark - NSTableViewDelegate

// View-base 设置某个元素的具体视图
- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    //    MMLogInfo(@"tableView for row: %ld", row);

    if ([self isInputFieldCellAtRow:row]) {
        self.queryView = [self createQueryView];
        self.queryView.associatedWindowType = self.windowType;
        [self.queryView initializeAimatedButtonAlphaValue:self.queryModel];
        self.queryView.queryModel = self.queryModel;
        return self.queryView;
    }

    if ([self isSelectLanguageCellAtRow:row]) {
        EZSelectLanguageCell *selectLanguageCell = [self.tableView makeViewWithIdentifier:EZSelectLanguageCellId owner:self];
        if (!selectLanguageCell) {
            selectLanguageCell = [[EZSelectLanguageCell alloc] initWithFrame:[self tableViewContentBounds]];
            selectLanguageCell.identifier = EZSelectLanguageCellId;
        }
        selectLanguageCell.queryModel = self.queryModel;
        self.selectLanguageCell = selectLanguageCell;

        mm_weakify(self);
        [selectLanguageCell setEnterActionBlock:^(EZLanguage from, EZLanguage to) {
            mm_strongify(self);
            self.queryModel.userSourceLanguage = from;
            self.queryModel.userTargetLanguage = to;

            [self retryQueryWithLanguage:EZLanguageAuto];
        }];
        return selectLanguageCell;
    }

    // show tips view
    if ([self isTipsViewAtRow:row]) {
        EZTableTipsCell *tipsCell = [self.tableView makeViewWithIdentifier:EZTableTipsCellId owner:self];
        if (!tipsCell) {
            tipsCell = [[EZTableTipsCell alloc] initWithFrame:[self tableViewContentBounds]
                                                         type:self.tipsCellType
                                                      content:self.tipsCellContent];
            tipsCell.identifier = EZTableTipsCellId;
        }
        self.tipsCell = tipsCell;
        return tipsCell;
    }

    EZResultView *resultCell = [self resultCellAtRow:row];
    resultCell.associatedWindowType = self.windowType;

    return resultCell;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [[EZTableRowView alloc] init];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    CGFloat height;

    if ([self isInputFieldCellAtRow:row]) {
        height = self.queryModel.queryViewHeight;
    } else if ([self isSelectLanguageCellAtRow:row]) {
        height = 35;
    } else if ([self isTipsViewAtRow:row]) {
        if (!self.tipsCell) {
            // mini cell height
            if ([self isCustomTipsType]) {
                height = 80;
            } else {
                height = 104;
            }
        } else {
            height = [self.tipsCell cellHeight];
        }
    } else {
        EZQueryResult *result = [self serviceAtRow:row].result;
        if (result.isShowing) {
            // A non-zero value must be set, but the initial viewHeight is 0.
            height = MAX(result.viewHeight, EZResultViewMiniHeight);
        } else {
            height = EZResultViewMiniHeight;
        }
    }
    //    MMLogInfo(@"row: %ld, height: %@", row, @(height));

    return height;
}

// Disable select cell
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}


#pragma mark - Update TableView and row cell.

/// Reset tableView, reloadData
- (void)resetTableView:(nullable void (^)(void))completion {
    [self resetQueryAndResults];
    [self reloadTableViewData:completion];
}

/// TableView reloadData, and update window height.
- (void)reloadTableViewData:(nullable void (^)(void))completion {
    [self reloadTableViewDataWithLock:YES completion:completion];
}

- (void)reloadTableViewDataWithLock:(BOOL)lockFlag completion:(nullable void (^)(void))completion {
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self updateWindowHeightWithLock:lockFlag];
        if (completion) {
            completion();
        }
    }];

    [self.tableView reloadData];
    [CATransaction commit];
}

- (void)closeAllResultView:(void (^)(void))completionHandler {
    [self.queryModel stopAllService];

    // !!!: Need to update all result cells, even it's not showing, it may show error image.
    NSArray *allResults = [self resetAllResults];
    [self updateCellWithResults:allResults reloadData:YES completionHandler:completionHandler];
}


- (void)updateCellWithResult:(EZQueryResult *)result reloadData:(BOOL)reloadData {
    if (result) {
        [self updateCellWithResults:@[ result ] reloadData:reloadData completionHandler:nil];
    }
}

- (void)updateCellWithResult:(EZQueryResult *)result reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {
    [self updateCellWithResults:@[ result ] reloadData:reloadData completionHandler:completionHandler];
}

- (void)updateCellWithResults:(NSArray<EZQueryResult *> *)results reloadData:(BOOL)reloadData {
    [self updateCellWithResults:results reloadData:reloadData completionHandler:nil];
}

- (void)updateCellWithResults:(NSArray<EZQueryResult *> *)results reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    for (EZQueryResult *result in results) {
        // !!!: Render webView html takes a little time(~0.5s), so we stop loading when webView finished loading.
        BOOL isFinished = YES;
        if (result.isShowing && result.HTMLString.length) {
            isFinished = result.webViewManager.wordResultViewHeight > 0;
        }
        result.isLoading = !isFinished;

        NSIndexSet *indexSet = [self indexSetOfResult:result];
        if (indexSet) {
            [rowIndexes addIndexes:indexSet];
        }
    }
    [self updateTableViewRowIndexes:rowIndexes reloadData:reloadData completionHandler:completionHandler];
}

- (void)updateTableViewRowIndexes:(NSIndexSet *)rowIndexes reloadData:(BOOL)reloadData {
    [self updateTableViewRowIndexes:rowIndexes reloadData:reloadData completionHandler:nil];
}

/// Update tableView row data, update row height and window height with animation.
- (void)updateTableViewRowIndexes:(NSIndexSet *)rowIndexes reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {
    [self updateTableViewRowIndexes:rowIndexes reloadData:reloadData animate:YES completionHandler:completionHandler];
}

/// Update cell row height, and reload cell data with animation.
/// TODO: we need to optimize the way of updating row height.
- (void)updateTableViewRowIndexes:(NSIndexSet *)rowIndexes
                       reloadData:(BOOL)reloadData
                          animate:(BOOL)animateFlag
                completionHandler:(void (^)(void))completionHandler {
    //    MMLogInfo(@"updateTableViewRowIndexes: %@", rowIndexes);

    // !!!: Since the caller may be in non-main thread, we need to dispatch to main thread, but canont always use dispatch_async, it will cause the animation not smooth.
    dispatch_block_on_main_safely(^{
        if (reloadData) {
            // !!!: Note: For NSView-based table views, this method drops the view-cells in the table row, but not the NSTableRowView instances.

            // ???: need to check.

            [self.tableView reloadDataForRowIndexes:rowIndexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        }

        CGFloat duration = animateFlag ? EZUpdateTableViewRowHeightAnimationDuration : 0;

        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
            context.duration = duration;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

            // !!!: Must first notify the update tableView cell height, and then calculate the tableView height.
            //            MMLogInfo(@"noteHeightOfRowsWithIndexesChanged: %@", rowIndexes);
            [self.tableView noteHeightOfRowsWithIndexesChanged:rowIndexes];
            [self updateWindowHeight];
        } completionHandler:^{
            //            MMLogInfo(@"completionHandler, updateTableViewRowIndexes: %@", rowIndexes);
            if (completionHandler) {
                completionHandler();
            }
        }];
    });
}

- (void)updateQueryCell {
    [self updateQueryCellWithAnimation:NO completionHandler:nil];
}

- (void)updateQueryCellWithAnimation:(BOOL)animateFlag {
    [self updateQueryCellWithAnimation:animateFlag completionHandler:nil];
}

/// Update query cell data and row height.
- (void)updateQueryCellWithCompletionHandler:(nullable void (^)(void))completionHandler {
    [self updateQueryCellWithAnimation:YES completionHandler:completionHandler];
}

- (void)updateQueryCellWithAnimation:(BOOL)animateFlag completionHandler:(nullable void (^)(void))completionHandler {
    if (self.isInputFieldCellVisible) {
        NSIndexSet *firstIndexSet = [NSIndexSet indexSetWithIndex:self.inputFieldCellIndex];
        [self updateTableViewRowIndexes:firstIndexSet reloadData:NO animate:animateFlag completionHandler:completionHandler];
    }
}

- (void)updateSelectLanguageCell {
    if (self.isSelectLanguageCellVisible) {
        NSIndexSet *rowIndexes = [NSMutableIndexSet indexSetWithIndex:self.selectLanguageCellIndex];
        [self.tableView reloadDataForRowIndexes:rowIndexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
}


// iterate all result cell, if cell height is not equal to the result cell height, update cell height.
- (void)updateAllResultCellHeightIfNeed {
    NSInteger offset = [self resultCellOffset];
    NSInteger numberOfRows = [self.tableView numberOfRows];
    for (NSInteger row = offset; row < numberOfRows; row++) {
        EZQueryService *service = [self serviceAtRow:row];
        EZQueryResult *result = service.result;
        if (result) {
            EZResultView *resultCell = [[[self.tableView rowViewAtRow:row makeIfNecessary:NO] subviews] firstObject];
            CGFloat cellHeight = resultCell.height;
            CGFloat resultHeight = result.viewHeight;
            if (cellHeight != resultHeight) {
                [self updateResultCellHeight:result];
            }
        }
    }
}

- (void)updateTableViewHeight {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.tableView numberOfRows])];
    [self.tableView noteHeightOfRowsWithIndexesChanged:indexSet];
}

- (void)updateResultCellHeight:(EZQueryResult *)result {
    NSIndexSet *indexSet = [self indexSetOfResult:result];
    if (indexSet) {
        [self.tableView noteHeightOfRowsWithIndexesChanged:indexSet];
    }
}

- (nullable NSIndexSet *)indexSetOfResult:(EZQueryResult *)result {
    NSInteger row = [self rowIndexOfResult:result];
    if (row == NSNotFound) {
        return nil;
    }
    NSInteger index = row + [self resultCellOffset];
    return [NSIndexSet indexSetWithIndex:index];
}

/// !!!: Maybe return NSNotFound
- (NSUInteger)rowIndexOfResult:(EZQueryResult *)result {
    NSString *serviceTypeWithUniqueIdentifier = result.serviceTypeWithUniqueIdentifier;
    // Sometimes the query is very slow, and at that time the user may have turned off the service in the settings page.
    NSInteger row = [self.serviceTypeIds indexOfObject:serviceTypeWithUniqueIdentifier];
    return row;
}


- (void)resetCellWithService:(EZQueryService *)service autoQuery:(BOOL)autoQuery {
    [self resetService:service];

    EZQueryResult *newResult = [service resetServiceResult];

    [self updateCellWithResult:newResult reloadData:YES completionHandler:^{
        if (autoQuery) {
            // Make enabledQuery = YES before retry, it may be closed manually.
            service.enabledQuery = YES;

            [self queryWithModel:self.queryModel service:service];
        }
    }];
}

- (void)resetService:(EZQueryService *)service {
    // We need to set service.queryModel first, otherwise result.queryModel will be nil.
    service.queryModel = self.queryModel;
    [service resetServiceResult];
    service.windowType = self.windowType;
}

- (void)updateService:(NSString *)serviceTypeWithUniqueIdentifier autoQuery:(BOOL)autoQuery {
    NSMutableArray *newServices = [self.services mutableCopy];
    for (EZQueryService *service in self.services) {
        if ([service.serviceTypeWithUniqueIdentifier isEqualToString:serviceTypeWithUniqueIdentifier]) {
            if (!autoQuery) {
                [self updateCellWithResult:service.result reloadData:YES completionHandler:nil];
                return;
            }

            EZQueryService *updatedService = [EZLocalStorage.shared service:serviceTypeWithUniqueIdentifier windowType:self.windowType];

            // For some strange reason, the old service can not be deallocated, this will cause a memory leak, and we also need to cancel old services subscribers.
            if ([service isKindOfClass:EZStreamService.class]) {
                [((EZStreamService *)service) cancelSubscribers];
            }

            NSInteger index = [self.serviceTypeIds indexOfObject:serviceTypeWithUniqueIdentifier];
            newServices[index] = updatedService;
            self.services = newServices.copy;

            [self resetCellWithService:updatedService autoQuery:autoQuery];

            return;
        }
    }
}

- (void)resetAllCellWithServices:(NSArray *)allServices completion:(void (^)(void))completion {
    [self setupServices:allServices];
    [self reloadTableViewData:completion];
}

/// Get latest services from local storage.
- (NSArray<EZQueryService *> *)latestServices {
    return [EZLocalStorage.shared allServices:self.windowType];
}


#pragma mark - Update Data.

- (void)resetQueryAndResults {
    [self resetAllResults];

    if (self.inputText.length) {
        self.inputText = @"";
    }
}

- (NSArray<EZQueryResult *> *)resetAllResults {
    NSMutableArray *allResults = [NSMutableArray array];
    for (EZQueryService *service in self.services) {
        EZQueryResult *result = [service resetServiceResult];
        [allResults addObject:result];
    }
    return allResults;
}

- (nullable EZResultView *)resultCellOfResult:(EZQueryResult *)result {
    NSInteger index = [self.serviceTypeIds indexOfObject:result.service.serviceTypeWithUniqueIdentifier];
    if (index != NSNotFound) {
        NSInteger row = index + [self resultCellOffset];
        EZResultView *resultCell = [[[self.tableView rowViewAtRow:row makeIfNecessary:NO] subviews] firstObject];

        // ???: Why is it possible to return a EZSelectLanguageCell ?
        if ([resultCell isKindOfClass:[EZResultView class]]) {
            return resultCell;
        }
    }

    return nil;
}

- (void)updateResultCell:(EZQueryResult *)result {
    EZResultView *resultView = [self resultCellOfResult:result];
    resultView.result = result;
}

- (void)delayDetectQueryText {
    [self cancelDelayDetectQueryText];
    [self performSelector:@selector(detectQueryText:) withObject:nil afterDelay:EZDelayDetectTextLanguageInterval];
}

- (void)cancelDelayDetectQueryText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(detectQueryText:) object:nil];
}

/// Detect query text, and update select language cell.
- (void)detectQueryText:(nullable void (^)(NSString *language))completion {
    [self cancelDelayDetectQueryText];

    [self.detectManager detectText:self.queryText completion:^(EZQueryModel *queryModel, NSError *error) {
        // `self.queryModel.detectedLanguage` has already been updated inside the method.

        // Show detected language button if has queryText, even detect language is auto.
        BOOL showAutoLanguage = YES;
        if (self.queryText.length == 0) {
            showAutoLanguage = NO;
        }
        self.queryModel.showAutoLanguage = showAutoLanguage;

        [self updateQueryViewModelAndDetectedLanguage:queryModel];

        if (completion) {
            completion(queryModel.detectedLanguage);
        }
    }];
}

- (void)updateQueryViewModelAndDetectedLanguage:(EZQueryModel *)queryModel {
    self.queryView.clearButtonHidden = (queryModel.inputText.length == 0) && ([self allShowingResults].count == 0);

    self.queryView.queryModel = queryModel;
    [self updateQueryCell];
    [self updateSelectLanguageCell];
}


// TODO: need to check, use true cell result, rather than self result
- (NSArray *)allShowingResults {
    NSMutableArray *results = [NSMutableArray array];
    for (EZQueryService *service in self.services) {
        EZQueryResult *result = service.result;
        if (result.isShowing) {
            [results addObject:result];
        }
    }

    return results;
}

/// Just set result isShowing to NO, not update cell view.
- (void)closeAllShowingResults {
    NSArray *results = [self allShowingResults];
    for (EZQueryResult *result in results) {
        result.isShowing = NO;
        result.isLoading = NO;
    }
}

/// Set all result webViewManager.isLoad to NO
- (void)setNeedUpdateIframeHeightForAllResults {
    for (EZQueryService *service in self.services) {
        EZQueryResult *result = service.result;
        result.webViewManager.needUpdateIframeHeight = YES;
    }
}

- (void)disableReplaceTextButton {
    for (EZQueryService *service in self.services) {
        service.result.showReplaceButton = NO;

        EZResultView *resultView = [self resultCellOfResult:service.result];
        resultView.wordResultView.replaceTextButton.enabled = NO;
    }
}


#pragma mark - Set up cell view

- (EZQueryView *)createQueryView {
    EZQueryView *queryView = [self.tableView makeViewWithIdentifier:EZQueryViewId owner:self];
    if (!queryView) {
        queryView = [[EZQueryView alloc] initWithFrame:[self tableViewContentBounds]];
        queryView.identifier = EZQueryViewId;
    }

    // placeholder, just for new user.
    NSString *placeholderText = NSLocalizedString(@"placeholder", nil);
    if (EZLocalStorage.shared.queryCount > 100) {
        placeholderText = @"";
    }
    queryView.placeholderText = placeholderText;

    queryView.audioButton.audioPlayer = self.audioPlayer;

    mm_weakify(self);
    [queryView setUpdateInputTextBlock:^(NSString *text, CGFloat queryViewHeight) {
        mm_strongify(self);
        //        MMLogInfo(@"UpdateQueryTextBlock");

        // !!!: The code here is a bit messy, so you need to be careful about changing it.

        // But, since there are cases where the query text is set manually, such as query selected text, where the query text is set first and then the input text is modified, the query cell must be updated for such cases.

        // Reduce the update frequency, update only when the queryText or height changes.
        if ([self.inputText isEqualToString:text] && self.queryModel.queryViewHeight == queryViewHeight) {
            return;
        }

        NSString *oldInputText = self.inputText;
        self.inputText = text;

        // Only detect when query text is changed.
        if (![self.inputText.trim isEqualToString:oldInputText.trim]) {
            [self delayDetectQueryText];
        }

        self.queryModel.queryViewHeight = queryViewHeight;
        [self updateQueryCell];
    }];

    [queryView setEnterActionBlock:^(NSString *text) {
        mm_strongify(self);
        // tips view hidden once user tap entry
        self.isTipsViewVisible = NO;
        [self startQueryText:text];
    }];

    [queryView setPasteTextBlock:^(NSString *_Nonnull text) {
        mm_strongify(self);
        BOOL autoQuery = [Configuration.shared autoQueryPastedText];
        if (autoQuery) {
            [self startQueryText:text];
        }
    }];

    [queryView setPlayAudioBlock:^(NSString *text) {
        mm_strongify(self);
        [self togglePlayQueryText];
    }];

    [queryView setCopyTextBlock:^(NSString *text) {
        [text copyAndShowToast:YES];
    }];

    [queryView setClearBlock:^(NSString *_Nonnull text) {
        mm_strongify(self);

        // Close tips view  when user clicking clear button.
        self.isTipsViewVisible = NO;

        [self clearAll];
    }];

    [queryView setSelectedLanguageBlock:^(EZLanguage language) {
        mm_strongify(self);

        EZLanguage detectedLanguage = self.queryModel.detectedLanguage;
        if (![detectedLanguage isEqualToString:language]) {
            self.queryModel.detectedLanguage = language;
            [self retryQueryWithLanguage:language];

            [self updateSelectLanguageCell];

            NSDictionary *dict = @{
                @"autoDetect" : detectedLanguage,
                @"userSelect" : language,
            };
            [EZLog logEventWithName:@"change_detected_language" parameters:dict];
        }
    }];

    return queryView;
}

- (EZResultView *)resultCellAtRow:(NSInteger)row {
    EZQueryService *service = [self serviceAtRow:row];
    EZResultView *resultCell = [self.tableView makeViewWithIdentifier:EZResultViewId owner:self];

    if (!resultCell) {
        resultCell = [[EZResultView alloc] initWithFrame:[self tableViewContentBounds]];
        resultCell.identifier = EZResultViewId;
    }

    EZQueryResult *result = service.result;
    resultCell.result = result;
    [self setupResultCell:resultCell];

    WKWebView *webView = nil;
    if ([service.serviceType isEqualToString:EZServiceTypeAppleDictionary]) {
        EZAppleDictionary *appleDictService = (EZAppleDictionary *)service;

        EZWebViewManager *webViewManager = result.webViewManager;
        webView = webViewManager.webView;
        resultCell.wordResultView.webView = webView;

        BOOL needLoadHTML = result.isShowing && result.HTMLString.length && !webViewManager.isLoaded;
        if (needLoadHTML) {
            webViewManager.isLoaded = YES;

            NSURL *htmlFileURL = [NSURL fileURLWithPath:appleDictService.htmlFilePath];
            webView.navigationDelegate = resultCell.wordResultView;
            [webView loadFileURL:htmlFileURL allowingReadAccessToURL:TTTDictionary.userDictionaryDirectoryURL];
        } else if (webViewManager.needUpdateIframeHeight && webViewManager.isLoaded) {
            [webViewManager updateAllIframe];
        }
    }

    return resultCell;
}

- (void)setupResultCell:(EZResultView *)resultView {
    EZQueryResult *result = resultView.result;
    EZQueryService *service = result.service;

    mm_weakify(self);
    [resultView setQueryTextBlock:^(NSString *_Nonnull word) {
        mm_strongify(self);
        [self startQueryText:word];
    }];

    [resultView setRetryBlock:^(EZQueryResult *result) {
        mm_strongify(self);
        [self resetCellWithService:service autoQuery:YES];
    }];

    // !!!: Avoid capture result, the block paramter result is different from former result.
    [resultView setClickArrowBlock:^(EZQueryResult *newResult) {
        mm_strongify(self);
        BOOL isShowing = newResult.isShowing;
        if (!isShowing) {
            [newResult.service.audioPlayer stop];
        }

        service.enabledQuery = isShowing;

        // If there is no result, try to query with current servie.
        if (isShowing && !newResult.hasShowingResult) {
            if (self.queryModel.needDetectLanguage) {
                [self detectQueryText:^(NSString *_Nonnull language) {
                    [self queryWithModel:self.queryModel service:service];
                }];
            } else {
                [self queryWithModel:self.queryModel service:service];
            }
        } else {
            // If alreay has result, just update cell.
            [self updateCellWithResult:newResult reloadData:YES];
        }
    }];
}

- (NSInteger)resultCellOffset {
    NSInteger offset = 0;

    if (self.isInputFieldCellVisible) {
        offset += 1;
    }
    if (self.isSelectLanguageCellVisible) {
        offset += 1;
    }
    if (self.isTipsViewVisible) {
        offset += 1;
    }

    return offset;
}

- (EZQueryService *)serviceAtRow:(NSInteger)row {
    NSInteger index = row - [self resultCellOffset];
    if (index < 0 || index >= self.services.count) {
        MMLogError(@"error row: %ld, windowType: %ld", row, self.windowType);
        return nil;
    }

    EZQueryService *service = self.services[index];
    return service;
}

- (nullable EZQueryService *)serviceWithType:(NSString *)serviceTypeId {
    NSInteger index = [self.serviceTypeIds indexOfObject:serviceTypeId];
    if (index != NSNotFound) {
        return self.services[index];
    }
    return nil;
}

// Get tableView bounds in real time.
- (CGRect)tableViewContentBounds {
    CGRect rect = CGRectMake(0, 0, self.scrollView.width - 2 * EZHorizontalCellSpacing_10, self.scrollView.height);
    return rect;
}


#pragma mark - Update Window Height

- (void)updateWindowHeight {
    [self updateWindowHeightWithLock:YES];
}

- (void)updateWindowHeightWithLock:(BOOL)lockFlag {
    if (lockFlag) {
        self.lockResizeWindow = YES;
    }

    //    MMLogInfo(@"updateWindowViewHeightWithLock");

    CGFloat tableViewHeight = [self getScrollViewContentHeight];
    CGFloat height = [self getRestrainedScrollViewHeight:tableViewHeight];
    //    MMLogInfo(@"getRestrainedScrollViewHeight: %@", @(height));

    CGSize maxWindowSize = [EZLayoutManager.shared maximumWindowSize:self.windowType];

    CGFloat titleBarHeight = EZTitlebarHeight_28; // system title bar height is 28

    CGFloat scrollViewHeight = height + self.scrollView.contentInsets.top + self.scrollView.contentInsets.bottom;
    scrollViewHeight = MIN(scrollViewHeight, maxWindowSize.height - titleBarHeight);
    //    MMLogInfo(@"scrollViewHeight: %@", @(scrollViewHeight));

    // Diable change window height manually.
    [self.scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(scrollViewHeight)).priority(MASLayoutPriorityDefaultHigh);
    }];

    CGFloat showingWindowHeight = scrollViewHeight + titleBarHeight;
    showingWindowHeight = MIN(showingWindowHeight, maxWindowSize.height);

    // Since chaneg height will cause position change, we need to adjust y to keep top-left coordinate position.
    NSWindow *window = self.view.window;
    CGFloat deltaHeight = window.height - showingWindowHeight;
    CGFloat y = window.y + deltaHeight;

    CGRect newFrame = CGRectMake(window.x, y, window.width, showingWindowHeight);

    CGRect screenVisibleFrame = EZLayoutManager.shared.screenVisibleFrame;
    CGRect safeFrame = [EZCoordinateUtils getSafeAreaFrame:newFrame inScreenVisibleFrame:screenVisibleFrame];

    // ???: why set window frame will change tableView height?
    // ???: why this window animation will block cell rendering?
    //    [self.window setFrame:safeFrame display:NO animate:animateFlag];
    [self.baseQueryWindow setFrame:safeFrame display:YES];

    // Restore tableView height.
    self.tableView.height = tableViewHeight;

    // Animation cost time.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(EZUpdateTableViewRowHeightAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.lockResizeWindow = NO;
    });

    //    MMLogInfo(@"window frame: %@", @(window.frame));
}

- (CGFloat)getRestrainedScrollViewHeight:(CGFloat)scrollViewContentHeight {
    CGFloat height = scrollViewContentHeight;

    CGSize minimumWindowSize = [EZLayoutManager.shared minimumWindowSize:self.windowType];
    CGSize maximumWindowSize = [EZLayoutManager.shared maximumWindowSize:self.windowType];

    height = MAX(height, minimumWindowSize.height);
    height = MIN(height, maximumWindowSize.height);

    return height;
}

/// Manually calculate tableView row height.
- (CGFloat)getScrollViewContentHeight {
    CGFloat scrollViewContentHeight = 0;

    NSInteger rowCount = [self numberOfRowsInTableView:self.tableView];
    for (int i = 0; i < rowCount; i++) {
        CGFloat rowHeight = [self tableView:self.tableView heightOfRow:i];
        //        MMLogInfo(@"row: %d, Height: %.1f", i, rowHeight);
        scrollViewContentHeight += (rowHeight + EZVerticalCellSpacing_7);
    }
    //    MMLogInfo(@"scrollViewContentHeight: %.1f", scrollViewContentHeight);


    return scrollViewContentHeight;
}

/// Auto calculate documentView height.
- (CGFloat)getContentHeight {
    // Modify scrollView height to 0, to get actual tableView content height, avoid blank view.
    self.scrollView.height = 0;

    CGFloat documentViewHeight = self.scrollView.documentView.height; // actually is tableView height
    //    MMLogInfo(@"documentView height: %@", @(documentViewHeight));

    return documentViewHeight;
}

- (CGFloat)miniQueryViewHeight {
    CGFloat miniInputViewHeight = [[EZLayoutManager shared] inputViewMinHeight:self.windowType];
    CGFloat queryViewHeight = miniInputViewHeight + EZQueryViewExceptInputViewHeight;
    return queryViewHeight;
}

#pragma mark - Auto play English word

- (void)autoPlayEnglishWordAudio {
    if (!self.config.autoPlayAudio) {
        return;
    }

    BOOL isEnglishWord = [self.queryText isEnglishWordWithLanguage:self.queryModel.queryFromLanguage];
    if (!isEnglishWord) {
        return;
    }

    MMLogInfo(@"Auto play English word audio: %@", self.queryText);
    [self togglePlayQueryText:YES];
}

#pragma mark -

/// Auto copy translated text.
- (void)autoCopyTranslatedTextOfService:(EZQueryService *)service {
    if (![self.config autoCopyFirstTranslatedText]) {
        service.autoCopyTranslatedTextBlock = nil;
        return;
    }

    [service setAutoCopyTranslatedTextBlock:^(EZQueryResult *result, NSError *error) {
        if (!result.HTMLString.length) {
            [result.copiedText copyToPasteboard];
            return;
        }

        mm_weakify(result);
        [result setDidFinishLoadingHTMLBlock:^{
            mm_strongify(result);
            [result.copiedText copyToPasteboard];
        }];
    }];
}

- (BOOL)isCustomTipsType {
    return self.tipsCellType == EZTipsCellTypeErrorTips ||
        self.tipsCellType == EZTipsCellTypeInfoTips ||
        self.tipsCellType == EZTipsCellTypeWarnTips;
}

- (BOOL)isInputFieldCellAtRow:(NSInteger)row {
    return row == self.inputFieldCellIndex && self.isInputFieldCellVisible;
}

- (BOOL)isSelectLanguageCellAtRow:(NSInteger)row {
    return row == self.selectLanguageCellIndex && self.isSelectLanguageCellVisible;
}

- (BOOL)isTipsViewAtRow:(NSInteger)row {
    return row == self.tipsCellIndex && self.isTipsViewVisible;
}

@end
