//
//  MainTabViewController.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZBaseQueryViewController.h"
#import "BaiduTranslate.h"
#import "YoudaoTranslate.h"
#import "GoogleTranslate.h"
#import "Configuration.h"
#import "NSColor+MyColors.h"
#import "EZQueryCell.h"
#import "EZResultCell.h"
#import "EZDetectManager.h"
#import <AVFoundation/AVFoundation.h>
#import "EZServiceTypes.h"
#import "EZQueryView.h"
#import "EZResultView.h"
#import "EZTitlebar.h"
#import "EZQueryModel.h"
#import "EZSelectLanguageCell.h"
#import "EZServiceStorage.h"
#import <KVOController/KVOController.h>
#import "EZCoordinateTool.h"
#import "EZBaseQueryWindow.h"
#include <Carbon/Carbon.h>
#import "EZWindowManager.h"
#import "EZAppleService.h"

static NSString * const EZQueryCellId = @"EZQueryCellId";
static NSString * const EZSelectLanguageCellId = @"EZSelectLanguageCellId";
static NSString * const EZResultCellId = @"EZResultCellId";

static NSString * const EZColumnId = @"EZColumnId";

static NSString * const EZQueryKey = @"{Query}";

static NSTimeInterval const kDelayUpdateWindowViewTime = 0.1;
static NSTimeInterval const kUpdateTableViewRowHeightAnimationDuration = 0.3;

@interface EZBaseQueryViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) EZTitlebar *titleBar;

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSTableColumn *column;

@property (nonatomic, strong) NSArray<EZServiceType> *serviceTypes;
@property (nonatomic, strong) NSArray<TranslateService *> *services;
@property (nonatomic, strong) EZQueryModel *queryModel;

@property (nonatomic, copy) NSString *queryText;

@property (nonatomic, strong) EZDetectManager *detectManager;
@property (nonatomic, strong) EZQueryCell *queryCell;
@property (nonatomic, strong) EZQueryView *queryView;
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) FBKVOController *kvo;

@property (nonatomic, assign) BOOL enableResizeWindow;

@end

@implementation EZBaseQueryViewController

