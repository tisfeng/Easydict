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
#import "DetectText.h"

@interface MainViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;

@property (nonatomic, strong) NSArray<Translate *> *translateServices;
@property (nonatomic, copy) NSDictionary<NSString *, Translate *> *translateDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, TranslateResult *> *translateResultDict;

@property (nonatomic, strong) Translate *translate;
@property (nonatomic, strong) DetectText *detectManager;
@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, strong) ResultView *resultView;
@property (nonatomic, strong) QueryView *queryView;

@property (nonatomic, copy) NSString *inputText;

@end

@implementation MainViewController

static const CGFloat kVerticalMargin = 10;
static const CGFloat kHorizontalMargin = 12;

static const CGFloat kMiniMainViewWidth = 300;
static const CGFloat kMiniMainViewHeight = 300;

/// 用代码创建 NSViewController 貌似不会自动创建 view，需要手动初始化
- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, kMiniMainViewWidth, kMiniMainViewHeight * 1.5)];
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
    
    self.translateServices = @[ GoogleTranslate.new, BaiduTranslate.new, YoudaoTranslate.new];
    
    NSMutableDictionary<NSString *, Translate *> *serviceDict = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, TranslateResult *> *translateResultDict = [NSMutableDictionary dictionary];
    
    for (Translate *translate in self.translateServices) {
        NSString *name = [translate name];
        serviceDict[name] = translate;
        
        TranslateResult *result = [[TranslateResult alloc] init];
        result.queryType = translate.queryType;
        result.text = self.inputText;
        result.normalResults = @[@""];
        
        [translateResultDict setValue:result forKey:name];
    }
    self.translateDict = serviceDict;
    self.translateResultDict = translateResultDict;
    
    
    self.translate = [[BaiduTranslate alloc] init];
    self.detectManager = [[DetectText alloc] init];
    
    [self tableView];
    
//    self.inputText = @"good";
//    [self startTranslate];
}


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
        
        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, kVerticalMargin, 0);
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
        tableView.intercellSpacing = CGSizeMake(kHorizontalMargin * 2, kVerticalMargin);
        tableView.gridColor = NSColor.clearColor;
        tableView.gridStyleMask = NSTableViewGridNone;
        [tableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask | NSTableViewSolidHorizontalGridLineMask];
        self.scrollView.documentView = tableView;
        [tableView sizeLastColumnToFit]; // must put in the end
    }
    return _tableView;
    ;
}


- (void)querySerive:(Translate *)translate
           language:(Language)fromLang
         completion:(nonnull void (^)(TranslateResult *_Nullable rranslateResult, NSError *_Nullable error))completion {
    [translate translate:self.inputText
                    from:fromLang
                      to:Configuration.shared.to
              completion:completion];
}

- (void)startTranslate {
    __block Language fromLang = Configuration.shared.from;
    
    if (fromLang == Language_auto) {
        [self.detectManager detect:self.inputText completion:^(Language language, NSError *error) {
            if (!error) {
                fromLang = language;
                NSLog(@"detect: %ld", language);
            }
            [self querySeriveFromLang:fromLang];
        }];
        return;
    }
    [self querySeriveFromLang:fromLang];
}

- (void)querySeriveFromLang:(Language)fromLang {
    [self.translateDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, Translate *translate, BOOL *stop) {
        [self querySerive:translate language:fromLang completion:^(TranslateResult *_Nullable translateResult, NSError *_Nullable error) {
            self.translateResultDict[key] = translateResult;
            
            [self.tableView reloadData];
        }];
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
//    return 4;
    return self.translateResultDict.count + 1;
}

// View-base
//设置某个元素的具体视图
- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row == 0) {
        QueryCell *queryCell = [[QueryCell alloc] initWithFrame:self.view.bounds];
        queryCell.identifier = @"queryCell";
        queryCell.queryView.queryText = self.inputText;
        
        mm_weakify(self)
        [queryCell setEnterActionBlock:^(QueryView *view) {
            mm_strongify(self);
            self.inputText = view.queryText;
            [self startTranslate];
        }];
        
        return queryCell;
    }
    

    ResultCell *resultView = [[ResultCell alloc] initWithFrame:self.view.bounds];
    resultView.identifier = @"resultView";
    NSString *name = [self.translateServices[row - 1] name];
    TranslateResult *result = self.translateResultDict[name];
    resultView.result = result;
    
    return resultView;
}

- (void)viewDidLayout {
    [super viewDidLayout];
    
//    [self.tableView reloadData];
}

@end
