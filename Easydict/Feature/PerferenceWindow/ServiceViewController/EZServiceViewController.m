//
//  EZServiceViewController.m
//  Easydict
//
//  Created by tisfeng on 2022/12/25.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZServiceViewController.h"
#import "EZServiceCell.h"
#import "EZServiceTypes.h"
#import "EZCustomTableRowView.h"
#import "EZLocalStorage.h"

static CGFloat const kMargin = 20;
static CGFloat const kPadding = 20;
static CGFloat const kRowHeight = 40;

static NSString *const EZServiceCellId = @"EZServiceCellId";
static NSString *const EZColumnId = @"EZColumnId";

@interface EZServiceViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSSegmentedControl *segmentedControl;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSTableColumn *column;

@property (nonatomic, strong) EZServiceCell *serviceCell;
@property (nonatomic, strong) NSMutableArray<EZServiceType> *serviceTypes;
@property (nonatomic, strong) NSMutableArray<EZQueryService *> *services;

@property (nonatomic, assign) EZWindowType windowType;
@property (nonatomic, copy) NSDictionary<NSNumber *, NSNumber *> *windowTypesDictionary;

@end

@implementation EZServiceViewController

- (void)loadView {
    CGRect frame = CGRectMake(0, 0, 350, 300);
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
    self.windowTypesDictionary = @{
        @(0) : @(EZWindowTypeMini),
        @(1) : @(EZWindowTypeFixed),
        @(2) : @(EZWindowTypeMain),
    };

    [self setupUIDataWithWindowType:EZWindowTypeMini];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleServiceUpdate:) name:EZServiceHasUpdatedNotification object:nil];
}

- (void)setupUIDataWithWindowType:(EZWindowType)windowType {
    self.windowType = windowType;
    self.serviceTypes = [[EZLocalStorage.shared allServiceTypes:windowType] mutableCopy];
    self.services = [[EZLocalStorage.shared allServices:windowType] mutableCopy];
    
    [self.tableView reloadData];
    [self updateScrollViewHeight];
}

- (void)updateScrollViewHeight {
    CGFloat tableViewHeight = [self getScrollViewContentHeight];
    [self.scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(tableViewHeight);
    }];
}

- (CGFloat)getScrollViewContentHeight {
    self.scrollView.height = 0;
    CGFloat documentViewHeight = self.scrollView.documentView.height; // actually is tableView height
    return documentViewHeight;
}

#pragma mark - NSNotificationCenter

- (void)handleServiceUpdate:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;

    EZWindowType windowType = [notification.userInfo[EZWindowTypeKey] integerValue];
    if (windowType == self.windowType || !userInfo) {
        [self setupUIDataWithWindowType:self.windowType];
    }
}

#pragma mark - Getter && Setter

- (NSSegmentedControl *)segmentedControl {
    if (!_segmentedControl) {
        NSSegmentedControl *segmentedControl = [[NSSegmentedControl alloc] init];
        [self.view addSubview:segmentedControl];
        [segmentedControl setSegmentCount:3];
        [segmentedControl setLabel:NSLocalizedString(@"mini_window", nil) forSegment:0];
        [segmentedControl setLabel:NSLocalizedString(@"fixed_window", nil) forSegment:1];
        [segmentedControl setLabel:NSLocalizedString(@"main_window", nil) forSegment:2];
        [segmentedControl setTarget:self];
        [segmentedControl setAction:@selector(segmentedControlClicked:)];
        [segmentedControl setSelectedSegment:0];
        [segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.inset(kMargin);
            make.height.mas_equalTo(25);
        }];
        _segmentedControl = segmentedControl;
    }
    return _segmentedControl;
}

