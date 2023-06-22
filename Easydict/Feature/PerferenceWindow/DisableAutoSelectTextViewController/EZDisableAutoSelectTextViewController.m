//
//  EZDisableAutoSelectTextViewController.m
//  Easydict
//
//  Created by tisfeng on 2023/6/16.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZDisableAutoSelectTextViewController.h"
#import "EZAppCell.h"
#import "EZServiceTypes.h"
#import "EZCustomTableRowView.h"
#import "EZLocalStorage.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "EZLocalStorage.h"
#import "EZConfiguration.h"

static CGFloat const kMargin = 20;
static CGFloat const kRowHeight = 45;

static NSString *const EZAppCellId = @"EZAppCellId";
static NSString *const EZColumnId = @"EZColumnId";

@interface EZDisableAutoSelectTextViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSTextField *titleTextField;
@property (nonatomic, strong) NSSegmentedControl *segmentedControl;

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSTableColumn *column;

@property (nonatomic, strong) NSMutableArray<EZAppModel *> *appModelList;

@end

@implementation EZDisableAutoSelectTextViewController

- (void)loadView {
    CGRect frame = CGRectMake(0, 0, 450, 400);
    self.view = [[NSView alloc] initWithFrame:frame];
    self.view.wantsLayer = YES;
    [self.view excuteLight:^(NSView *view) {
        view.layer.backgroundColor = [NSColor ez_resultViewBgLightColor].CGColor;
    } dark:^(NSView *view) {
        view.layer.backgroundColor = [NSColor ez_resultViewBgDarkColor].CGColor;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}

- (void)setup {
    self.appModelList = [[EZLocalStorage.shared selectTextTypeAppModelList] mutableCopy];
    
    [self.titleTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.inset(kMargin + 5); // ???: Why is the actual inset is 18?
    }];
    
    CGFloat scollviewHeight = kRowHeight * 8;
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleTextField.mas_bottom).offset(kMargin);
        make.left.right.inset(kMargin);
        make.height.mas_equalTo(scollviewHeight);
    }];
    
    [self.segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollView.mas_bottom).offset(15);
        make.left.equalTo(self.scrollView);
        make.size.mas_equalTo(CGSizeMake(80, 20));
        make.bottom.equalTo(self.view).offset(-kMargin);
    }];
}


#pragma mark - Getter && Setter

- (NSTextField *)titleTextField {
    if (!_titleTextField) {
        NSTextField *titleTextField = [NSTextField wrappingLabelWithString:NSLocalizedString(@"disabled_title", nil)];
        [self.view addSubview:titleTextField];
        titleTextField.font = [NSFont systemFontOfSize:14];
        _titleTextField = titleTextField;
    }
    return _titleTextField;
}

- (NSScrollView *)scrollView {
    if (!_scrollView) {
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:scrollView];
        _scrollView = scrollView;
        
        scrollView.wantsLayer = YES;
        scrollView.layer.cornerRadius = EZCornerRadius_8;
        
        [scrollView excuteLight:^(NSTableView *view) {
            view.backgroundColor = [NSColor ez_tableRowViewBgLightColor];
        } dark:^(NSTableView *view) {
            view.backgroundColor = [NSColor ez_tableRowViewBgDarkColor];
        }];
        
        scrollView.hasVerticalScroller = YES;
        scrollView.verticalScroller.controlSize = NSControlSizeSmall;
        [scrollView setAutomaticallyAdjustsContentInsets:NO];
        
        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, 0, 0);
        
        scrollView.documentView = self.tableView;
    }
    return _scrollView;
}

- (NSTableView *)tableView {
    if (!_tableView) {
        NSTableView *tableView = [[NSTableView alloc] initWithFrame:self.scrollView.bounds];
        _tableView = tableView;
        
        [tableView excuteLight:^(NSTableView *view) {
            view.backgroundColor = [NSColor ez_tableRowViewBgLightColor];
        } dark:^(NSTableView *view) {
            view.backgroundColor = [NSColor ez_tableRowViewBgDarkColor];
        }];
        
        tableView.style = NSTableViewStylePlain;
        
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:EZColumnId];
        self.column = column;
        column.resizingMask = NSTableColumnUserResizingMask | NSTableColumnAutoresizingMask;
        [tableView addTableColumn:column];
        
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = kRowHeight;
        tableView.allowsMultipleSelection = YES;
        [tableView setAutoresizesSubviews:YES];
        [tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
        
        tableView.headerView = nil;
        tableView.intercellSpacing = CGSizeMake(2 * 10, 0);
        tableView.gridColor = NSColor.clearColor;
        self.scrollView.documentView = tableView;
        [tableView sizeLastColumnToFit]; // must put in the end
    }
    return _tableView;
}

