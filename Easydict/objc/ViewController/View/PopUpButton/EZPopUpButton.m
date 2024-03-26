//
//  EZPopButton.m
//  Easydict
//
//  Created by tisfeng on 2022/11/24.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZPopUpButton.h"

@interface EZPopUpButton ()

@property (nonatomic, strong) NSArray<NSString *> *titles;

@end


@implementation EZPopUpButton

DefineMethodMMMake_m(EZPopUpButton);

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.title = @"";
    
    mm_weakify(self)
    [self setClickBlock:^(EZButton *_Nonnull button) {
        mm_strongify(self)
        // 显示menu
        if (self.titles.count) {
            [self setupMenu];
            [self.customMenu popUpBelowView:self];
        }
    }];
    
    [NSView mm_make:^(NSView *_Nonnull titleContainerView) {
        [self addSubview:titleContainerView];
        titleContainerView.layer.backgroundColor = [NSColor redColor].CGColor;
        titleContainerView.wantsLayer = YES;
        [titleContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.offset(0);
            make.left.mas_greaterThanOrEqualTo(5);
            make.right.mas_lessThanOrEqualTo(5);
        }];
        
        self.textField = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            [titleContainerView addSubview:textField];
            textField.stringValue = @"";
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            textField.font = [NSFont systemFontOfSize:13];
            textField.maximumNumberOfLines = 1;
            textField.lineBreakMode = NSLineBreakByTruncatingTail;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.left.bottom.equalTo(titleContainerView);
            }];
            [textField excuteLight:^(NSTextField *label) {
                label.textColor = [NSColor ez_resultTextLightColor];
            } dark:^(NSTextField *label) {
                label.textColor = [NSColor ez_resultTextDarkColor];
            }];
        }];
        
        self.imageView = [NSImageView mm_make:^(NSImageView *_Nonnull imageView) {
            [titleContainerView addSubview:imageView];
            NSImage *image = [NSImage imageNamed:@"arrow_down_filling"];
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.textField.mas_right).offset(3);
                make.centerY.equalTo(self.textField).offset(1);
                make.right.equalTo(titleContainerView);
                make.width.height.equalTo(@8);
            }];
            [imageView excuteLight:^(NSImageView *imageView) {
                imageView.image = [image imageWithTintColor:[NSColor ez_imageTintLightColor]];
            } dark:^(NSTextField *label) {
                imageView.image = [image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
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
    [self.titles enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
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
