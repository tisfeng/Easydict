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
#import "MyScroller.h"

@interface MainViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic, strong) Translate *translate;
@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, strong) ResultView *resultView;
@property (nonatomic, strong) QueryView *queryView;

@property (nonatomic, copy) NSString *queryText;

@end

@implementation MainViewController

static const CGFloat kPadding = 12;


/// 用代码创建 NSViewController 貌似不会自动创建 view，需要手动初始化
- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
    self.view.wantsLayer = YES;
    self.view.layer.cornerRadius = 4;
    self.view.layer.masksToBounds = YES;
    [self.view excuteLight:^(NSView *_Nonnull x) {
        x.layer.backgroundColor = NSColor.mainViewBgLightColor.CGColor;
    } drak:^(NSView *_Nonnull x) {
        x.layer.backgroundColor = NSColor.mainViewBgDarkColor.CGColor;
    }];
}

- (void)setup {
    QueryView *queryView = [[QueryView alloc] init];
    [self.view addSubview:queryView];
    self.queryView = queryView;
    queryView.queryText = @"'NSKeyedUnarchiveFromData' should not be used to for un-archiving and will be removed in a future release.\nMainViewController";
    
    [queryView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(100);
    }];
    
    ResultView *resultView = [[ResultView alloc] init];
    [self.view addSubview:resultView];
    self.resultView = resultView;
    
    [resultView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(queryView.mas_bottom);
        make.bottom.left.right.equalTo(self.view);
    }];
    
    [self translateText:@"good"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.translate = [[BaiduTranslate alloc] init];

    
//    [self setup];
//    return;
    
    self.queryText = @"";
    
    _dataArray = [NSMutableArray array];
    for (int i = 0; i < 4; i++) {
        [_dataArray addObject:[NSString stringWithFormat:@"%d行数据", i]];
    }
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    [self.view addSubview:scrollView];

    scrollView.hasVerticalScroller = YES;
    scrollView.verticalScroller = [[MyScroller alloc] init];
    scrollView.frame = self.view.bounds;
    [scrollView setAutomaticallyAdjustsContentInsets:NO];
    
    //    CGSize screenSize = NSScreen.mainScreen.frame.size;
    
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    scrollView.contentInsets = NSEdgeInsetsMake(kPadding, 0, kPadding, 0);
    
    _tableView = [[NSTableView alloc] initWithFrame:self.view.bounds];
    
    if (@available(macOS 11.0, *)) {
        _tableView.style = NSTableViewStylePlain;
    } else {
        // Fallback on earlier versions
    }
    
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"resultView"];
    column.width = 400;
    //    column.minWidth = 200;
    column.resizingMask = NSTableColumnUserResizingMask | NSTableColumnAutoresizingMask;
    
    if (@available(macOS 10.13, *)) {
        _tableView.usesAutomaticRowHeights = YES;
    } else {
        // Fallback on earlier versions
    }
    column.title = @"title";
    _tableView.headerView = nil;
    [_tableView addTableColumn:column];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 200;
    _tableView.intercellSpacing = CGSizeMake(24, 10);
    _tableView.gridColor = NSColor.clearColor;
    _tableView.gridStyleMask = NSTableViewGridNone;
    
    [_tableView excuteLight:^(NSTableView *tableView) {
        tableView.backgroundColor = NSColor.mainViewBgLightColor;
    } drak:^(NSTableView *tableView) {
        tableView.backgroundColor = NSColor.mainViewBgDarkColor;
    }];
    
    [_tableView reloadData];
    
    [_tableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask | NSTableViewSolidHorizontalGridLineMask];
    [_tableView setAutoresizesSubviews:YES];
    [_tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
    scrollView.contentView.documentView = _tableView;
    
    [_tableView sizeLastColumnToFit];
}

- (void)translateText:(NSString *)text {
    self.queryText = text;
    [self.translate translate:text
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

//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    return _dataArray[row];
//}

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
                
                if (view.queryText.length) {
                    [self translateText:view.queryText];
                }
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
//设置每行容器视图
//- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
//    ResultCell *rowView = [[ResultCell alloc] init];
//    return rowView;
//}

//- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
//    return 300;
//}

- (void)viewDidLayout {
    [super viewDidLayout];
        
    [self.tableView reloadData];
}

@end