- (NSSegmentedControl *)segmentedControl {
    if (!_segmentedControl) {
        NSSegmentedControl *segmentedControl = [[NSSegmentedControl alloc] init];
        _segmentedControl = segmentedControl;
        [self.view addSubview:segmentedControl];
        [segmentedControl setSegmentCount:2];
        [segmentedControl setLabel:NSLocalizedString(@"+", nil) forSegment:0];
        [segmentedControl setLabel:NSLocalizedString(@"−", nil) forSegment:1];
        [segmentedControl setTarget:self];
        [segmentedControl setAction:@selector(segmentedControlClicked:)];
        segmentedControl.trackingMode = NSSegmentSwitchTrackingMomentary;
        
        [self disableDeleteAction];
    }
    return _segmentedControl;
}


#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.appModelList.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    EZAppCell *cell = [tableView makeViewWithIdentifier:EZAppCellId owner:self];
    if (!cell) {
        cell = [[EZAppCell alloc] init];
        cell.identifier = EZAppCellId;
    }
    
    cell.model = self.appModelList[row];
    
    return cell;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    EZCustomTableRowView *rowView = [[EZCustomTableRowView alloc] init];
    return rowView;
}

//  select cell
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = notification.object;
    NSInteger selectedRow = tableView.selectedRow;
    
    // selectedRow will be -1 when clicking the blank area of the tableview
    BOOL enabledSelected = selectedRow >= 0;
    [self.segmentedControl setEnabled:enabledSelected forSegment:1];
}

#pragma mark - Actions

- (void)segmentedControlClicked:(NSSegmentedControl *)sender {
    NSInteger index = [sender selectedSegment];
    
    if (index == 0) {
        [self selectApp];
    } else {
        NSIndexSet *selectedRows = [self.tableView selectedRowIndexes];
        NSMutableArray *selectedAppBundles = [NSMutableArray array];
        [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *_Nonnull stop) {
            [selectedAppBundles addObject:self.appModelList[idx]];
        }];
        
        [self.appModelList removeObjectsInArray:selectedAppBundles];
        [self updateLocalStoredAppModelList];
        
        [self.tableView reloadData];
        
        [self disableDeleteAction];
    }
}

#pragma mark -

- (void)selectApp {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:YES];
    NSArray<UTType *> *allowedTypes = @[ UTTypeApplication ];
    [openPanel setAllowedContentTypes:allowedTypes];
    
    // ???: Since [auto select] will cause lag when dragging select apps, I don't know why 😰
    EZConfiguration.shared.disabledAutoSelect = YES;
    
    NSModalResponse result = [openPanel runModal];
    if (result == NSModalResponseOK) {
        NSLog(@"selected URLs: %@", openPanel.URLs);
        
        NSArray *appModels = [self appModelsFromBundleURLs:openPanel.URLs];
        [self.appModelList addObjectsFromArray:appModels];
        [self updateLocalStoredAppModelList];
        
        [self.tableView reloadData];
    }
    
    EZConfiguration.shared.disabledAutoSelect = NO;
}

- (NSArray<EZAppModel *> *)appModelsFromBundleIDDict:(NSDictionary<NSString *, NSNumber *> *)appBundleIDDict {
    NSMutableArray *appModels = [NSMutableArray array];
    for (NSString *bundleID in appBundleIDDict.allKeys) {
        NSNumber *type = appBundleIDDict[bundleID];
        EZAppModel *appModel = [[EZAppModel alloc] init];
        appModel.appBundleID = bundleID;
        appModel.triggerType = type.integerValue;
        [appModels addObject:appModel];
    }
    return appModels;
}

- (NSArray<EZAppModel *> *)appModelsFromBundleURLs:(NSArray<NSURL *> *)appBundleURLs {
    NSMutableArray *appModels = [NSMutableArray array];
    for (NSURL *appBundleURL in appBundleURLs) {
        NSBundle *appBundle = [[NSBundle alloc] initWithURL:appBundleURL];
        if (appBundle) {
            EZAppModel *appModel = [[EZAppModel alloc] init];
            appModel.appBundleID = appBundle.bundleIdentifier;
            appModel.triggerType = EZTriggerTypeNone;
            if (![self.appModelList containsObject:appModel]) {
                [appModels addObject:appModel];
            }
        }
    }
    return appModels;
}

- (void)updateLocalStoredAppModelList {
    EZLocalStorage.shared.selectTextTypeAppModelList = self.appModelList;
}

- (void)disableDeleteAction {
    [self.segmentedControl setEnabled:NO forSegment:1];
}


#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"disabled_app_list", nil);
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:@"disable_blue"];
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
