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
#import "EZServiceRowView.h"
#import "EZLocalStorage.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "EZConstKey.h"
#import "EZLocalStorage.h"
#import "EZConfiguration.h"

static CGFloat const kMargin = 20;
static CGFloat const kPadding = 20;
static CGFloat const kRowHeight = 40;

static NSString *const EZAppCellId = @"EZAppCellId";
static NSString *const EZColumnId = @"EZColumnId";

@interface EZDisableAutoSelectTextViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSTextField *titleTextField;
@property (nonatomic, strong) NSSegmentedControl *segmentedControl;

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSTableColumn *column;

@property (nonatomic, strong) NSMutableArray<NSString *> *disabledAppBundleIDList;
@property (nonatomic, strong) NSMutableArray<NSBundle *> *appBundleList;

@end

@implementation EZDisableAutoSelectTextViewController

- (void)loadView {
    CGRect frame = CGRectMake(0, 0, 400, 350);
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
    NSArray *disabledAppBundleIDList = [EZLocalStorage.shared disabledAppBundleIDList];
    
    self.disabledAppBundleIDList = [disabledAppBundleIDList mutableCopy];

    self.appBundleList = [[self appBundlesFromBundleIDList:self.disabledAppBundleIDList] mutableCopy];
        
    [self.tableView reloadData];
    [self updateScrollViewHeight];
}

- (void)updateScrollViewHeight {
    CGFloat tableViewHeight = [self getScrollViewContentHeight];
    [self.scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(tableViewHeight);
    }];
    
    [self.segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollView.mas_bottom).offset(15);
        make.left.equalTo(self.scrollView);
        make.size.mas_equalTo(CGSizeMake(80, 20));
        make.bottom.equalTo(self.view).offset(-kPadding);
    }];
}

- (CGFloat)getScrollViewContentHeight {
    self.scrollView.height = 0;
    CGFloat documentViewHeight = self.scrollView.documentView.height; // actually is tableView height
    CGFloat height = MAX(documentViewHeight, kRowHeight * 5);
    return height;
}


#pragma mark - Getter && Setter

- (NSTextField *)titleTextField {
    if (!_titleTextField) {
        NSTextField *titleTextField = [NSTextField wrappingLabelWithString:NSLocalizedString(@"disabled_title", nil)];
        [self.view addSubview:titleTextField];
        titleTextField.font = [NSFont systemFontOfSize:14];
        [titleTextField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.inset(kMargin + 5); // ???: Why is the actual inset is 18?
        }];
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

        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleTextField.mas_bottom).offset(kPadding);
            make.left.right.inset(kMargin);
        }];

        scrollView.hasVerticalScroller = YES;
        scrollView.verticalScroller.controlSize = NSControlSizeSmall;
        [scrollView setAutomaticallyAdjustsContentInsets:NO];

        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, 0, 0);
    }
    return _scrollView;
}

- (NSTableView *)tableView {
    if (!_tableView) {
        NSTableView *tableView = [[NSTableView alloc] initWithFrame:self.scrollView.bounds];
        _tableView = tableView;

        [tableView excuteLight:^(NSTableView *view) {
            view.backgroundColor = NSColor.whiteColor;
        } dark:^(NSTableView *view) {
            view.backgroundColor = [NSColor mm_colorWithHexString:@"#28292A"];
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
    return self.appBundleList.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    EZAppCell *cell = [tableView makeViewWithIdentifier:EZAppCellId owner:self];
    if (!cell) {
        cell = [[EZAppCell alloc] init];
        cell.identifier = EZAppCellId;
    }

    NSBundle *bundle = self.appBundleList[row];
    cell.appBundle = bundle;

    return cell;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    EZServiceRowView *rowView = [[EZServiceRowView alloc] init];
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
        [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            [selectedAppBundles addObject:self.appBundleList[idx]];
        }];

        [self.appBundleList removeObjectsInArray:selectedAppBundles];
        [self updateDisabledAppBundleIDList];
        
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
    NSArray<UTType *> *allowedTypes = @[UTTypeApplication];
    [openPanel setAllowedContentTypes:allowedTypes];

    // ???: Since [auto select] will cause lag when dragging select apps, I don't know why 😰
    EZConfiguration.shared.disabledAutoSelect = YES;
    
    NSModalResponse result = [openPanel runModal];
    if (result == NSModalResponseOK) {
        NSLog(@"selected URLs: %@", openPanel.URLs);
        
        NSArray *appBundleIDList = [self appBundleIDListFromBundleURLs:openPanel.URLs];
        NSArray *appBundles = [self appBundlesFromBundleIDList:appBundleIDList];
        [self.appBundleList addObjectsFromArray:appBundles];
        [self updateDisabledAppBundleIDList];

        [self.tableView reloadData];
    }
    
    EZConfiguration.shared.disabledAutoSelect = NO;
}

- (NSArray<NSBundle *> *)appBundlesFromBundleIDList:(NSArray<NSString *> *)appBundleIDList {
    NSMutableArray *appBundles = [NSMutableArray array];
    for (NSString *bundleID in appBundleIDList) {
        NSURL *appURL = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:bundleID];
        NSBundle *appBundle = [[NSBundle alloc] initWithURL:appURL];
        if (appBundle) {
            [appBundles addObject:appBundle];
        }
    }
    return appBundles;
}

- (NSArray<NSString *> *)appBundleIDListFromBundleURLs:(NSArray<NSURL *> *)appBundleURLs {
    NSMutableArray *appBundleIDList = [NSMutableArray array];
    for (NSURL *appBundleURL in appBundleURLs) {
        NSBundle *appBundle = [[NSBundle alloc] initWithURL:appBundleURL];
        if (appBundle) {
            NSString *bundleID = appBundle.bundleIdentifier;
            if (![self.disabledAppBundleIDList containsObject:bundleID]) {
                [appBundleIDList addObject:bundleID];
            }
        }
    }
    return appBundleIDList;
}

- (void)updateDisabledAppBundleIDList {
    // generate disabledAppBundleIDList from self.appBundleList
    NSMutableArray *disabledAppBundleIDList = [NSMutableArray array];
    for (NSBundle *bundle in self.appBundleList) {
        NSString *bundleID = bundle.bundleIdentifier;
        [disabledAppBundleIDList addObject:bundleID];
    }
    self.disabledAppBundleIDList = disabledAppBundleIDList;
    
    EZLocalStorage.shared.disabledAppBundleIDList = self.disabledAppBundleIDList;
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