- (instancetype)initWithWindowType:(EZWindowType)type {
    if (self = [super init]) {
        self.windowType = type;
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
        x.layer.backgroundColor = NSColor.mainViewBgLightColor.CGColor;
    } drak:^(NSView *_Nonnull x) {
        x.layer.backgroundColor = NSColor.mainViewBgDarkColor.CGColor;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    
    [self updateWindowViewHeightWithLock];
}

- (void)viewDidLayout {
    [self setupTitlebarActions];
}

- (void)setupTitlebarActions {
    mm_weakify(self);
    
    [self.window.titleBar.eudicButton setClickBlock:^(EZButton * _Nonnull button) {
        mm_strongify(self);
        [self openUrl:[ NSString stringWithFormat:@"eudic://dict/%@", EZQueryKey]];
    }];
    
    [self.window.titleBar.chromeButton setClickBlock:^(EZButton * _Nonnull button) {
        mm_strongify(self);
        [self openUrl:[ NSString stringWithFormat:@"https://www.google.com/search?q=%@", EZQueryKey]];
    }];
}

- (void)openUrl:(NSString *)urlString {
    NSString *queryText = self.queryModel.queryText ?: @"";
    urlString = [urlString stringByReplacingOccurrencesOfString:EZQueryKey withString:@"%@"];
    
    NSString *url = [NSString stringWithFormat:urlString, queryText];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSLog(@"open url: %@", url);
    
    BOOL success = [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    if (success) {
        [[EZWindowManager shared] closeFloatingWindow];
    }
}

- (void)resetQueryResults {
    self.queryText = @"";
        
    for (TranslateService *service in self.services) {
        TranslateResult *result = [[TranslateResult alloc] init];
        service.result = result;
        result.isShowing = NO; // default not show, show result after querying.
    }
}

- (void)setup {
    self.serviceTypes = @[
        EZServiceTypeGoogle,
        EZServiceTypeYoudao,
        EZServiceTypeBaidu,
    ];
    
    NSMutableArray *translateServices = [NSMutableArray array];
    for (EZServiceType type in self.serviceTypes) {
        TranslateService *service = [EZServiceTypes serviceWithType:type];
        [translateServices addObject:service];
    }
    self.services = translateServices;
    
    self.queryModel = [[EZQueryModel alloc] init];
    self.detectManager = [EZDetectManager managerWithModel:self.queryModel];
    
    [self resetQueryResults];

    self.player = [[AVPlayer alloc] init];
    
    [self tableView];
    
    mm_weakify(self);
    [self setResizeWindowBlock:^{
        mm_strongify(self);
        
        // Avoid recycling call, resize window --> update window height --> resize window
        if (!self.enableResizeWindow) {
            return;
        }
        
        [self reloadTableViewData:^{
            [self delayUpdateWindowViewHeight];
        }];
    }];
    
    self.kvo = [FBKVOController controllerWithObserver:self];
    [self.kvo observe:self
              keyPath:@"queryText"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                block:^(id _Nullable observer, id _Nonnull object, NSDictionary<NSString *, id> *_Nonnull change) {
//        NSLog(@"change: %@", change);
        
//        NSString *queryText = change[NSKeyValueChangeNewKey];
    }];
}


#pragma mark - Setter && Getter

- (void)setQueryText:(NSString *)queryText {
    _queryText = queryText;
    
    if (queryText.length == 0) {
        [self.queryModel reset];
    }
    
    self.queryModel.queryText = queryText;
    self.queryView.queryModel = self.queryModel;
}

- (NSScrollView *)scrollView {
    if (!_scrollView) {
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:scrollView];
        _scrollView = scrollView;
        
        scrollView.wantsLayer = YES;
        scrollView.layer.cornerRadius = EZCornerRadius_8;
        [scrollView excuteLight:^(NSScrollView *scrollView) {
            scrollView.backgroundColor = NSColor.mainViewBgLightColor;
        } drak:^(NSScrollView *scrollView) {
            scrollView.backgroundColor = NSColor.mainViewBgDarkColor;
        }];
        
        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(0);
            make.left.right.bottom.equalTo(self.view);
            
            CGSize miniWindowSize = [EZLayoutManager.shared minimumWindowSize:self.windowType];;
            make.width.mas_greaterThanOrEqualTo(miniWindowSize.width);
            make.height.mas_greaterThanOrEqualTo(miniWindowSize.height);
        }];
        
        scrollView.hasVerticalScroller = YES;
        scrollView.verticalScroller.controlSize = NSControlSizeSmall;
        [scrollView setAutomaticallyAdjustsContentInsets:NO];
        
        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, 7, 0);
    }
    return _scrollView;
}

- (NSTableView *)tableView {
    if (!_tableView) {
        NSTableView *tableView = [[NSTableView alloc] initWithFrame:self.scrollView.bounds];
        _tableView = tableView;
        
        [tableView excuteLight:^(NSTableView *tableView) {
            tableView.backgroundColor = NSColor.mainViewBgLightColor;
        } drak:^(NSTableView *tableView) {
            tableView.backgroundColor = NSColor.mainViewBgDarkColor;
        }];
        
        if (@available(macOS 11.0, *)) {
            tableView.style = NSTableViewStylePlain;
        } else {
            // Fallback on earlier versions
        }
        
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:EZColumnId];
        self.column = column;
        column.resizingMask = NSTableColumnUserResizingMask | NSTableColumnAutoresizingMask;
        [tableView addTableColumn:column];
        
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 100;
        [tableView setAutoresizesSubviews:YES];
        [tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
        
        tableView.headerView = nil;
        tableView.intercellSpacing = CGSizeMake(2 * EZMiniHorizontalMargin_12, EZMiniVerticalMargin_8);
        tableView.gridColor = NSColor.clearColor;
        tableView.gridStyleMask = NSTableViewGridNone;
        [tableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask | NSTableViewSolidHorizontalGridLineMask];
        self.scrollView.documentView = tableView;
        [tableView sizeLastColumnToFit]; // must put in the end
    }
    return _tableView;
}

