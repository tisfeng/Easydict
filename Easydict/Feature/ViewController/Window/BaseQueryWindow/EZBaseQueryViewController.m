//
//  MainTabViewController.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZBaseQueryViewController.h"
#import "EZQueryCell.h"
#import "EZResultCell.h"
#import "EZDetectManager.h"
#import "EZQueryView.h"
#import "EZResultView.h"
#import "EZQueryModel.h"
#import "EZSelectLanguageCell.h"
#import <KVOController/KVOController.h>
#import "EZCoordinateTool.h"
#import "EZWindowManager.h"
#import "EZServiceTypes.h"
#import "EZAppleService.h"
#import "EZAudioPlayer.h"

static NSString *const EZQueryCellId = @"EZQueryCellId";
static NSString *const EZSelectLanguageCellId = @"EZSelectLanguageCellId";
static NSString *const EZResultCellId = @"EZResultCellId";

static NSString *const EZColumnId = @"EZColumnId";

static NSTimeInterval const kDelayUpdateWindowViewTime = 0.01;

@interface EZBaseQueryViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) EZTitlebar *titleBar;

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSTableColumn *column;

@property (nonatomic, strong) EZQueryCell *queryCell;
@property (nonatomic, strong) EZQueryView *queryView;


@property (nonatomic, strong) NSArray<EZServiceType> *serviceTypes;
@property (nonatomic, strong) NSArray<EZQueryService *> *services;
@property (nonatomic, strong) EZQueryModel *queryModel;

@property (nonatomic, strong) EZDetectManager *detectManager;
@property (nonatomic, strong) EZAudioPlayer *audioPlayer;


@property (nonatomic, strong) FBKVOController *kvo;

@property (nonatomic, assign) BOOL lockResizeWindow;

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
    [self updateWindowViewHeightWithAnimation:NO];
}


