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

@interface EZMainViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;

@property (nonatomic, strong) NSArray<EZServiceType> *serviceTypes;
@property (nonatomic, strong) NSArray<TranslateService *> *translateServices;
@property (nonatomic, copy) NSString *inputText;

@property (nonatomic, strong) DetectManager *detectManager;
@property (nonatomic, strong) EZQueryView *queryView;
@property (nonatomic, strong) AVPlayer *player;

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
    self.inputText = @"";
    
    self.serviceTypes = @[EZServiceTypeGoogle, EZServiceTypeBaidu, EZServiceTypeYoudao];
//    self.serviceTypes = @[EZServiceTypeGoogle];

    NSMutableArray *translateServices = [NSMutableArray array];
    for (EZServiceType type in self.serviceTypes) {
        TranslateService *service = [ServiceTypes serviceWithType:type];
        [translateServices addObject:service];
    }
    self.translateServices = translateServices;
    
    self.detectManager = [[DetectManager alloc] init];
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
        tableView.intercellSpacing = CGSizeMake(kMainHorizontalMargin * 2, kMainVerticalMargin);
        tableView.gridColor = NSColor.clearColor;
        tableView.gridStyleMask = NSTableViewGridNone;
        [tableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask | NSTableViewSolidHorizontalGridLineMask];
        self.scrollView.documentView = tableView;
        [tableView sizeLastColumnToFit]; // must put in the end
    }
    return _tableView;
}

- (void)startQuery {
    [self startQueryText:self.inputText];
}

- (void)startQueryText:(NSString *)text {
    self.inputText = text;
    
    __block Language fromLang = Configuration.shared.from;
    
    if (fromLang != Language_auto) {
        [self queryText:text fromLangunage:fromLang];
        return;
    }
    
    [self.detectManager detect:self.inputText completion:^(Language language, NSError *error) {
        if (!error) {
            fromLang = language;
            NSLog(@"detect language: %ld", language);
        }
        [self queryText:text fromLangunage:fromLang];
    }];
}

- (void)queryText:(NSString *)text fromLangunage:(Language)fromLang {
    for (TranslateService *service in self.translateServices) {
        [self queryText:text
                 serive:service
               language:fromLang completion:^(TranslateResult *_Nullable translateResult, NSError *_Nullable error) {
            service.translateResult = translateResult;
            
            [self updateUI];
        }];
    }
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


- (void)updateUI {
    [self.tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.translateServices.count + 1;
}

// View-base
// 设置某个元素的具体视图
- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row == 0) {
        EZQueryCell *queryCell = [self queryCell];
        return queryCell;
    }
    
    EZResultCell *resultCell = [self resultCellAtRow:row];
    return resultCell;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

- (EZQueryCell *)queryCell {
    EZQueryCell *queryCell = [[EZQueryCell alloc] initWithFrame:self.view.bounds];
    queryCell.identifier = @"queryCell";
    queryCell.queryView.copiedText = self.inputText;
    self.queryView = queryCell.queryView;
    
    Language detectLang = self.detectManager.language;
    if (detectLang != Language_auto) {
        self.queryView.detectLanguage = LanguageDescFromEnum(detectLang);
    }
    
    mm_weakify(self)
    [queryCell setEnterActionBlock:^(NSString *text) {
        mm_strongify(self);
        self.inputText = text;
        [self startQuery];
    }];
    
    [queryCell setPlayAudioBlock:^(NSString *text) {
        mm_strongify(self);
        TranslateService *service = [self firstTranslateService];
        if (service) {
            NSString *text = self.inputText;
            Language lang = self.detectManager.language;
            [service audio:text from:lang completion:^(NSString * _Nullable url, NSError * _Nullable error) {
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
    for (TranslateService *service in self.translateServices) {
        return service;
    }
    return nil;
}

- (EZResultCell *)resultCellAtRow:(NSInteger)row {
    EZResultCell *resultCell = [[EZResultCell alloc] initWithFrame:self.view.bounds];
    resultCell.identifier = @"resultCell";
    
    NSInteger index = row - 1;
    TranslateResult *result = self.translateServices[index].translateResult;
    if (!result) {
        result = [[TranslateResult alloc] init];
        result.serviceType = self.serviceTypes[index];
    }
    resultCell.result = result;
    [self setupResultCell:resultCell];
    
    return resultCell;
}

- (TranslateService *)translateServicesWithType:(EZServiceType)serviceType {
    NSInteger index = [self.serviceTypes indexOfObject:serviceType];
    return self.translateServices[index];
}

- (void)setupResultCell:(EZResultCell *)resultCell {
    EZResultView *resultView = resultCell.resultView;
    TranslateResult *result = resultCell.result;
    TranslateService *serive = [self translateServicesWithType:result.serviceType];
    
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
