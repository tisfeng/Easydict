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
#import "EZWindowManager.h"
#import "EZServiceTypes.h"
#import "EZAudioPlayer.h"
#import "EZLog.h"
#import "EZConfiguration.h"
#import "EZLocalStorage.h"
#import "EZTableRowView.h"
#import "EZSchemeParser.h"
#import "EZBaiduTranslate.h"
#import "EZToast.h"
#import "DictionaryKit.h"
#import "EZAppleDictionary.h"
#import "NSString+EZUtils.h"
#import "EZEventMonitor.h"
#import "Easydict-Swift.h"

static NSString *const EZQueryViewId = @"EZQueryViewId";
static NSString *const EZSelectLanguageCellId = @"EZSelectLanguageCellId";
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

// queryText is self.queryModel.queryText;
@property (nonatomic, copy, readonly) NSString *queryText;
@property (nonatomic, strong) NSArray<EZServiceType> *serviceTypes;
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

@end

@implementation EZBaseQueryViewController

/// !!!: Must init with a type, update NSNotification need window type.
- (instancetype)init {
    return [self initWithWindowType:EZWindowTypeFixed];
}

- (instancetype)initWithWindowType:(EZWindowType)type {
    if (self = [super init]) {
        self.windowType = type;
        [self setupData];
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
    
    [self setupUI];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    
    [EZLog logWindowAppear:self.windowType];
}

- (void)setupData {
    self.queryModel = [[EZQueryModel alloc] init];
    self.queryModel.queryViewHeight = [self miniQueryViewHeight];
    
    self.detectManager = [EZDetectManager managerWithModel:self.queryModel];
    
    [self setupServices];
    [self resetQueryAndResults];
}

- (void)setupUI {
    [self tableView];
    
    [self updateWindowViewHeight];
    
    mm_weakify(self);
    [self setResizeWindowBlock:^{
        mm_strongify(self);
        
        // Avoid recycling call, resize window --> update window height --> resize window
        if (self.lockResizeWindow) {
            //            NSLog(@"lockResizeWindow");
            return;
        }
        
        [self setNeedUpdateIframeHeightForAllResults];
        
        [self reloadTableViewDataWithLock:NO completion:^{
            // Update query view height manually, and update cell height.
            CGFloat queryViewHeight = [self.queryView heightOfQueryView];
            if (queryViewHeight) {
                self.queryModel.queryViewHeight = queryViewHeight;
                NSIndexSet *firstIndexSet = [NSIndexSet indexSetWithIndex:0];
                [self.tableView noteHeightOfRowsWithIndexesChanged:firstIndexSet];
            }
            
            [self updateWindowViewHeight];
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
    
    
    //    ???: FIX [dcs_error] kDCSActiveDictionariesChangedDistributedNotification catched, but it seems does not work.
    [defaultCenter addObserver:self
                      selector:@selector(activeDictionariesChanged:)
                          name:kDCSActiveDictionariesChangedDistributedNotification
                        object:nil];
    
    [defaultCenter addObserverForName:ChangeFontSizeView.changeFontSizeNotificationName object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull notification) {
        mm_strongify(self);
        [self reloadTableViewData:^{
            [self updateAllResultCellHeight];
        }];
    }];
}


- (void)setupServices {
    NSMutableArray *serviceTypes = [NSMutableArray array];
    NSMutableArray *services = [NSMutableArray array];
    
    self.youdaoService = nil;
    EZServiceType defaultTTSServiceType = EZConfiguration.shared.defaultTTSServiceType;
    
    NSArray *allServices = [EZLocalStorage.shared allServices:self.windowType];
    for (EZQueryService *service in allServices) {
        if (service.enabled) {
            service.queryModel = self.queryModel;
            service.windowType = self.windowType;
            [services addObject:service];
            [serviceTypes addObject:service.serviceType];
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
    self.serviceTypes = serviceTypes;
    
    self.audioPlayer = [[EZAudioPlayer alloc] init];
    if (!self.youdaoService) {
        self.youdaoService = [self serviceWithType:EZServiceTypeYoudao];
    }
}

// 通知触发时会调用的方法
- (void)activeDictionariesChanged:(NSNotification *)notification {
    NSLog(@"Active dictionaries changed: %@", notification);
}

- (void)dealloc {
    NSLog(@"dealloc: %@", self);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSNotificationCenter

- (void)handleServiceUpdate:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    EZWindowType type = [userInfo[EZWindowTypeKey] integerValue];
    if (type == self.windowType || !userInfo) {
        [self updateServices];
    }
}

- (void)updateServices {
    [self setupServices];
    [self resetAllResults];
    
    [self reloadTableViewData:nil];
}

- (void)boundsDidChangeNotification:(NSNotification *)notification {
    // TODO: need to optimize. Manually update the cell height, because the reused cell will not self-adjust the height.
    //    [self updateAllResultCellHeightIfNeed];
    [self updateAllResultCellHeight];
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
    EZServiceType defaultTTSServiceType = EZConfiguration.shared.defaultTTSServiceType;
    if (![_defaultTTSService.serviceType isEqualToString:defaultTTSServiceType]) {
        _defaultTTSService = [EZServiceTypes.shared serviceWithType:defaultTTSServiceType];
    }
    return _defaultTTSService;
}


#pragma mark - Public Methods

/// Before starting query text, close all result view.
- (void)startQueryText:(NSString *)text {
    [self startQueryText:text actionType:self.queryModel.actionType];
}

- (void)startQueryText:(NSString *)text actionType:(EZActionType)actionType {
    NSLog(@"query actionType: %@", actionType);
    
    if (text.trim.length == 0) {
        NSLog(@"query text is empty");
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
            [self postUpdateServiceNotification];
        }
    }];
    
    return YES;
}

- (void)postUpdateServiceNotification {
    // Need to update all types window.
    NSNotification *notification = [NSNotification notificationWithName:EZServiceHasUpdatedNotification object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)startOCRImage:(NSImage *)image actionType:(EZActionType)actionType {
    NSLog(@"start OCR Image");
    
    self.queryModel.OCRImage = image;
    self.queryModel.actionType = actionType;
    
    self.queryView.isTypingChinese = NO;
    [self.queryView startLoadingAnimation:YES];
    
    mm_weakify(self);
    [self.detectManager ocrAndDetectText:^(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error) {
        mm_strongify(self);
        // !!!: inputText should be used here, not queryText, queryText may be modified, such as easydict://query?text=xxx
        NSString *inputText = queryModel.inputText;
        NSLog(@"ocr result: %@", inputText);
        
        NSDictionary *dict = @{
            @"detectedLanguage" : queryModel.detectedLanguage,
            @"actionType" : actionType,
        };
        [EZLog logEventWithName:@"ocr" parameters:dict];
        
        
        if (actionType == EZActionTypeScreenshotOCR) {
            [inputText copyToPasteboardSafely];
            
            dispatch_block_on_main_safely(^{
                [EZToast showSuccessToast];
            });
            
            return;
        }
        
        
        if (actionType == EZActionTypeOCRQuery) {
            [self.queryView startLoadingAnimation:NO];
            
            self.inputText = inputText;
            
            // Show detected language, even auto
            self.queryModel.showAutoLanguage = YES;
            
            [self updateQueryTextAndParagraphStyle:inputText actionType:actionType];
            
            if (error) {
                NSString *errorMsg = [error localizedDescription];
                self.queryView.alertText = errorMsg;
                return;
            }
            
            if (EZConfiguration.shared.autoCopyOCRText) {
                [inputText copyToPasteboardSafely];
            }
            
            [self.queryView highlightAllLinks];
            
            if ([self.inputText isURL]) {
                // Append a whitespace to beautify the link.
                self.inputText = [self.inputText stringByAppendingString:@" "];
                
                return;
            }
            
            BOOL autoSnipTranslate = EZConfiguration.shared.autoQueryOCRText;
            if (autoSnipTranslate && queryModel.autoQuery) {
                [self startQueryText];
            }
        }
    }];
}

- (void)retryQuery {
    NSLog(@"retry query");
    
    [self.audioPlayer stop];
    
    // Reset query view height.
    if (self.queryModel.OCRImage) {
        self.inputText = @"";
    }
    
    // Re-detect langauge when retry.
    self.queryModel.detectedLanguage = EZLanguageAuto;
    self.queryModel.needDetectLanguage = YES;
    
    [self closeAllResultView:^{
        [self startQueryWithType:self.queryModel.actionType];
    }];
}

- (void)focusInputTextView {
    // Fix ⚠️: ERROR: Setting <EZTextView: 0x13d82c5d0> as the first responder for window <EZFixedQueryWindow: 0x11c607800>, but it is in a different window ((null))! This would eventually crash when the view is freed. The first responder will be set to nil.
    if (self.queryView.window == self.baseQueryWindow) {
        // Need to activate the current application first.
        [NSApp activateIgnoringOtherApps:YES];
        
        [self.baseQueryWindow makeFirstResponder:self.queryView.textView];
    }
}

- (void)clearInput {
    // Clear query text, detect language and clear button right now;
    self.inputText = @"";
    self.queryModel.OCRImage = nil;
    [self.queryView setAlertTextHidden:YES];
    
    [self.audioPlayer stop];
    ;
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
        
        [self.audioPlayer playTextAudio:queryText
                               language:textLanguage
                                 accent:nil
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
}

- (void)scrollToEndOfTextView {
    [self.queryView scrollToEndOfTextView];
}

#pragma mark - Query Methods

- (void)startQueryText {
    [self startQueryText:self.inputText actionType:self.queryModel.actionType];
}

- (void)startQueryWithType:(EZActionType)actionType {
    NSImage *ocrImage = self.queryModel.OCRImage;
    if (actionType == EZActionTypeOCRQuery && ocrImage) {
        [self startOCRImage:ocrImage actionType:actionType];
    } else {
        [self startQueryText:self.inputText actionType:actionType];
    }
}

/// Directly query model.
- (void)queryCurrentModel {
    if (self.queryText.length == 0) {
        NSLog(@"query text is empty");
        return;
    }
    
    NSLog(@"query text: %@", self.queryText);
    
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
    NSLog(@"query: %@ --> %@", queryModel.queryFromLanguage, queryModel.queryTargetLanguage);
    
    self.firstService = nil;
    for (EZQueryService *service in self.services) {
        BOOL enableAutoQuery = service.enabledQuery && service.enabledAutoQuery;
        if (!enableAutoQuery) {
            NSLog(@"service disabled: %@", service.serviceType);
            continue;
        }
        
        [self queryWithModel:queryModel service:service autoPlay:NO];
        
        if (!self.firstService) {
            self.firstService = service;
            [self autoCopyTranslatedTextOfService:service];
        }
    }
    
    [[EZLocalStorage shared] increaseQueryCount:self.inputText];
    
    // Auto play query text if it is an English word.
    [self autoPlayEnglishWordAudio];
}

- (void)queryWithModel:(EZQueryModel *)queryModel
               service:(EZQueryService *)service
              autoPlay:(BOOL)autoPlay {
    [self queryWithModel:queryModel service:service completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
        if (error) {
            NSLog(@"query error: %@", error);
        }
        result.error = [EZError errorWithNSError:error];
        
        // Auto convert to traditional Chinese if needed.
        if (service.autoConvertTraditionalChinese &&
            [self.queryModel.queryTargetLanguage isEqualToString:EZLanguageTraditionalChinese]) {
            [service.result convertToTraditionalChineseResult];
        }
        
        BOOL hideResult = !result.manulShow && !result.hasTranslatedResult && result.isWarningErrorType;
        if (hideResult) {
            result.isShowing = NO;
        }
        
        //  NSLog(@"update service: %@, %@", service.serviceType, result);
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
        NSLog(@"service disabled: %@", service.serviceType);
        return;
    }
    if (queryModel.queryText.length == 0) {
        NSLog(@"queryText is empty");
        return;
    }
    
    //    NSLog(@"query service: %@", service.serviceType);
    
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
//    NSLog(@"tableView for row: %ld", row);
    
    if (row == 0) {
        self.queryView = [self createQueryView];
        self.queryView.windowType = self.windowType;
        [self.queryView initializeAimatedButtonAlphaValue:self.queryModel];
        self.queryView.queryModel = self.queryModel;
        return self.queryView;
    }
    
    if (self.windowType != EZWindowTypeMini && row == 1) {
        EZSelectLanguageCell *selectLanguageCell = [self.tableView makeViewWithIdentifier:EZSelectLanguageCellId owner:self];
        if (!selectLanguageCell) {
            selectLanguageCell = [[EZSelectLanguageCell alloc] initWithFrame:[self tableViewContentBounds]];
            selectLanguageCell.identifier = EZSelectLanguageCellId;
        }
        selectLanguageCell.queryModel = self.queryModel;
        self.selectLanguageCell = selectLanguageCell;
        
        mm_weakify(self);
        [selectLanguageCell setEnterActionBlock:^(EZLanguage _Nonnull from, EZLanguage _Nonnull to) {
            mm_strongify(self);
            self.queryModel.userSourceLanguage = from;
            self.queryModel.userTargetLanguage = to;
            
            [self retryQuery];
        }];
        return selectLanguageCell;
    }
    
    EZResultView *resultCell = [self resultCellAtRow:row];
    return resultCell;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [[EZTableRowView alloc] init];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    CGFloat height;
    
    if (row == 0) {
        height = self.queryModel.queryViewHeight;
    } else if (row == 1 && self.windowType != EZWindowTypeMini) {
        height = 35;
    } else {
        EZQueryResult *result = [self serviceAtRow:row].result;
        if (result.isShowing) {
            // A non-zero value must be set, but the initial viewHeight is 0.
            height = MAX(result.viewHeight, EZResultViewMiniHeight);
        } else {
            height = EZResultViewMiniHeight;
        }
    }
    //        NSLog(@"row: %ld, height: %@", row, @(height));
    
    return height;
}

// Disable select cell
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}


#pragma mark - Update TableView and row cell.

/// Reset tableView, reloadData
- (void)resetTableView:(void (^)(void))completion {
    [self resetQueryAndResults];
    [self reloadTableViewData:completion];
}

/// TableView reloadData, and update window height.
- (void)reloadTableViewData:(void (^)(void))completion {
    [self reloadTableViewDataWithLock:YES completion:completion];
}

- (void)reloadTableViewDataWithLock:(BOOL)lockFlag completion:(void (^)(void))completion {
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self updateWindowViewHeightWithLock:lockFlag animate:NO display:YES];
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
    [self updateCellWithResults:@[ result ] reloadData:reloadData completionHandler:nil];
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
    //    NSLog(@"updateTableViewRowIndexes: %@", rowIndexes);
    
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
            // !!!: Must first notify the update tableView cell height, and then calculate the tableView height.
            //        NSLog(@"noteHeightOfRowsWithIndexesChanged: %@", rowIndexes);
            [self.tableView noteHeightOfRowsWithIndexesChanged:rowIndexes];
            [self updateWindowViewHeight];
        } completionHandler:^{
            //        NSLog(@"completionHandler, updateTableViewRowIndexes: %@", rowIndexes);
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
    NSIndexSet *firstIndexSet = [NSIndexSet indexSetWithIndex:0];
    [self updateTableViewRowIndexes:firstIndexSet reloadData:NO animate:animateFlag completionHandler:completionHandler];
}

- (void)updateSelectLanguageCell {
    NSInteger offset = [self resultCellOffset];
    if (offset == 1) {
        return;
    }
    
    NSIndexSet *rowIndexes = [NSMutableIndexSet indexSetWithIndex:offset - 1];
    [self.tableView reloadDataForRowIndexes:rowIndexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
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

- (void)updateAllResultCellHeight {
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
    EZServiceType serviceType = result.serviceType;
    // Sometimes the query is very slow, and at that time the user may have turned off the service in the settings page.
    NSInteger row = [self.serviceTypes indexOfObject:serviceType];
    return row;
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
        EZQueryResult *result = [self resetServiceResult:service];
        [allResults addObject:result];
    }
    return allResults;
}

- (EZQueryResult *)resetServiceResult:(EZQueryService *)service {
    EZQueryResult *result = service.result;
    [result reset];
    if (!result) {
        result = [[EZQueryResult alloc] init];
    }
    
    NSArray *enabledReplaceTypes = @[
        EZActionTypeAutoSelectQuery,
        EZActionTypeShortcutQuery,
        EZActionTypeInvokeQuery,
    ];
    if ([enabledReplaceTypes containsObject:self.queryModel.actionType]) {
        result.showReplaceButton = EZEventMonitor.shared.isSelectedTextEditable;
    } else {
        result.showReplaceButton = NO;
    }
    
    service.result = result;
    return result;
}

- (nullable EZResultView *)resultCellOfResult:(EZQueryResult *)result {
    NSInteger index = [self.services indexOfObject:result.service];
    NSInteger row = index + [self resultCellOffset];
    
    EZResultView *resultCell = [[[self.tableView rowViewAtRow:row makeIfNecessary:NO] subviews] firstObject];
    
    // ???: Why is it possible to return a EZSelectLanguageCell ?
    if ([resultCell isKindOfClass:[EZResultView class]]) {
        return resultCell;
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
        //        NSLog(@"UpdateQueryTextBlock");
        
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
        [self startQueryText:text];
    }];
    
    [queryView setPasteTextBlock:^(NSString *_Nonnull text) {
        mm_strongify(self);
        [self detectQueryText:^(NSString *_Nonnull language) {
            if ([EZConfiguration.shared autoQueryPastedText]) {
                [self startQueryWithType:EZActionTypeInputQuery];
            }
        }];
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
        [self clearAll];
    }];
    
    [queryView setSelectedLanguageBlock:^(EZLanguage language) {
        mm_strongify(self);
        
        EZLanguage detectedLanguage = self.queryModel.detectedLanguage;
        if (![detectedLanguage isEqualToString:language]) {
            self.queryModel.detectedLanguage = language;
            [self retryQuery];
            
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
        
        // Make enabledQuery = YES before retry, it may be closed manually.
        service.enabledQuery = YES;
        
        EZQueryResult *newResult = [self resetServiceResult:service];
        [self updateCellWithResult:newResult reloadData:YES completionHandler:^{
            [self queryWithModel:self.queryModel service:service autoPlay:NO];
        }];
    }];
    
    // !!!: Avoid capture result, the block paramter result is different from former result.
    [resultView setClickArrowBlock:^(EZQueryResult *newResult) {
        mm_strongify(self);
        BOOL isShowing = newResult.isShowing;
        if (!isShowing) {
            [newResult.service.audioPlayer stop];
        }
        
        service.enabledQuery = isShowing;
        
        // If result is not empty, update cell and show.
        if (isShowing && !newResult.hasShowingResult) {
            if (self.queryModel.needDetectLanguage) {
                [self detectQueryText:^(NSString *_Nonnull language) {
                    [self queryWithModel:self.queryModel service:service autoPlay:NO];
                }];
            } else {
                [self queryWithModel:self.queryModel service:service autoPlay:NO];
            }
        } else {
            [self updateCellWithResult:newResult reloadData:YES];
            
            // if hide result view, we need to notify to update reused cell height.
            if (!isShowing) {
                [self.tableView reloadData];
            }
        }
    }];
}

- (NSInteger)resultCellOffset {
    NSInteger offset;
    switch (self.windowType) {
        case EZWindowTypeMini: {
            offset = 1;
            break;
        }
        case EZWindowTypeMain:
        case EZWindowTypeFixed: {
            offset = 2;
            break;
        }
        default: {
            offset = 2;
        }
    }
    
    return offset;
}

- (EZQueryService *)serviceAtRow:(NSInteger)row {
    NSInteger index = row - [self resultCellOffset];
    EZQueryService *service = self.services[index];
    return service;
}

- (nullable EZQueryService *)serviceWithType:(EZServiceType)serviceType {
    NSInteger index = [self.serviceTypes indexOfObject:serviceType];
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

- (void)updateWindowViewHeight {
    [self updateWindowViewHeightWithAnimation:NO display:YES];
}

- (void)updateWindowViewHeightWithAnimation:(BOOL)animateFlag display:(BOOL)displayFlag {
    [self updateWindowViewHeightWithLock:YES animate:animateFlag display:displayFlag];
}

- (void)updateWindowViewHeightWithLock:(BOOL)lockFlag
                               animate:(BOOL)animateFlag
                               display:(BOOL)displayFlag {
    if (lockFlag) {
        self.lockResizeWindow = YES;
    }
    
    //    NSLog(@"updateWindowViewHeightWithLock");
    
    CGFloat tableViewHeight = [self getScrollViewContentHeight];
    CGFloat height = [self getRestrainedScrollViewHeight:tableViewHeight];
    //            NSLog(@"getRestrainedScrollViewHeight: %@", @(height));
    
    CGSize maxWindowSize = [EZLayoutManager.shared maximumWindowSize:self.windowType];
    
    CGFloat titleBarHeight = EZTitlebarHeight_28; // system title bar height is 28
    
    CGFloat scrollViewHeight = height + self.scrollView.contentInsets.top + self.scrollView.contentInsets.bottom;
    scrollViewHeight = MIN(scrollViewHeight, maxWindowSize.height - titleBarHeight);
    
    // Diable change window height manually.
    [self.scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_greaterThanOrEqualTo(scrollViewHeight);
        make.height.mas_lessThanOrEqualTo(scrollViewHeight);
    }];
    
    CGFloat showingWindowHeight = scrollViewHeight + titleBarHeight;
    showingWindowHeight = MIN(showingWindowHeight, maxWindowSize.height);
    
    // Since chaneg height will cause position change, we need to adjust y to keep top-left coordinate position.
    NSWindow *window = self.view.window;
    
    CGFloat deltaHeight = window.height - showingWindowHeight;
    CGFloat y = window.y + deltaHeight;
    
    CGRect newFrame = CGRectMake(window.x, y, window.width, showingWindowHeight);
    CGRect safeFrame = [EZCoordinateUtils getSafeAreaFrame:newFrame inScreen:nil];
    
    // ???: why set window frame will change tableView height?
    // ???: why this window animation will block cell rendering?
    //    [self.window setFrame:safeFrame display:NO animate:animateFlag];
    [self.baseQueryWindow setFrame:safeFrame display:NO];
    
    // Restore tableView height.
    self.tableView.height = tableViewHeight;
    
    if (animateFlag) {
        // Animation cost time.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(EZUpdateTableViewRowHeightAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.lockResizeWindow = NO;
        });
    } else {
        self.lockResizeWindow = NO;
    }
    
    //    NSLog(@"window frame: %@", @(window.frame));
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
        //        NSLog(@"row: %d, Height: %.1f", i, rowHeight);
        scrollViewContentHeight += (rowHeight + EZVerticalCellSpacing_7);
    }
    //    NSLog(@"scrollViewContentHeight: %.1f", scrollViewContentHeight);
    
    return scrollViewContentHeight;
}

/// Auto calculate documentView height.
- (CGFloat)getContentHeight {
    // Modify scrollView height to 0, to get actual tableView content height, avoid blank view.
    self.scrollView.height = 0;
    
    CGFloat documentViewHeight = self.scrollView.documentView.height; // actually is tableView height
    //    NSLog(@"documentView height: %@", @(documentViewHeight));
    
    return documentViewHeight;
}

- (CGFloat)miniQueryViewHeight {
    CGFloat miniInputViewHeight = [[EZLayoutManager shared] inputViewMinHeight:self.windowType];
    CGFloat queryViewHeight = miniInputViewHeight + EZQueryViewExceptInputViewHeight;
    return queryViewHeight;
}

#pragma mark - Auto play English word

- (void)autoPlayEnglishWordAudio {
    if (!EZConfiguration.shared.autoPlayAudio) {
        return;
    }
    
    BOOL isEnglishWord = [self.queryText isEnglishWordWithLanguage:self.queryModel.queryFromLanguage];
    
    if (!isEnglishWord) {
        NSLog(@"Not an English Word");
        return;
    }
    
    [self togglePlayQueryText:YES];
}

#pragma mark -

/// Auto copy translated text.
- (void)autoCopyTranslatedTextOfService:(EZQueryService *)service {
    if (![EZConfiguration.shared autoCopyFirstTranslatedText]) {
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

@end
