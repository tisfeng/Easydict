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
#import "TranslateLanguage.h"
#import <AVFoundation/AVFoundation.h>
#import "ServiceTypes.h"

@interface MainViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;

@property (nonatomic, strong) NSArray<EDServiceType> *services;
@property (nonatomic, strong) NSArray<TranslateService *> *translateServices;
//@property (nonatomic, copy) NSDictionary<NSString *, TranslateService *> *translateDict;
//@property (nonatomic, strong) NSMutableDictionary<NSString *, TranslateResult *> *translateResultDict;

@property (nonatomic, strong) DetectText *detectManager;
@property (nonatomic, strong) QueryView *queryView;
@property (nonatomic, strong) AVPlayer *player;

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
    
    [self setup];
    
//    self.inputText = @"good";
//    [self startTranslate];
}

- (void)setup {
    self.inputText = @"";
    self.services = [ServiceTypes allServiceTypes];
    self.translateServices = @[GoogleTranslate.new, BaiduTranslate.new, YoudaoTranslate.new];
   
    self.detectManager = [[DetectText alloc] init];
    self.player = [[AVPlayer alloc] init];

    [self tableView];
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
}


- (void)queryText:(NSString *)text
           serive:(TranslateService *)service
           language:(Language)fromLang
         completion:(nonnull void (^)(TranslateResult *_Nullable translateResult, NSError *_Nullable error))completion {
    [service translate:self.inputText
                    from:fromLang
                      to:Configuration.shared.to
              completion:completion];
}

- (void)startQueryText:(NSString *)text {
    __block Language fromLang = Configuration.shared.from;
    
    if (fromLang != Language_auto) {
        [self queryText:text fromLangunage:fromLang];;
        return;
    }
    
    [self.detectManager detect:self.inputText completion:^(Language language, NSError *error) {
        if (!error) {
            fromLang = language;
            NSLog(@"detect language: %ld", language);
        }
        [self queryText:text fromLangunage:fromLang];;
    }];
}

- (void)queryText:(NSString *)text fromLangunage:(Language)fromLang {
    NSString *language = LanguageDescFromEnum(fromLang);
    [self.queryView setDetectLanguage:language];
    
    for (TranslateService *service in self.translateServices) {
        [self queryText:text
          serive:service language:fromLang completion:^(TranslateResult *_Nullable translateResult, NSError *_Nullable error) {
              service.translateResult = translateResult;
            
            [self updateUI];
        }];
    }
    
//    [self.translateDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, TranslateService *service, BOOL *stop) {
//
//        [self queryText:text
//          serive:service language:fromLang completion:^(TranslateResult *_Nullable translateResult, NSError *_Nullable error) {
//            self.translateResultDict[key] = translateResult;
//
//            [self updateUI];
//        }];
//    }];
}

- (void)updateUI {
    [self.tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.translateServices.count + 1;
}

// View-base
//设置某个元素的具体视图
- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row == 0) {
        QueryCell *queryCell = [self queryCell];
        return queryCell;
    }
    

    ResultCell *resultCell = [self resultCellAtRow:row];
    return resultCell;
}

- (QueryCell *)queryCell {
    QueryCell *queryCell = [[QueryCell alloc] initWithFrame:self.view.bounds];
    queryCell.identifier = @"queryCell";
    queryCell.queryView.queryText = self.inputText;
    self.queryView = queryCell.queryView;
    
    Language detectLang = self.detectManager.language;
    if (detectLang != Language_auto) {
        self.queryView.detectLanguage = LanguageDescFromEnum(detectLang);
    }
    
    mm_weakify(self)
    [queryCell setEnterActionBlock:^(QueryView *view) {
        mm_strongify(self);
        self.inputText = view.queryText;
        [self startQueryText:self.inputText];
    }];
    
    return queryCell;
}

- (ResultCell *)resultCellAtRow:(NSInteger)row {
    ResultCell *resultCell = [[ResultCell alloc] initWithFrame:self.view.bounds];
    resultCell.identifier = @"resultView";
    TranslateResult *result = self.translateServices[row - 1].translateResult;
    if (result) {
        resultCell.result = result;
    }
    
    [self setupResultView:resultCell.resultView];
    
    return resultCell;
}

- (void)setupResultView:(ResultView *)resultView {
//    mm_weakify(self)
//    [resultView.normalResultView setAudioActionBlock:^(NormalResultView *_Nonnull view) {
//        mm_strongify(self);
//        if (!self.result) {
//            return;
//        }
//        if (self.result.toSpeakURL) {
//            [self playAudioWithURL:self.result.toSpeakURL];
//        } else {
//            [self playAudioWithText:[NSString mm_stringByCombineComponents:self.result.normalResults separatedString:@"\n"] lang:self.result.to];
//        }
//    }];
//    [resultView.normalResultView setCopyActionBlock:^(NormalResultView *_Nonnull view) {
//        mm_strongify(self);
//        if (!self.result) return;
//        [NSPasteboard mm_generalPasteboardSetString:view.textView.string];
//    }];
//    [resultView.wordResultView setPlayAudioBlock:^(WordResultView *_Nonnull view, NSString *_Nonnull url) {
//        mm_strongify(self);
//        [self playAudioWithURL:url];
//    }];
//    [resultView.wordResultView setSelectWordBlock:^(WordResultView *_Nonnull view, NSString *_Nonnull word) {
//        [NSPasteboard mm_generalPasteboardSetString:word];
//    }];
}

- (void)playAudioWithText:(NSString *)text lang:(Language)lang {
//    if (text.length) {
//        mm_weakify(self)
//        [self.translate audio:text from:lang completion:^(NSString *_Nullable url, NSError *_Nullable error) {
//            mm_strongify(self);
//            if (!error) {
//                [self playAudioWithURL:url];
//            } else {
//                MMLogInfo(@"获取音频 URL 失败 %@", error);
//            }
//        }];
//    }
}

- (void)playAudioWithURL:(NSString *)url {
    MMLogInfo(@"播放音频 %@", url);
    [self.player pause];
    if (!url.length) return;
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]]];
    [self.player play];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    
    [self updateUI];
}

@end
