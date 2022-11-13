//
//  MainTabViewController.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZMainViewController.h"
#import "BaiduTranslate.h"
#import "YoudaoTranslate.h"
#import "GoogleTranslate.h"
#import "Configuration.h"
#import "NSColor+MyColors.h"
#import "EZQueryCell.h"
#import "EZResultCell.h"
#import "DetectManager.h"
#import <AVFoundation/AVFoundation.h>
#import "ServiceTypes.h"
#import "EZQueryView.h"
#import "EZResultView.h"
#import "EZConst.h"


static NSString *EZColumnId = @"EZColumnId";
static NSString *EZQueryCellId = @"EZQueryCellId";
static NSString *EZResultCellId = @"EZResultCellId";

@interface EZMainViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSTableColumn *column;
@property (nonatomic, strong) EZQueryCell *queryCell;

@property (nonatomic, strong) NSArray<EZServiceType> *serviceTypes;
@property (nonatomic, strong) NSArray<TranslateService *> *services;
@property (nonatomic, copy) NSString *queryText;

@property (nonatomic, strong) DetectManager *detectManager;
@property (nonatomic, strong) EZQueryView *queryView;
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, assign) CGFloat textViewHeight;

@end

@implementation EZMainViewController

static const CGFloat kMiniMainViewWidth = 300;
static const CGFloat kMiniMainViewHeight = 300;

/// 用代码创建 NSViewController 貌似不会自动创建 view，需要手动初始化
- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, kMiniMainViewWidth * 1.3, kMiniMainViewHeight * 2)];
    self.view.wantsLayer = YES;
    self.view.layer.cornerRadius = 4;
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
    
    [self startQueryText:@"good"];
    //    [self startQueryText:@"你好\n世界"];
    
}

- (void)setup {
    self.serviceTypes = @[EZServiceTypeGoogle, EZServiceTypeBaidu, EZServiceTypeYoudao];
    
    NSMutableArray *translateServices = [NSMutableArray array];
    for (EZServiceType type in self.serviceTypes) {
        TranslateService *service = [ServiceTypes serviceWithType:type];
        [translateServices addObject:service];
    }
    self.services = translateServices;
    
    self.detectManager = [[DetectManager alloc] init];
    self.player = [[AVPlayer alloc] init];
    
    [self tableView];
}

#pragma mark - Getter
- (NSScrollView *)scrollView {
    if (!_scrollView) {
        NSScrollView *scrollView = [[NSScrollView alloc] init];
        _scrollView = scrollView;
        [self.view addSubview:scrollView];
        
        [scrollView excuteLight:^(NSScrollView *scrollView) {
            scrollView.backgroundColor = NSColor.mainViewBgLightColor;
        } drak:^(NSScrollView *scrollView) {
            scrollView.backgroundColor = NSColor.mainViewBgDarkColor;
        }];
        scrollView.hasVerticalScroller = YES;
        scrollView.verticalScroller.controlSize = NSControlSizeSmall;
        scrollView.frame = self.view.bounds;
        [scrollView setAutomaticallyAdjustsContentInsets:NO];
        
        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
            make.width.mas_greaterThanOrEqualTo(kMiniMainViewWidth);
            make.height.mas_greaterThanOrEqualTo(kMiniMainViewHeight);
        }];
        
        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, 7, 0);
    }
    return _scrollView;
}

- (NSTableView *)tableView {
    if (!_tableView) {
        NSTableView *tableView = [[NSTableView alloc] initWithFrame:self.view.bounds];
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
        tableView.intercellSpacing = CGSizeMake(kMainHorizontalMargin * 2, kMainVerticalMargin);
        tableView.gridColor = NSColor.clearColor;
        tableView.gridStyleMask = NSTableViewGridNone;
        [tableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask | NSTableViewSolidHorizontalGridLineMask];
        self.scrollView.documentView = tableView;
        [tableView sizeLastColumnToFit]; // must put in the end
    }
    return _tableView;
}

- (void)setQueryText:(NSString *)queryText {
    _queryText = queryText;
    
    self.queryCell.queryText = queryText;
}

- (void)startQuery {
    [self startQueryText:self.queryText];
}

- (void)startQueryText:(NSString *)text {
    self.queryText = text;
    
    __block Language fromLang = Configuration.shared.from;
    
    if (fromLang != Language_auto) {
        [self queryText:text fromLangunage:fromLang];
        return;
    }
    
    [self.detectManager detect:self.queryText completion:^(Language language, NSError *error) {
        if (!error) {
            fromLang = language;
            NSLog(@"detect language: %ld", language);
        }
        
        if (fromLang != Language_auto) {
            self.queryView.detectLanguage = LanguageDescFromEnum(fromLang);
        }
        [self queryText:text fromLangunage:fromLang];
    }];
}

- (void)queryText:(NSString *)text fromLangunage:(Language)fromLang {
    for (TranslateService *service in self.services) {
        [self queryText:text
                 serive:service
               language:fromLang completion:^(TranslateResult *_Nullable translateResult, NSError *_Nullable error) {
            if (!translateResult) {
                NSLog(@"translateResult is nil, error: %@", error);
                return;
            }
            [self updateTranslateResult:translateResult reloadData:YES];
        }];
    }
}

