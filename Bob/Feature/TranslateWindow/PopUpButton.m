//
//  PopUpButton.m
//  Bob
//
//  Created by ripper on 2019/11/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "PopUpButton.h"

@interface PopUpButton ()

@property (nonatomic, strong) NSArray<NSString *> *titles;

@end

@implementation PopUpButton

DefineMethodMMMake_m(PopUpButton)

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.wantsLayer = YES;
    [self.layer excuteLight:^(id  _Nonnull x) {
        [x setBorderColor:[NSColor mm_colorWithHexString:@"#EEEEEE"].CGColor];
    } drak:^(id  _Nonnull x) {
        [x setBorderColor:DarkBorderColor.CGColor];
    }];
    self.layer.borderWidth = 1;
    self.layer.cornerRadius = 4;
    self.bordered = NO;
    self.imageScaling = NSImageScaleProportionallyDown;
    self.bezelStyle = NSBezelStyleRegularSquare;
    [self setButtonType:NSButtonTypeToggle];
    self.title = @"";
    mm_weakify(self)
    [self setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        mm_strongify(self)
        // 显示menu
        if (self.titles.count) {
            [self setupMenu];
            [self.customMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, 0) inView:self];
        }
        return RACSignal.empty;
    }]];
    
    [NSView mm_make:^(NSView * _Nonnull titleContainerView) {
        [self addSubview:titleContainerView];
        titleContainerView.layer.backgroundColor = [NSColor redColor].CGColor;
        titleContainerView.wantsLayer = YES;
        [titleContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.offset(0);
            make.left.mas_greaterThanOrEqualTo(5);
            make.right.mas_lessThanOrEqualTo(5);
        }];
        
        self.textField = [NSTextField mm_make:^(NSTextField * _Nonnull textField) {
            [titleContainerView addSubview:textField];
            textField.stringValue = @"";
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            textField.font = [NSFont systemFontOfSize:12];
            [textField excuteLight:^(id  _Nonnull x) {
                textField.textColor = [NSColor mm_colorWithHexString:@"#333333"];
            } drak:^(id  _Nonnull x) {
                textField.textColor = [NSColor whiteColor];
            }];
            textField.maximumNumberOfLines = 1;
            textField.lineBreakMode = NSLineBreakByTruncatingTail;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.left.bottom.equalTo(titleContainerView);
            }];
        }];
        
        self.imageView = [NSImageView mm_make:^(NSImageView * _Nonnull imageView) {
            [titleContainerView addSubview:imageView];
            imageView.image = [NSImage imageNamed:@"arrow_down"];
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.textField.mas_right).offset(3);
                make.centerY.equalTo(self.textField).offset(1);
                make.right.equalTo(titleContainerView);
                make.width.height.equalTo(@8);
            }];
        }];
    }];
}

#pragma mark -

- (void)setupMenu {
    if (!self.customMenu) {
        self.customMenu = [NSMenu new];
    }
    [self.customMenu removeAllItems];
    [self.titles enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:obj action:@selector(clickItem:) keyEquivalent:@""];
        item.tag = idx;
        item.target = self;
        [self.customMenu addItem:item];
    }];
}

- (void)clickItem:(NSMenuItem *)item {
    [self updateWithIndex:item.tag];
    if (self.menuItemSeletedBlock) {
        self.menuItemSeletedBlock(item.tag, item.title);
    }
    self.customMenu = nil;
}

- (void)updateMenuWithTitleArray:(NSArray<NSString *> *)titles {
    self.titles = titles;
    
    if (self.customMenu) {
        [self setupMenu];
    }
}

- (void)updateWithIndex:(NSInteger)index {
    if (index >= 0 && index < self.titles.count) {
        self.textField.stringValue = [self.titles objectAtIndex:index];
    }
}

@end
