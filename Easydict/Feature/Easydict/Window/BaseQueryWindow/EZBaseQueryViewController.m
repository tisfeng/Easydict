//
//  MainTabViewController.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZBaseQueryViewController.h"
#import "EZQueryCell.h"
#import "EZResultCell.h"
#import "EZDetectManager.h"
#import <AVFoundation/AVFoundation.h>
#import "EZQueryView.h"
#import "EZResultView.h"
#import "EZQueryModel.h"
#import "EZSelectLanguageCell.h"
#import <KVOController/KVOController.h>
#import "EZCoordinateTool.h"
#import "EZWindowManager.h"
#import "EZServiceTypes.h"

static NSString * const EZQueryCellId = @"EZQueryCellId";
static NSString * const EZSelectLanguageCellId = @"EZSelectLanguageCellId";
static NSString * const EZResultCellId = @"EZResultCellId";

static NSString * const EZColumnId = @"EZColumnId";

static NSTimeInterval const kDelayUpdateWindowViewTime = 0.1;
static NSTimeInterval const kUpdateTableViewRowHeightAnimationDuration = 0.3;

@interface EZBaseQueryViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) EZTitlebar *titleBar;

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSTableColumn *column;

@property (nonatomic, strong) NSArray<EZServiceType> *serviceTypes;
@property (nonatomic, strong) NSArray<EZQueryService *> *services;
@property (nonatomic, strong) EZQueryModel *queryModel;

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

- (void)setup {
    self.queryModel = [[EZQueryModel alloc] init];
    self.detectManager = [EZDetectManager managerWithModel:self.queryModel];
    
    self.serviceTypes = @[
        EZServiceTypeGoogle,
        EZServiceTypeYoudao,
        EZServiceTypeBaidu,
    ];
    
    NSMutableArray *services = [NSMutableArray array];
    for (EZServiceType type in self.serviceTypes) {
        EZQueryService *service = [EZServiceTypes serviceWithType:type];
        service.queryModel = self.queryModel;
        [services addObject:service];
    }
    self.services = services;
    [self resetAllServiceResults];

    
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
    
//    self.kvo = [FBKVOController controllerWithObserver:self];
//    [self.kvo observe:self
//              keyPath:@"queryText"
//              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
//                block:^(id _Nullable observer, id _Nonnull object, NSDictionary<NSString *, id> *_Nonnull change) {
////        NSLog(@"change: %@", change);
//        
////        NSString *queryText = change[NSKeyValueChangeNewKey];
//    }];
}


#pragma mark - Setter && Getter