- (void)setup {
    self.queryModel = [[EZQueryModel alloc] init];
    self.queryModel.queryViewHeight = [self miniQueryViewHeight];
    
    self.detectManager = [EZDetectManager managerWithModel:self.queryModel];
    
    self.serviceTypes = @[
        EZServiceTypeGoogle,
        EZServiceTypeDeepL,
        EZServiceTypeBaidu,
        EZServiceTypeYoudao,
    ];
    
    NSMutableArray *services = [NSMutableArray array];
    for (EZServiceType type in self.serviceTypes) {
        EZQueryService *service = [EZServiceTypes serviceWithType:type];
        service.queryModel = self.queryModel;
        [services addObject:service];
    }
    self.services = services;
    [self resetQueryAndResults];
    
    [self tableView];
    
    self.audioPlayer = [[EZAudioPlayer alloc] init];
    
    mm_weakify(self);
    [self setResizeWindowBlock:^{
        mm_strongify(self);
        
        // Avoid recycling call, resize window --> update window height --> resize window
        if (self.lockResizeWindow) {
            //            NSLog(@"lockResizeWindow");
            return;
        }
        
        [self reloadTableViewDataWithLock:NO completion:^{
            // Update query view height manually, and update cell height.
            self.queryModel.queryViewHeight = [self.queryView heightOfQueryView];
            
            NSIndexSet *firstIndexSet = [NSIndexSet indexSetWithIndex:0];
            [self.tableView noteHeightOfRowsWithIndexesChanged:firstIndexSet];
            
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


#pragma mark - Getter && Setter

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
            
            CGSize miniWindowSize = [EZLayoutManager.shared minimumWindowSize:self.windowType];
            make.width.mas_greaterThanOrEqualTo(miniWindowSize.width);
            make.height.mas_greaterThanOrEqualTo(miniWindowSize.height);
        }];
        
        scrollView.hasVerticalScroller = YES;
        scrollView.verticalScroller.controlSize = NSControlSizeSmall;
        [scrollView setAutomaticallyAdjustsContentInsets:NO];
        
        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, 6, 0);
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
        tableView.intercellSpacing = CGSizeMake(2 * EZHorizontalCellSpacing_12, EZVerticalCellSpacing_8);
        tableView.gridColor = NSColor.clearColor;
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

- (void)setQueryText:(NSString *)queryText {
    // !!!: Avoid text being affected by input text.
    _queryText = [queryText copy];
    
    self.queryModel.queryText = queryText;
    
    if (self.queryText.length == 0) {
        self.queryModel.detectedLanguage = EZLanguageAuto;
        self.queryModel.queryViewHeight = [self miniQueryViewHeight];
        [self updateQueryViewModelAndDetectedLanguage:self.queryModel];
    } else {
        self.queryView.queryModel = self.queryModel;
        [self updateQueryCell];
    }
    
    if ([self allShowingResults].count > 0) {
        [self.queryView setClearButtonAnimatedHidden:NO];
    }
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
    
    self.queryModel.ocrImage = image;
    
    [self.detectManager ocrAndDetectText:^(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error) {
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
    // !!!: Reset all result before new query.
    [self resetAllResults];
    
    // There may be a detected language, but since there is a 1.0s delay in the `delayDetectQueryText` method, so it may be a previously leftover value, so we must re-detect the text language before each query.
    [self detectQueryText:^{
        [self queryAllSerives:self.queryModel];
    }];
}

- (void)queryAllSerives:(EZQueryModel *)queryModel {
    NSLog(@"query: %@ --> %@", queryModel.queryFromLanguage, queryModel.queryTargetLanguage);
    
    for (EZQueryService *service in self.services) {
        [self queryWithModel:queryModel serive:service completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
            if (error) {
                NSLog(@"query error: %@", error);
            }
            result.error = error;
            NSLog(@"service: %@, %@", service.serviceType, result);
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
    service.result.isLoading = YES;
    
    [self updateResultCell:service.result];
    
    NSLog(@"query service: %@", service.serviceType);
    
    [service translate:queryModel.queryText
                  from:queryModel.queryFromLanguage
                    to:queryModel.queryTargetLanguage
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
        [self.queryView initializeAimatedButtonAlphaValue:self.queryModel];
        self.queryView.queryModel = self.queryModel;
        self.queryCell = queryCell;
        
        return queryCell;
    }
    
    if (self.windowType != EZWindowTypeMini && row == 1) {
        EZSelectLanguageCell *selectLanguageCell = [[EZSelectLanguageCell alloc] initWithFrame:[self tableViewContentBounds]];
        selectLanguageCell.queryModel = self.queryModel;
        
        mm_weakify(self);
        [selectLanguageCell setEnterActionBlock:^(EZLanguage _Nonnull from, EZLanguage _Nonnull to) {
            mm_strongify(self);
            self.queryModel.userSourceLanguage = from;
            self.queryModel.userTargetLanguage = to;
            self.queryModel.detectedLanguage = EZLanguageAuto;
            
            [self startQueryText];
        }];
        return selectLanguageCell;
    }
    
    EZResultCell *resultCell = [self resultCellAtRow:row];
    return resultCell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    CGFloat height;
    
    if (row == 0) {
        height = self.queryModel.queryViewHeight;
    } else if (self.windowType != EZWindowTypeMini && row == 1) {
        height = 35;
    } else {
        EZQueryResult *result = [self serviceAtRow:row].result;
        // A non-zero value must be set, but the initial viewHeight is 0.
        height = MAX(result.viewHeight, kResultViewMiniHeight);
    }
    //    NSLog(@"row: %ld, height: %@", row, @(height));
    
    return height;
}

// Disable select cell
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}


#pragma mark - Update TableView

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
    NSArray *closingResults = [self allShowingResults];
    [self closeAllShowingResults];
    [self updateCellWithResults:closingResults reloadData:YES completionHandler:completionHandler];
}


- (void)updateCellWithResult:(EZQueryResult *)result reloadData:(BOOL)reloadData {
    [self updateCellWithResults:@[ result ] reloadData:reloadData completionHandler:nil];
}

- (void)updateCellWithResult:(EZQueryResult *)result reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {

    [self updateCellWithResults:@[ result ] reloadData:reloadData completionHandler:nil];
}

- (void)updateCellWithResults:(NSArray<EZQueryResult *> *)results reloadData:(BOOL)reloadData {
    [self updateCellWithResults:results reloadData:reloadData completionHandler:nil];
}

- (void)updateCellWithResults:(NSArray<EZQueryResult *> *)results reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    for (EZQueryResult *result in results) {
        result.isLoading = NO;
        EZServiceType serviceType = result.serviceType;
        NSInteger row = [self.serviceTypes indexOfObject:serviceType];
        [rowIndexes addIndex:row + [self resultCellOffset]];
    }
    [self updateTableViewRowIndexes:rowIndexes reloadData:reloadData completionHandler:completionHandler];
}

- (void)updateTableViewRowIndexes:(NSIndexSet *)rowIndexes reloadData:(BOOL)reloadData {
    [self updateTableViewRowIndexes:rowIndexes reloadData:reloadData completionHandler:nil];
}

/// Update tableView row data, update row height and window height with animation.
- (void)updateTableViewRowIndexes:(NSIndexSet *)rowIndexes reloadData:(BOOL)reloadData completionHandler:(void (^)(void))completionHandler {
    if (reloadData) {
        
        // !!!: Note: For NSView-based table views, this method drops the view-cells in the table row, but not the NSTableRowView instances.
        
        // ???: need to check.
        
        [self.tableView reloadDataForRowIndexes:rowIndexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
        context.duration = EZUpdateTableViewRowHeightAnimationDuration;
        // !!!: Must first notify the update tableView cell height, and then calculate the tableView height.
        [self.tableView noteHeightOfRowsWithIndexesChanged:rowIndexes];
//        NSLog(@"noteHeightOfRowsWithIndexesChanged: %@", rowIndexes);
        [self updateWindowViewHeightWithAnimation:YES];
    } completionHandler:^{
        if (completionHandler) {
            completionHandler();
        }
    }];
}

- (void)updateQueryCell {
    [self updateQueryCellWithCompletionHandler:nil];
}

/// Update query cell data and row height.
- (void)updateQueryCellWithCompletionHandler:(nullable void (^)(void))completionHandler {
    NSIndexSet *firstIndexSet = [NSIndexSet indexSetWithIndex:0];
    [self updateTableViewRowIndexes:firstIndexSet reloadData:NO completionHandler:completionHandler];
}

- (void)updateSelectLanguageCell {
    NSInteger offset = [self resultCellOffset];
    if (offset == 1) {
        return;
    }
    
    NSIndexSet *rowIndexes = [NSMutableIndexSet indexSetWithIndex:offset - 1];
    [self.tableView reloadDataForRowIndexes:rowIndexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

#pragma mark - Update Data.

- (void)resetQueryAndResults {
    [self resetAllResults];
    
    self.queryText = @"";
}

- (void)resetAllResults {
    for (EZQueryService *service in self.services) {
        EZQueryResult *result = service.result;
        [result reset];
        if (!service.result) {
            result = [[EZQueryResult alloc] init];
        }
        result.isShowing = NO; // default not show, show after querying if result is not empty.
        result.isLoading = NO;
        service.result = result;
        
        [self updateResultCell:service.result];
    }
}

- (void)updateResultCell:(EZQueryResult *)result {
    NSInteger index = [self.services indexOfObject:result.service];
    NSInteger row =  index + [self resultCellOffset];
    
    EZResultCell *resultCell = [[[self.tableView rowViewAtRow:row makeIfNecessary:NO] subviews] firstObject];
    resultCell.result = result;
}

- (void)delayDetectQueryText {
    [self cancelDelayDetectQueryText];
    [self performSelector:@selector(detectQueryText:) withObject:nil afterDelay:1.0];
}

- (void)cancelDelayDetectQueryText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(detectQueryText:) object:nil];
}

/// Detect query text, and update select language cell.
- (void)detectQueryText:(nullable void (^)(void))completion {
    [self.detectManager detectText:^(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error) {
        // `self.queryModel.detectedLanguage` has already been updated inside the method.
        
        [self updateQueryViewModelAndDetectedLanguage:queryModel];
        
        if (completion) {
            completion();
        }
    }];
}

- (void)updateQueryViewModelAndDetectedLanguage:(EZQueryModel *)queryModel {
    self.queryView.queryModel = queryModel;
    [self updateQueryCell];
    [self updateSelectLanguageCell];
}


// TODO: need to check, use true cell result, rather than self result
- (NSArray *)allShowingResults {
    NSMutableArray *results = [NSMutableArray array];
    
    //    NSInteger rowCount = [self.tableView numberOfRows];
    //    NSInteger startIndex = [self resultCellOffset];
    //    rowCount -= startIndex;
    //
    //    for (int i = (int)startIndex; i < rowCount; i++) {
    //        EZResultCell *resultCell = [[[self.tableView rowViewAtRow:i makeIfNecessary:NO] subviews] firstObject];
    //        EZQueryResult *result = resultCell.result;
    //        if (result.isShowing) {
    //            [results addObject:result];
    //        }
    //    }
    
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

#pragma mark -

// Get tableView bounds in real time.
- (CGRect)tableViewContentBounds {
    CGRect rect = CGRectMake(0, 0, self.scrollView.width - 2 * EZHorizontalCellSpacing_12, self.scrollView.height);
    return rect;
}

- (EZQueryCell *)createQueryCell {
    EZQueryCell *queryCell = [[EZQueryCell alloc] initWithFrame:[self tableViewContentBounds]];
    queryCell.identifier = EZQueryCellId;
    
    EZQueryView *queryView = queryCell.queryView;
    
    mm_weakify(self);
    [queryView setUpdateQueryTextBlock:^(NSString *_Nonnull text, CGFloat queryViewHeight) {
        mm_strongify(self);
        
        // !!!: The code here is a bit messy, so you need to be careful about changing it.
        
        // Since the query view is not currently reused, all views with the same content may be created and assigned multiple times, but this is actually unnecessary, so there is no need to update the content and height in this case.
        if ([self.queryText isEqualToString:text]) {
            return;
        }
        
        self.queryText = [NSString stringWithString:text];
        
        [self delayDetectQueryText];
        
        // Reduce the update frequency, update only when the height changes.
        if (queryViewHeight != self.queryModel.queryViewHeight) {
            self.queryModel.queryViewHeight = queryViewHeight;
            [self updateQueryCell];
        }
    }];
    
    [queryView setEnterActionBlock:^(NSString *text) {
        mm_strongify(self);
        [self startQueryText:text];
    }];
    
    [queryView setPlayAudioBlock:^(NSString *text) {
        mm_strongify(self);
        [self.audioPlayer  playSystemTextAudio:self.queryText fromLanguage:self.queryModel.queryFromLanguage];
    }];
    
    [queryView setCopyTextBlock:^(NSString *text) {
        mm_strongify(self);
        [self copyTextToPasteboard:text];
    }];
    
    [queryView setClearBlock:^(NSString *_Nonnull text) {
        mm_strongify(self);
        
        // Clear query text, detect language and clear button right now;
        self.queryText = @"";
        
        [self updateQueryCellWithCompletionHandler:^{
            // !!!: To show closing animation, we cannot reset result directly.
            [self closeAllResultView:^{
                [self resetQueryAndResults];
            }];
        }];
        
    }];
    
    [queryView setSelectedLanguageBlock:^(EZLanguage _Nonnull language) {
        mm_strongify(self);
        self.queryModel.detectedLanguage = language;
        [self startQueryText];
    }];
    
    return queryCell;
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
        [self.audioPlayer playTextAudio:text
                           fromLanguage:service.queryModel.queryTargetLanguage
                                 serive:service];
    }];
    
    [resultView setCopyTextBlock:^(NSString *_Nonnull text) {
        mm_strongify(self);
        [self copyTextToPasteboard:text];
    }];
    
    [resultView setQueryTextBlock:^(NSString * _Nonnull word) {
        mm_strongify(self);
        [self startQueryText:word];
    }];
    
    // !!!: Avoid capture result, the block paramter result is different from former result.
    [resultView setClickArrowBlock:^(EZQueryResult *result) {
        mm_strongify(self);
        service.enabled = result.isShowing;
        
        // If result is not empty, update cell and show.
        if (result.isShowing && !result.hasResult) {
            [self queryWithModel:self.queryModel serive:service completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
                [self updateCellWithResult:result reloadData:YES];
            }];
        } else {
            [self updateCellWithResult:result reloadData:YES];
        }
    }];
}

- (void)copyTextToPasteboard:(NSString *)text {
    [NSPasteboard mm_generalPasteboardSetString:text];
}

#pragma mark - Update Window Height

- (void)updateWindowViewHeightWithAnimation:(BOOL)animated {
    [self updateWindowViewHeightWithAnimation:animated display:YES];
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
    CGRect safeFrame = [EZCoordinateTool getSafeAreaFrame:newFrame];
    
    // ???: why set window frame will change tableView height?
    [self.window setFrame:safeFrame display:NO animate:animateFlag];
    
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
        scrollViewContentHeight += (rowHeight + EZVerticalCellSpacing_8);
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
    CGFloat miniInputViewHeight = [[EZLayoutManager shared] inputViewMiniHeight:self.windowType];
    CGFloat queryViewHeight = miniInputViewHeight + EZExceptInputViewHeight;
    return queryViewHeight;
}

/// Delay update, to avoid reload tableView frequently.
- (void)delayUpdateWindowViewHeight {
    [self cancelUpdateWindowViewHeight];
    [self performSelector:@selector(updateWindowViewHeightWithAnimation:) withObject:@(NO) afterDelay:kDelayUpdateWindowViewTime];
}

- (void)cancelUpdateWindowViewHeight {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateWindowViewHeightWithAnimation:) object:@(NO)];
}

@end