- (EZQueryCell *)queryCell {
    if (!_queryCell) {
        _queryCell = [self createQueryCell];
    }
    return _queryCell;
}

#pragma mark - Public Methods

- (void)startQueryText:(NSString *)text {
    // !!!:  deep copy text, because text will be released in resetQueryResults.
    NSString *queryText = [text mutableCopy];
    
    if (text.length == 0) {
        NSLog(@"query text length = 0");
        return;
    }
    
    NSLog(@"query text: %@", text);
    
    // Close all resultView before querying new text
    [self closeAllResultView:^{
        self.queryText = queryText;
        [self queryCurrentModel];
    }];
}

- (void)startQueryWithImage:(NSImage *)image {
    NSLog(@"startQueryImage");
    
    mm_weakify(self);
    
    TranslateService *appleService = [[EZAppleService alloc] init];
    [appleService ocr:image from:Configuration.shared.from to:Configuration.shared.to completion:^(OCRResult * _Nullable ocrResult, NSError * _Nullable error) {
        mm_strongify(self);
        
        NSString *ocrText = ocrResult.mergedText;
        self.queryText = ocrText;
        NSLog(@"ocr text: %@", ocrText);
        
//        [self queryText:ocrText];
    }];
}

- (void)retry {
    NSLog(@"retry");
    [self startQueryText];
}

- (void)focusInputTextView {
    // Need to activate the current application first.
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    
    [self.window makeFirstResponder:self.queryView.textView];
}


#pragma mark - Query Methods

- (void)startQueryText {
    [self startQueryText:self.queryModel.queryText];
}

- (void)queryCurrentModel {
    if (self.queryModel.targetLanguage != Language_auto) {
        [self queryAllSerives:self.queryModel];
        return;
    }
    
    [self.detectManager detect:^(EZQueryModel * _Nonnull queryModel, NSError * _Nullable error) {
        self.queryView.queryModel = queryModel;
        [self queryAllSerives:queryModel];
    }];
}

- (void)queryAllSerives:(EZQueryModel *)queryModel  {
    for (TranslateService *service in self.services) {
        [self queryWithModel:queryModel serive:service completion:^(TranslateResult * _Nullable result, NSError * _Nullable error) {
            if (!result) {
                NSLog(@"result is nil, error: %@", error);
                return;
            }
            [self updateCellWithResult:result reloadData:YES completionHandler:nil];
        }];
    }
}

- (void)queryWithModel:(EZQueryModel *)queryModel
                serive:(TranslateService *)service
            completion:(nonnull void (^)(TranslateResult *_Nullable result, NSError *_Nullable error))completion {
    if (!service.enabled) {
        NSLog(@"service disabled: %@", service);
        return;
    }
    
    // Show result if it has been queried.
    service.result.isShowing = YES;
    [service translate:queryModel.queryText
                  from:queryModel.sourceLanguage
                    to:queryModel.targetLanguage
            completion:completion];
}


#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.services.count + [self resultCellOffset];
}

#pragma mark - NSTableViewDelegate

// View-base 设置某个元素的具体视图
- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    //    NSLog(@"tableView for row: %ld", row);
    
    // TODO: should reuse cell.
    if (row == 0) {
        EZQueryCell *queryCell = [self createQueryCell];
        self.queryView = queryCell.queryView;
        self.queryView.windowType = self.windowType;
        self.queryView.queryModel = self.queryModel;
        self.queryCell = queryCell;
        return queryCell;
    }
    
    if (self.windowType != EZWindowTypeMini && row == 1) {
        EZSelectLanguageCell *selectCell = [[EZSelectLanguageCell alloc] initWithFrame:[self tableViewContentBounds]];
        return selectCell;
    }
    
    EZResultCell *resultCell = [self resultCellAtRow:row];
    return resultCell;
}

