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

@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic, strong) Translate *translate;
@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, strong) ResultView *resultView;

@property (nonatomic, copy) NSString *queryText;

@end

@implementation MainViewController

/// 用代码创建 NSViewController 貌似不会自动创建 view，需要手动初始化
- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
    self.view.wantsLayer = YES;
    self.view.layer.cornerRadius = 4;
    self.view.layer.masksToBounds = YES;
    [self.view excuteLight:^(NSView *_Nonnull x) {
        x.layer.backgroundColor = NSColor.mainViewBgLightColor.CGColor;
        //        x.layer.borderWidth = 0;
    } drak:^(NSView *_Nonnull x) {
        x.layer.backgroundColor = NSColor.mainViewBgDarkColor.CGColor;
        
        //        x.layer.borderColor = [NSColor mm_colorWithHexString:@"#515253"].CGColor;
        
        //        x.layer.borderColor = [[NSColor mm_colorWithHexString:@"#515253"] colorWithAlphaComponent:0.15].CGColor;
        //        x.layer.borderWidth = 0.5;
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
    [scrollView setAutomaticallyAdjustsContentInsets:NO];
    CGFloat padding = -10;
    [scrollView setContentInsets:NSEdgeInsetsMake(padding, padding, padding, padding)];
    
    [self.view addSubview:scrollView];
    
    //    CGSize screenSize = NSScreen.mainScreen.frame.size;
    
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        //        make.height.mas_equalTo(screenSize.height *2/3);
        make.bottom.equalTo(self.view);
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
    _tableView.rowHeight = 200;
    _tableView.intercellSpacing = CGSizeMake(0, 10);
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
    
    
    //    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.edges.equalTo(scrollView);
    //    }];
    
    self.translate = [[BaiduTranslate alloc] init];
    [self translateText:@"good"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidResize:)
                                                 name:NSWindowDidResizeNotification
                                               object:self];
}

- (void)translateText:(NSString *)text {
    self.queryText = text;
    [self.translate translate:text
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
            queryCell = [[QueryCell alloc] init];
            [queryCell.queryView.textView setString:self.queryText] ;
            
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
    
    //    NSString *queryCellID = @"queryCellID";
    //    QueryCell *queryCell = [tableView makeViewWithIdentifier:queryCellID owner:self];
    //    if (!queryCell) {
    //        queryCell = [[QueryCell alloc] init];
    //        queryCell.identifier = queryCellID;
    //    }
    //    return queryCell;
    
    NSString *resultCellID = @"resultCellID";
//    ResultCell *resultView = [tableView makeViewWithIdentifier:resultCellID owner:self];
    ResultCell *resultView;

    if (!resultView) {
        resultView = [[ResultCell alloc] init];
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
    
    NSLog(@"viewDidLayout, MainViewController");
    
    [self.tableView reloadData];
}

- (void)windowDidResize:(NSNotification *)aNotification {
    NSLog(@"窗口拉伸, (%.2f, %.2f)", self.view.width, self.view.height);
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
    // 根据需要调整NSView上面的别的控件和视图的frame
    NSLog(@"resizeSubviewsWithOldSize: %@", @(oldBoundsSize));
}

@end