- (void)setQueryText:(NSString *)queryText {
    _queryText = queryText;
        
    if (queryText.length == 0) {
        self.queryModel.queryViewHeight = 0;
    }
    
    [self updateSelectLanguageCell];
    
    self.queryModel.queryText = queryText;
    self.queryView.queryModel = self.queryModel;
    
    if ([self allShowingResults].count > 0) {
        [self.queryView showClearButton:YES];
    }
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

/// Close all result view, then query text.
- (void)startQueryText:(NSString *)text {
    if (text.length == 0) {
        NSLog(@"query text is empty");
        return;
    }
    
    NSLog(@"query text: %@", text);
        
    // Close all resultView before querying new text.
    [self closeAllResultView:^{
        NSLog(@"close all result");
        self.queryText = text;
        [self queryCurrentModel];
    }];
}

- (void)startQueryWithImage:(NSImage *)image {
    NSLog(@"startQueryImage");
    
    mm_weakify(self);
    
    self.queryModel.image = image;
    
    [self.detectManager ocrAndDetectText:^(EZQueryModel * _Nonnull queryModel, NSError * _Nullable error) {
        mm_strongify(self);
        
        self.queryText = queryModel.queryText;
        NSLog(@"ocr text: %@", self.queryText);
    }];
}

- (void)retry {
    NSLog(@"retry");
    [self startQueryText];
}

- (void)focusInputTextView {
    // Need to activate the current application first.
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    
//    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];

    [self.window makeFirstResponder:self.queryView.textView];
}


#pragma mark - Query Methods

/// Close all result view, then query.
- (void)startQueryText {
    [self startQueryText:self.queryModel.queryText];
}

/// Directly query model.
- (void)queryCurrentModel {
    EZLanguage fromLanguage = self.queryModel.detectedLanguage;
    if ([fromLanguage isEqualToString:EZLanguageAuto]) {
        fromLanguage = self.queryModel.sourceLanguage;
    }
    
    if (![fromLanguage isEqualToString:EZLanguageAuto]) {
        [self queryAllSerives:self.queryModel];
        return;
    }
    
    [self.detectManager detectText:^(EZQueryModel * _Nonnull queryModel, NSError * _Nullable error) {
        self.queryView.queryModel = queryModel;
        [self updateSelectLanguageCell];
        [self queryAllSerives:queryModel];
    }];
}

- (void)queryAllSerives:(EZQueryModel *)queryModel  {
    NSLog(@"from-to: %@ --> %@", queryModel.queryFromLanguage, queryModel.autoTargetLanguage);

    for (EZQueryService *service in self.services) {
        [self queryWithModel:queryModel serive:service completion:^(EZQueryResult * _Nullable result, NSError * _Nullable error) {
            if (!result) {
                NSLog(@"result is nil, error: %@", error);
            }
            result.error = error;
            [self updateCellWithResult:result reloadData:YES completionHandler:nil];
        }];
    }
}

- (void)queryWithModel:(EZQueryModel *)queryModel
                serive:(EZQueryService *)service
            completion:(nonnull void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    if (!service.enabled) {
        NSLog(@"service disabled: %@", service.serviceType);
        return;
    }
    if (queryModel.queryText.length == 0) {
        NSLog(@"queryText is empty");
        return;
    }
    
    // Show result if it has been queried.
    service.result.isShowing = YES;

    NSLog(@"query service: %@", service.serviceType);
    
    [service translate:queryModel.queryText
                  from:queryModel.queryFromLanguage
                    to:queryModel.autoTargetLanguage
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
        EZSelectLanguageCell *selectLanguageCell = [[EZSelectLanguageCell alloc] initWithFrame:[self tableViewContentBounds]];
        selectLanguageCell.queryModel = self.queryModel;
        
        mm_weakify(self);
        [selectLanguageCell setEnterActionBlock:^(EZLanguage  _Nonnull from, EZLanguage  _Nonnull to) {
            mm_strongify(self);
            self.queryModel.sourceLanguage = from;
            self.queryModel.targetLanguage = to;
            self.queryModel.detectedLanguage = EZLanguageAuto;
            
            [self startQueryText];
        }];
        return selectLanguageCell;
    }
    
    EZResultCell *resultCell = [self resultCellAtRow:row];
    return resultCell;
}

// TODO: cache height, only calculate once.
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    CGFloat height;
    
    if (row == 0) {
        if (self.queryModel.queryViewHeight) {
            height = self.queryModel.queryViewHeight;
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
        EZQueryResult *result = [self serviceAtRow:row].result;
        if (!result.isShowing || result.isEmpty) {
            height = kResultViewMiniHeight;
        } else {
            EZResultCell *resultCell = [self resultCellAtRow:row];
            height = [resultCell fittingSize].height ?: kResultViewMiniHeight;
        }
        result.cellHeight = height;
    }
    
    //    NSLog(@"row: %ld, height: %@", row, @(height));
    
    return height;
}

// Disable select cell
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}


#pragma mark - Update TableView

- (void)resetAllServiceResults {
    for (EZQueryService *service in self.services) {
        EZQueryResult *result = [[EZQueryResult alloc] init];
        result.isShowing = NO; // default not show, show result after querying.
        service.result = result;
    }
    self.queryText = @"";
}

- (void)clearQueryResultsWithAnimation:(void (^)(void))completion {
    self.queryText = @"";
    
    // !!!: To show closing animation, we cannot reset result directly.
    [self closeAllResultView:^{
        [self resetAllServiceResults];
        if (completion) {
            completion();
        }
    }];
}

- (void)resetTableView:(void (^)(void))completion {
    [self resetAllServiceResults];
    [self reloadTableViewData:completion];
}

/// TableView reloadData
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

- (void)closeAllResultView:(void (^)(void))completionHandler {
    NSArray *closingResults = [self allShowingResults];
    [self closeAllShowingResults];
    [self updateCellWithResults:closingResults reloadData:YES completionHandler:completionHandler];
}