// TODO: cache height, only calculate once.
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    CGFloat height;
    
    if (row == 0) {
        if (self.queryModel.viewHeight) {
            height = self.queryModel.viewHeight;
        } else {
            @autoreleasepool {
                EZQueryCell *queryCell = [[EZQueryCell alloc] initWithFrame:[self tableViewContentBounds]];
                EZQueryView *queryView = queryCell.queryView;
                queryView.windowType = self.windowType;
                queryView.queryModel = self.queryModel;
                height = [queryView heightOfQueryView];
            }
        }
    } else if (self.windowType != EZWindowTypeMini && row == 1) {
        height = 35;
    } else {
        TranslateService *service = [self serviceAtRow:row];
        if (service.result && !service.result.isShowing) {
            height = kResultViewMiniHeight;
        } else {
            EZResultCell *resultCell = [self resultCellAtRow:row];
            height = [resultCell fittingSize].height ?: kResultViewMiniHeight;
        }
        service.result.cellHeight = height;
    }
    
    //    NSLog(@"row: %ld, height: %@", row, @(height));
    
    return height;
}

// Disable select cell
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}


#pragma mark - Update TableView

- (void)resetTableView:(void (^)(void))completion {
    [self resetQueryResults];
    [self reloadTableViewData:completion];
}

- (void)reloadTableViewData:(void (^)(void))completion {
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self updateWindowViewHeightWithLock];
        if (completion) {
            completion();
        }
    }];
    
    [self.tableView reloadData];
    [CATransaction commit];
}


- (void)updateTableViewWithAnimation:(nullable void (^)(void))completion {
    NSMutableArray *results = [NSMutableArray array];
    for (TranslateService *service in self.services) {
        [results addObject:service.result];
    }
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        if (completion) {
            completion();
        }
    }];
    
    NSIndexSet *firstIndexSet = [NSIndexSet indexSetWithIndex:0];

    // Avoid blocking when delete text in query text, so set NO reloadData, we update query cell manually
    [self updateTableViewRowIndexes:firstIndexSet reloadData:NO];
    
    // Need to reload cell data, especially arrow button state.
    [self updateCellWithResults:results reloadData:YES];
    
    [CATransaction commit];
}

- (void)closeAllResultView:(void (^)(void))completionHandler {
    NSArray *closingResults = [self needUpdateClosedResults];
    [self updateCellWithResults:closingResults reloadData:YES completionHandler:completionHandler];
}


- (void)updateCellWithResult:(TranslateResult *)result reloadData:(BOOL)reloadData {
    [self updateCellWithResults:@[ result ] reloadData:reloadData completionHandler:nil];
}

- (void)updateCellWithResult:(TranslateResult *)result reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {
    if (!result) {
        NSLog(@"resutl is nil");
        return;
    }
    [self updateCellWithResults:@[ result ] reloadData:reloadData completionHandler:nil];
}

- (void)updateCellWithResults:(NSArray<TranslateResult *> *)results reloadData:(BOOL)reloadData {
    [self updateCellWithResults:results reloadData:reloadData completionHandler:nil];
}

- (void)updateCellWithResults:(NSArray<TranslateResult *> *)results reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    for (TranslateResult *result in results) {
        EZServiceType serviceType = result.serviceType;
        NSInteger row = [self.serviceTypes indexOfObject:serviceType];
        [rowIndexes addIndex:row + [self resultCellOffset]];
    }
    [self updateTableViewRowIndexes:rowIndexes reloadData:reloadData completionHandler:completionHandler];
}


- (void)updateTableViewRowIndexes:(NSIndexSet *)rowIndexes reloadData:(BOOL)reloadData  {
    [self updateTableViewRowIndexes:rowIndexes reloadData:reloadData completionHandler:nil];
}

- (void)updateTableViewRowIndexes:(NSIndexSet *)rowIndexes reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {
    if (reloadData) {
        [self.tableView reloadDataForRowIndexes:rowIndexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
        context.duration = kUpdateTableViewRowHeightAnimationDuration;
        [self.tableView noteHeightOfRowsWithIndexesChanged:rowIndexes];
    } completionHandler:^{
        [self updateWindowViewHeightWithLock];
        
        if (completionHandler) {
            completionHandler();
        }
    }];
}