- (void)queryText:(NSString *)text
           serive:(TranslateService *)service
         language:(Language)fromLang
       completion:(nonnull void (^)(TranslateResult *_Nullable translateResult, NSError *_Nullable error))completion {
    [service translate:self.queryText
                  from:fromLang
                    to:Configuration.shared.to
            completion:completion];
}


- (void)updateUI {
    [self.tableView reloadData];
}

- (void)updateTranslateResult:(TranslateResult *)result reloadData:(BOOL)reloadData {
    [self updateServiceResults:@[result]reloadData:reloadData];
}

- (void)updateServiceResults:(NSArray<TranslateResult *> *)results reloadData:(BOOL)reloadData {
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    for (TranslateResult *result in results) {
        EZServiceType serviceType = result.serviceType;
        NSInteger row = [self.serviceTypes indexOfObject:serviceType];
        [rowIndexes addIndex:row + 1];
    }
    [self updateTableViewRowIndexes:rowIndexes reloadData:reloadData];
}

- (void)updateTableViewRowIndexes:(NSIndexSet *)rowIndexes reloadData:(BOOL)reloadData {
    if (reloadData) {
        [self.tableView reloadDataForRowIndexes:rowIndexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
    [self.tableView noteHeightOfRowsWithIndexesChanged:rowIndexes];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.services.count + 1;
}

#pragma mark - NSTableViewDelegate

// View-base 设置某个元素的具体视图
- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
//    NSLog(@"tableView for row: %ld", row);
    
    if (row == 0) {
        EZQueryCell *queryCell = [self createQueryCell];
        queryCell.queryText = self.queryText;
        self.queryView = queryCell.queryView;

        return queryCell;
    }
    
    EZResultCell *resultCell = [self resultCellAtRow:row];
    return resultCell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    NSView *cellView;
    if (row == 0) {
        EZQueryCell *queryCell = [[EZQueryCell alloc] initWithFrame:self.tableView.bounds];
        queryCell.queryText = self.queryText;
        cellView = queryCell;
    } else {
        cellView = [self resultCellAtRow:row];
    }
    
    CGFloat height = [cellView fittingSize].height;
//    NSLog(@"row: %ld, height: %@", row, @(height));
    
    return height;
}

// Disable select cell
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

#pragma mark -

- (EZQueryCell *)createQueryCell {
    EZQueryCell *queryCell = [[EZQueryCell alloc] initWithFrame:self.tableView.bounds];
    queryCell.identifier = EZQueryCellId;
        
    mm_weakify(self);
    [queryCell setUpdateQueryTextBlock:^(NSString * _Nonnull text, CGFloat textViewHeight) {
        mm_strongify(self);
        self->_queryText = text;
        
        if (textViewHeight != self.textViewHeight) {
            self.textViewHeight = textViewHeight;
            
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                // recover input focus
                [self.view.window makeFirstResponder:self.queryView.textView];
                
                // scroll to input view bottom
                NSScrollView *scrollView = self.queryView.scrollView;
                CGFloat height = scrollView.documentView.frame.size.height - scrollView.contentSize.height;
                [scrollView.contentView scrollToPoint:NSMakePoint(0, height)];
            }];
            
            NSIndexSet *firstIndexSet = [NSIndexSet indexSetWithIndex:0];
            [self updateTableViewRowIndexes:firstIndexSet reloadData:NO];
            [CATransaction commit];
        }
    }];
    
    [queryCell setEnterActionBlock:^(NSString *text) {
        mm_strongify(self);
        [self startQueryText:text];
    }];
    
    [queryCell setPlayAudioBlock:^(NSString *text) {
        mm_strongify(self);
        TranslateService *service = [self firstTranslateService];
        if (service) {
            Language lang = self.detectManager.language;
            [service audio:self.queryText from:lang completion:^(NSString * _Nullable url, NSError * _Nullable error) {
                if (url.length) {
                    [self playAudioWithURL:url];
                }
            }];
        }
    }];
    
    [queryCell setCopyTextBlock:^(NSString *text) {
        mm_strongify(self);
        [self copyTextToPasteboard:text];
    }];
    
    return queryCell;
}

- (TranslateService * _Nullable)firstTranslateService {
    for (TranslateService *service in self.services) {
        return service;
    }
    return nil;
}

- (EZResultCell *)resultCellAtRow:(NSInteger)row {
    EZResultCell *resultCell = [[EZResultCell alloc] initWithFrame:self.tableView.bounds];
    resultCell.identifier = EZResultCellId;
    
    NSInteger index = row - 1;
    
    TranslateService *service = self.services[index];
    TranslateResult *result = service.result;
    if (!result) {
        result = [[TranslateResult alloc] init];
        service.result = result;
    }
    resultCell.result = result;
    [self setupResultCell:resultCell];
    
    return resultCell;
}

- (TranslateService *)servicesWithType:(EZServiceType)serviceType {
    NSInteger index = [self.serviceTypes indexOfObject:serviceType];
    return self.services[index];
}

- (void)setupResultCell:(EZResultCell *)resultCell {
    EZResultView *resultView = resultCell.resultView;
    TranslateResult *result = resultCell.result;
    TranslateService *serive = [self servicesWithType:result.serviceType];
    
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
        [self updateTranslateResult:result reloadData:NO];
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

- (void)viewDidLayout {
    [super viewDidLayout];
    
    [self updateUI];
}

@end
