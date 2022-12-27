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
#import "EZServiceRowView.h"
#import "EZLocalStorage.h"

static CGFloat const kMargin = 15;
static CGFloat const kRowHeight = 40;

static NSString *const EZServiceCellId = @"EZServiceCellId";
static NSString *const EZColumnId = @"EZColumnId";

@interface EZServiceViewController ()<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSTableColumn *column;

@property (nonatomic, strong) EZServiceCell *serviceCell;
@property (nonatomic, strong) NSMutableArray<EZServiceType> *serviceTypes;
@property (nonatomic, strong) NSMutableArray<EZQueryService *> *services;

@end

@implementation EZServiceViewController


/// 用代码创建 NSViewController 貌似不会自动创建 view，需要手动初始化
- (void)loadView {
    CGRect frame = CGRectMake(0, 0, 300, 300);
    self.view = [[NSView alloc] initWithFrame:frame];
    self.view.wantsLayer = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}

- (void)setup {
    self.serviceTypes = [[EZLocalStorage.shared allServiceTypes] mutableCopy];
    self.services = [[EZLocalStorage.shared allServices] mutableCopy];
    
    [self tableView];
    
    CGFloat viewHeight = kMargin * 2 + self.services.count * (kRowHeight + EZVerticalCellSpacing_8);
    self.view.height = viewHeight;
}


#pragma mark - Getter && Setter

- (NSScrollView *)scrollView {
    if (!_scrollView) {
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:scrollView];
        _scrollView = scrollView;
        
        scrollView.wantsLayer = YES;
        scrollView.layer.cornerRadius = EZCornerRadius_8;
        
        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view).insets(NSEdgeInsetsMake(kMargin, kMargin, kMargin, kMargin));
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
        
        tableView.style = NSTableViewStylePlain;
        
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:EZColumnId];
        self.column = column;
        column.resizingMask = NSTableColumnUserResizingMask | NSTableColumnAutoresizingMask;
        [tableView addTableColumn:column];
        
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 40;
        [tableView registerForDraggedTypes:@[NSPasteboardTypeString]];
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
    EZServiceCell *cell = [tableView makeViewWithIdentifier:@"EZServiceCell" owner:self];
    if (!cell) {
        cell = [[EZServiceCell alloc] init];
        cell.identifier = @"EZServiceCell";
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
        [EZLocalStorage.shared saveService:service];
        [self postUpdateServiceNotification];
    }];
    
    return cell;
    
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [[EZServiceRowView alloc] init];
}

- (nullable id <NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
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
    
    EZServiceType oldServiceType = [info.draggingPasteboard stringForType:NSPasteboardTypeString];
    if ([self.serviceTypes containsObject:oldServiceType]) {
        NSInteger oldIndex = [self.serviceTypes indexOfObject:oldServiceType];
        NSLog(@"oldIndex: %ld, to row: %ld", oldIndex, row);
        [self.serviceTypes insertObject:oldServiceType atIndex:row];
        
        NSInteger removedIndex = oldIndex;
        if (row < oldIndex) {
            removedIndex = oldIndex + 1;
        }
        NSLog(@"removedIndex: %ld", removedIndex);
        [self.serviceTypes removeObjectAtIndex:removedIndex];
        EZLocalStorage.shared.allServiceTypes = self.serviceTypes;
        self.services = [[[EZLocalStorage shared] allServices] mutableCopy];
        [self.tableView reloadData];
        
        [self postUpdateServiceNotification];
    }
    
    return YES;
}


- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    
}

//  select cell
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return YES;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
    
}

#pragma mark -

- (void)postUpdateServiceNotification {
    NSNotification *notification = [NSNotification notificationWithName:EZServiceHasUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
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
