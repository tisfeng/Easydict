//
//  MainTabViewController.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "MainViewController.h"
#import "ResultCell.h"
#import "BaiduTranslate.h"
#import "YoudaoTranslate.h"
#import "GoogleTranslate.h"
#import "QueryView.h"
#import "ResultView.h"
#import "Configuration.h"
#import "NSColor+MyColors.h"
#import "QueryCell.h"

@interface MainViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic, strong) Translate *translate;
@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, strong) ResultView *resultView;
@property (nonatomic, strong) QueryView *queryView;

@property (nonatomic, copy) NSString *queryText;

@end

@implementation MainViewController

static const CGFloat kVerticalPadding = 10;
static const CGFloat kHorizontalPadding = 12;

static const CGFloat kMiniMainViewWidth = 200;
static const CGFloat kMiniMainViewHeight = 300;

/// 用代码创建 NSViewController 貌似不会自动创建 view，需要手动初始化
- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, kMiniMainViewWidth * 1.5, kMiniMainViewHeight * 1.5)];
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
    
    self.translate = [[BaiduTranslate alloc] init];

    self.queryText = @"good";
    [self startTranslate];
    
    _dataArray = [NSMutableArray array];
    for (int i = 0; i < 4; i++) {
        [_dataArray addObject:[NSString stringWithFormat:@"%d行数据", i]];
    }
    
    [self tableView];
}

- (NSScrollView *)scrollView {
    if (!_scrollView) {
        NSScrollView *scrollView = [[NSScrollView alloc] init];
        [self.view addSubview:scrollView];
        self.scrollView = scrollView;

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
        
        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, kVerticalPadding, 0);
    }
    return _scrollView;
}

- (NSTableView *)tableView {
    if (!_tableView) {
        NSTableView *tableView = [[NSTableView alloc] initWithFrame:self.view.bounds];
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

        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"column"];
        column.resizingMask = NSTableColumnUserResizingMask | NSTableColumnAutoresizingMask;
        [tableView addTableColumn:column];

        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.usesAutomaticRowHeights = YES;
        tableView.rowHeight = 100;
        [tableView setAutoresizesSubviews:YES];
        [tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
        
        tableView.headerView = nil;
        tableView.intercellSpacing = CGSizeMake(kHorizontalPadding * 2, kVerticalPadding);
        tableView.gridColor = NSColor.clearColor;
        tableView.gridStyleMask = NSTableViewGridNone;
        [tableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask | NSTableViewSolidHorizontalGridLineMask];
        self.scrollView.documentView = tableView;
        [tableView sizeLastColumnToFit]; // must put in the end
    }
    return _tableView;;
}

- (void)startTranslate {
    [self.translate translate:self.queryText
                         from:Configuration.shared.from
                           to:Configuration.shared.to
                   completion:^(TranslateResult *_Nullable result, NSError *_Nullable error) {
        self.result = result;
        [self.tableView reloadData];
        [self.resultView refreshWithResult:result];
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _dataArray.count;
}

// View-base
//设置某个元素的具体视图
- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row == 0) {
        NSString *queryCellID = @"queryCellID";
//        QueryCell *queryCell = [tableView makeViewWithIdentifier:queryCellID owner:self];
        QueryCell *queryCell;

        if (!queryCell) {
            queryCell = [[QueryCell alloc] initWithFrame:self.view.bounds];
            queryCell.queryView.queryText = self.queryText;
            
            mm_weakify(self)
            [queryCell setEnterActionBlock:^(QueryView *view) {
                mm_strongify(self);
                self.queryText = view.queryText;
                [self startTranslate];
            }];
            queryCell.identifier = queryCellID;
        }
        return queryCell;
    }
    
    NSString *resultCellID = @"resultCellID";
//    ResultCell *resultView = [tableView makeViewWithIdentifier:resultCellID owner:self];
    ResultCell *resultView;

    if (!resultView) {
        resultView = [[ResultCell alloc] initWithFrame:self.view.bounds];
        resultView.identifier = resultCellID;
    }
    
    resultView.result = self.result;
    
    return resultView;
}

- (void)viewDidLayout {
    [super viewDidLayout];
        
    [self.tableView reloadData];
}

@end