- (NSArray *)needUpdateClosedResults {
    NSMutableArray *results = [NSMutableArray array];
    for (TranslateService *service in self.services) {
        TranslateResult *result = service.result;
        if (result.isShowing) {
            result.isShowing = NO;
            [results addObject:result];
        }
    }
    return results;
}

#pragma mark -

// Get tableView bounds in real time.
- (CGRect)tableViewContentBounds {
    CGRect rect = CGRectMake(0, 0, self.scrollView.width - 2 * EZMiniHorizontalMargin_12, self.scrollView.height);
    return rect;
}

- (EZQueryCell *)createQueryCell {
    EZQueryCell *queryCell = [[EZQueryCell alloc] initWithFrame:[self tableViewContentBounds]];
    queryCell.identifier = EZQueryCellId;
    
    EZQueryView *queryView = queryCell.queryView;
    
    mm_weakify(self);
    [queryView setUpdateQueryTextBlock:^(NSString *_Nonnull text, CGFloat queryViewHeight) {
        mm_strongify(self);
        
        self.queryText = text;

        // Reduce the update frequency, update only when the height changes.
        if (queryViewHeight != self.queryModel.viewHeight) {
            self.queryModel.viewHeight = queryViewHeight;
            
            NSIndexSet *firstIndexSet = [NSIndexSet indexSetWithIndex:0];
            
            // !!!: Avoid blocking when deleting text continuously in query text, so set NO reloadData, we update query cell manually.
            [self updateTableViewRowIndexes:firstIndexSet reloadData:NO completionHandler:nil];
        }
    }];
    
    [queryView setEnterActionBlock:^(NSString *text) {
        mm_strongify(self);
        [self startQueryText:text];
    }];
    
    [queryView setPlayAudioBlock:^(NSString *text) {
        mm_strongify(self);
        TranslateService *service = [self firstTranslateService];
        if (service) {
            Language lang = self.queryModel.sourceLanguage;
            [service audio:self.queryModel.queryText from:lang completion:^(NSString *_Nullable url, NSError *_Nullable error) {
                if (url.length) {
                    [self playAudioWithURL:url];
                }
            }];
        }
    }];
    
    [queryView setCopyTextBlock:^(NSString *text) {
        mm_strongify(self);
        [self copyTextToPasteboard:text];
    }];
    
    [queryView setClearBlock:^(NSString * _Nonnull text) {
        mm_strongify(self);
        [self resetQueryResults];
        [self updateTableViewWithAnimation:nil];
    }];
    
    return queryCell;
}

- (TranslateService *_Nullable)firstTranslateService {
    for (TranslateService *service in self.services) {
        return service;
    }
    return nil;
}

- (EZResultCell *)resultCellAtRow:(NSInteger)row {
    EZResultCell *resultCell = [[EZResultCell alloc] initWithFrame:[self tableViewContentBounds]];
    resultCell.identifier = EZResultCellId;
    
    TranslateService *service = [self serviceAtRow:row];
    resultCell.result = service.result;
    [self setupResultCell:resultCell];
    
    return resultCell;
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
        }
        default:
            break;
    }
    
    return offset;
}

- (TranslateService *)serviceAtRow:(NSInteger)row {
    NSInteger index = row - [self resultCellOffset];
    TranslateService *service = self.services[index];
    return service;
}

- (TranslateService *)serviceWithType:(EZServiceType)serviceType {
    NSInteger index = [self.serviceTypes indexOfObject:serviceType];
    return self.services[index];
}

