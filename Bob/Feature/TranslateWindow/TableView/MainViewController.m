//
//  MainTabViewController.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "MainViewController.h"
#import "TableRow.h"
#import "BaiduTranslate.h"
#import "YoudaoTranslate.h"
#import "GoogleTranslate.h"
#import "Selection.h"
#import "PopUpButton.h"
#import "QueryView.h"
#import "ResultView.h"
#import "Configuration.h"
#import <AVFoundation/AVFoundation.h>
#import "ImageButton.h"
#import "TranslateWindowController.h"
#import "FlippedView.h"


@interface MainViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic, strong) Translate *translate;
@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, strong) ResultView *resultView;

@end

@implementation MainViewController

/// 用代码创建 NSViewController 貌似不会自动创建 view，需要手动初始化
- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 300, 500)];
    self.view.wantsLayer = YES;
    self.view.layer.cornerRadius = 4;
    self.view.layer.masksToBounds = YES;
    [self.view excuteLight:^(NSView *_Nonnull x) {
        x.layer.backgroundColor = NSColor.whiteColor.CGColor;
        x.layer.borderWidth = 0;
    } drak:^(NSView *_Nonnull x) {
        x.layer.backgroundColor = DarkBorderColor.CGColor;
        x.layer.borderColor = [[NSColor whiteColor] colorWithAlphaComponent:0.15].CGColor;
        x.layer.borderWidth = 1;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _dataArray = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        [_dataArray addObject:[NSString stringWithFormat:@"%d行数据", i]];
    }
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    scrollView.hasVerticalScroller = YES;
    scrollView.frame = self.view.bounds;
    [self.view addSubview:scrollView];
    
    CGSize screenSize = NSScreen.mainScreen.frame.size;
    
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(screenSize.height *2/3);
    }];
    
    _tableView = [[NSTableView alloc] initWithFrame:self.view.bounds];
    
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
//    _tableView.rowHeight = 200;
    [_tableView reloadData];
    [_tableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask|NSTableViewSolidHorizontalGridLineMask];
    [_tableView setAutoresizesSubviews:YES];
    [_tableView setColumnAutoresizingStyle:NSTableViewNoColumnAutoresizing];
    scrollView.contentView.documentView = _tableView;
    
//    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(scrollView);
//    }];
    
    self.translate = [[BaiduTranslate alloc] init];
    [self.translate translate:@"good"
                         from:Configuration.shared.from
                           to:Configuration.shared.to
                   completion:^(TranslateResult *_Nullable result, NSError *_Nullable error) {
        self.result = result;
        [self.tableView reloadData];
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (self.result) {
        return _dataArray.count;
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return _dataArray[row];
}

// View-base
//设置某个元素的具体视图
- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    //根据ID取视图
    NSString *cellID = tableColumn.identifier;
    TableRow *rowView = [tableView makeViewWithIdentifier:cellID owner:self];
    if (!rowView) {
        rowView = [[TableRow alloc] init];
        rowView.identifier = cellID;
    }
    
    rowView.result = self.result;

    return rowView;
}
//设置每行容器视图
//- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
//    TableRow *rowView = [[TableRow alloc] init];
//    return rowView;
//}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 300;
}


@end