- (void)updateCellWithResult:(EZQueryResult *)result reloadData:(BOOL)reloadData {
    if (!result) {
        NSLog(@"resutl is nil");
        return;
    }
    [self updateCellWithResults:@[ result ] reloadData:reloadData completionHandler:nil];
}

- (void)updateCellWithResult:(EZQueryResult *)result reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {
    if (!result) {
        NSLog(@"resutl is nil");
        return;
    }
    [self updateCellWithResults:@[ result ] reloadData:reloadData completionHandler:nil];
}

- (void)updateCellWithResults:(NSArray<EZQueryResult *> *)results reloadData:(BOOL)reloadData {
    [self updateCellWithResults:results reloadData:reloadData completionHandler:nil];
}

- (void)updateCellWithResults:(NSArray<EZQueryResult *> *)results reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    for (EZQueryResult *result in results) {
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

- (void)updateSelectLanguageCell {
    NSInteger offset = [self resultCellOffset];
    if (offset == 1) {
        return;
    }
    
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSetWithIndex:offset - 1];
    [self.tableView reloadDataForRowIndexes:rowIndexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

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
    }
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
        
        // As soon as the input text changes, set detectedLanguage to Auto.
        self.queryModel.detectedLanguage = EZLanguageAuto;
        
        // !!!: text is from textView.string, it will be changed!
        self.queryText = [text mutableCopy];

        // Reduce the update frequency, update only when the height changes.
        if (queryViewHeight != self.queryModel.queryViewHeight) {
            self.queryModel.queryViewHeight = queryViewHeight;
            
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
        EZQueryService *service = [self firstEZQueryService];
        if (service) {
            EZLanguage lang = self.queryModel.sourceLanguage;
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
        [self clearQueryResultsWithAnimation:nil];
    }];
    
    [queryView setSelectedLanguageBlock:^(EZLanguage  _Nonnull language) {
        mm_strongify(self);
        self.queryModel.detectedLanguage = language;
        [self startQueryText];
    }];
    
    return queryCell;
}

- (EZQueryService *_Nullable)firstEZQueryService {
    for (EZQueryService *service in self.services) {
        return service;
    }
    return nil;
}

- (EZResultCell *)resultCellAtRow:(NSInteger)row {
    EZResultCell *resultCell = [[EZResultCell alloc] initWithFrame:[self tableViewContentBounds]];
    resultCell.identifier = EZResultCellId;
    
    EZQueryService *service = [self serviceAtRow:row];
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

- (EZQueryService *)serviceAtRow:(NSInteger)row {
    NSInteger index = row - [self resultCellOffset];
    EZQueryService *service = self.services[index];
    return service;
}

- (EZQueryService *)serviceWithType:(EZServiceType)serviceType {
    NSInteger index = [self.serviceTypes indexOfObject:serviceType];
    return self.services[index];
}

- (void)setupResultCell:(EZResultCell *)resultCell {
    EZResultView *resultView = resultCell.resultView;
    EZQueryResult *result = resultCell.result;
    EZQueryService *service = [self serviceWithType:result.serviceType];
    
    mm_weakify(self)
    [resultView setPlayAudioBlock:^(NSString *_Nonnull text) {
        mm_strongify(self);
        if (!result) {
            return;
        }
        
        [self playSeriveAudio:service text:text lang:result.from];
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
        service.enabled = isShowing;
        
        // If result is not empty, update cell and show.
        if (!result.isEmpty) {
            [self updateCellWithResult:result reloadData:YES];
            return;
        }
        
        [self queryWithModel:self.queryModel serive:service completion:^(EZQueryResult * _Nullable result, NSError * _Nullable error) {
            [self updateCellWithResult:result reloadData:YES];
        }];
    }];
}

- (void)playSeriveAudio:(EZQueryService *)service textArray:(NSArray<NSString *> *)textArray lang:(EZLanguage)lang {
    NSString *text = [NSString mm_stringByCombineComponents:textArray separatedString:@"\n"];
    [self playSeriveAudio:service text:text lang:lang];
}

- (void)playSeriveAudio:(EZQueryService *)service text:(NSString *)text lang:(EZLanguage)lang {
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