- (void)setupResultCell:(EZResultCell *)resultCell {
    EZResultView *resultView = resultCell.resultView;
    TranslateResult *result = resultCell.result;
    TranslateService *serive = [self serviceWithType:result.serviceType];
    
    mm_weakify(self)
    [resultView setPlayAudioBlock:^(NSString *_Nonnull text) {
        mm_strongify(self);
        if (!result) {
            return;
        }
        
        [self playSeriveAudio:serive text:text lang:result.from];
    }];
    
    [resultView setCopyTextBlock:^(NSString *_Nonnull text) {
        mm_strongify(self);
        if (!result) {
            return;
        }
        [self copyTextToPasteboard:text];
    }];
    
    [resultView setClickArrowBlock:^(BOOL isShowing) {
        mm_strongify(self);
        TranslateService *service = [self serviceWithType:result.serviceType];
        service.enabled = isShowing;
        
        // If hasn't result, start querying
        if (!result.raw) {
            [service translate:self.queryModel.queryText
                          from:self.queryModel.sourceLanguage
                            to:Configuration.shared.to
                    completion:^(TranslateResult *_Nullable result, NSError *_Nullable error) {
                [self updateCellWithResult:result reloadData:YES completionHandler:nil];
            }];
        } else {
            [self updateCellWithResult:result reloadData:YES];
        }
    }];
}

- (void)playSeriveAudio:(TranslateService *)service textArray:(NSArray<NSString *> *)textArray lang:(Language)lang {
    NSString *text = [NSString mm_stringByCombineComponents:textArray separatedString:@"\n"];
    [self playSeriveAudio:service text:text lang:lang];
}

- (void)playSeriveAudio:(TranslateService *)service text:(NSString *)text lang:(Language)lang {
    if (text.length) {
        mm_weakify(self)
        [service audio:text from:lang completion:^(NSString *_Nullable url, NSError *_Nullable error) {
            mm_strongify(self);
            if (!error) {
                [self playAudioWithURL:url];
            } else {
                MMLogInfo(@"获取音频 URL 失败 %@", error);
            }
        }];
    }
}

- (void)copyTextToPasteboard:(NSString *)text {
    [NSPasteboard mm_generalPasteboardSetString:text];
}

- (void)playAudioWithURL:(NSString *)url {
    MMLogInfo(@"播放音频 %@", url);
    [self.player pause];
    if (!url.length) {
        return;
    }
    
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]]];
    [self.player play];
}

#pragma mark - Update Window Height

- (void)updateWindowViewHeightWithLock {
    [self updateWindowViewHeight:YES];
}

- (void)updateWindowViewHeight:(BOOL)lock {
    NSTimeInterval lockTime = 0.1;
    
    if (lock) {
        self.enableResizeWindow = NO;
    }
    
    CGFloat height = [self getScrollViewHeight];
    //    NSLog(@"contentHeight: %@", @(height));
    
    CGSize maxWindowSize = [EZLayoutManager.shared maximumWindowSize:self.windowType];
    
    CGFloat titleBarHeight = EZTitlebarHeight; // system title bar height is 28
    
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
    [window setFrame:newFrame display:YES];
    
    CGPoint safeLocation = [EZCoordinateTool getSafeLocation:window.frame];
    
    //    NSLog(@"window frame: %@", @(window.frame));
    //    NSLog(@"safe frame: %@", @(safeFrame));
    
    [window setFrameOrigin:safeLocation];
    
    if (lock) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(lockTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.enableResizeWindow = YES;
        });
    }
}

- (CGFloat)getScrollViewHeight {
    CGFloat height = [self getContentHeight];
    
    CGSize minimumWindowSize = [EZLayoutManager.shared minimumWindowSize:self.windowType];;
    CGSize maximumWindowSize = [EZLayoutManager.shared maximumWindowSize:self.windowType];;
    
    height = MAX(height, minimumWindowSize.height);
    height = MIN(height, maximumWindowSize.height);
    
    return height;
}

- (CGFloat)getContentHeight {
    // Modify scrollView height to 0, to get actual tableView content height, avoid blank view.
    self.scrollView.height = 0;
    
    CGFloat documentViewHeight = self.scrollView.documentView.height; // actually is tableView height
    //    NSLog(@"documentView height: %@", @(documentViewHeight));
    
    return documentViewHeight;
}

/// Delay update, to avoid reload tableView frequently.
- (void)delayUpdateWindowViewHeight {
    [self cancelUpdateWindowViewHeight];
    [self performSelector:@selector(updateWindowViewHeightWithLock) withObject:nil afterDelay:kDelayUpdateWindowViewTime];
}

- (void)cancelUpdateWindowViewHeight {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateWindowViewHeightWithLock) object:nil];
}

@end