- (NSScrollView *)scrollView {
    if (!_scrollView) {
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:scrollView];
        _scrollView = scrollView;

        scrollView.wantsLayer = YES;
        scrollView.layer.cornerRadius = EZCornerRadius_8;

        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.segmentedControl.mas_bottom).offset(kPadding);
            make.left.right.bottom.inset(kMargin);
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
        [tableView registerForDraggedTypes:@[ NSPasteboardTypeString ]];
        [tableView setAutoresizesSubviews:YES];
        [tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];

        tableView.headerView = nil;
        tableView.intercellSpacing = CGSizeMake(2 * EZHorizontalCellSpacing_12, EZVerticalCellSpacing_8);
        tableView.gridColor = NSColor.clearColor;
        self.scrollView.documentView = tableView;
        [tableView sizeLastColumnToFit]; // must put in the end
    }
    return _tableView;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.services.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    EZServiceCell *cell = [tableView makeViewWithIdentifier:EZServiceCellId owner:self];
    if (!cell) {
        cell = [[EZServiceCell alloc] init];
        cell.identifier = EZServiceCellId;
    }

    EZQueryService *service = self.services[row];
    cell.service = service;

    mm_weakify(self, service);

    [cell setClickToggleButton:^(NSButton *button) {
        mm_strongify(self, service);
        service.enabled = button.mm_isOn;

        // Set enabledQuery to YES if service enabled.
        if (service.enabled) {
            service.enabledQuery = YES;
        }
        [EZLocalStorage.shared setService:service windowType:self.windowType];
        [self postUpdateServiceNotification];
    }];

    return cell;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    EZCustomTableRowView *rowView = [[EZCustomTableRowView alloc] init];
    return rowView;
}

- (nullable id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    EZQueryService *service = self.services[row];
    return service.serviceType;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    if (dropOperation == NSTableViewDropAbove) {
        return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    EZServiceType draggedServiceType = [info.draggingPasteboard stringForType:NSPasteboardTypeString];
    NSArray *oldEnabledServiceTypes = [self enabledServiceTypes:self.services];
    if ([self.serviceTypes containsObject:draggedServiceType]) {
        NSInteger oldIndex = [self.serviceTypes indexOfObject:draggedServiceType];
        NSLog(@"oldIndex: %ld, to row: %ld", oldIndex, row);
        [self.serviceTypes insertObject:draggedServiceType atIndex:row];

        NSInteger removedIndex = oldIndex;
        if (row < oldIndex) {
            removedIndex = oldIndex + 1;
        }
        NSLog(@"removedIndex: %ld", removedIndex);
        [self.serviceTypes removeObjectAtIndex:removedIndex];

        EZLocalStorage *localStorage = [EZLocalStorage shared];
        [localStorage setAllServiceTypes:self.serviceTypes windowType:self.windowType];
        self.services = [[localStorage allServices:self.windowType] mutableCopy];
        [self.tableView reloadData];

        // If the order of enabled services is changed, need to post notification.
        NSArray *newEnabledServiceTypes = [self enabledServiceTypes:self.services];
        if (![newEnabledServiceTypes isEqualToArray:oldEnabledServiceTypes]) {
            [self postUpdateServiceNotification];
        }
    }

    return YES;
}

- (EZQueryService *)serviceWithType:(EZServiceType)type {
    NSInteger index = [self.serviceTypes indexOfObject:type];
    if (index != NSNotFound) {
        return self.services[index];
    }
    return nil;
}


- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
}

//  select cell
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return YES;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
}

#pragma mark - Actions

- (void)segmentedControlClicked:(NSSegmentedControl *)sender {
    NSInteger index = [sender selectedSegment];
    EZWindowType windowType = [self.windowTypesDictionary[@(index)] integerValue];
    [self setupUIDataWithWindowType:windowType];
    [self.tableView reloadData];
}

#pragma mark -

- (void)postUpdateServiceNotification {
    NSDictionary *userInfo = @{EZWindowTypeKey : @(self.windowType)};
    NSNotification *notification = [NSNotification notificationWithName:EZServiceHasUpdatedNotification object:nil userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (NSArray *)enabledServiceTypes:(NSArray *)services {
    NSMutableArray *array = [NSMutableArray array];
    for (EZQueryService *service in services) {
        if (service.enabled) {
            [array addObject:service.serviceType];
        }
    }
    return array;
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"service", nil);
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:@"toolbar_service"];
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
