//
//  SnipFocusView.m
//  Bob
//
//  Created by ripper on 2019/11/29.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "SnipFocusView.h"

@implementation SnipFocusView

DefineMethodMMMake_m(SnipFocusView)

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor mm_colorWithHexString:@"#007AFF"].CGColor;
    self.layer.borderColor = [NSColor whiteColor].CGColor;
    self.layer.borderWidth = 1;
    self.shadow = [NSShadow new];
    self.layer.shadowColor = [NSColor blackColor].CGColor;
    self.layer.shadowRadius = 4;
    self.layer.shadowOpacity = 0.2;
    
    self.imageView = [NSImageView mm_make:^(NSImageView * _Nonnull imageView) {
        [self addSubview:imageView];
        imageView.wantsLayer = YES;
        imageView.layer.backgroundColor = NSColor.whiteColor.CGColor;
        imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.offset(0);
            make.width.height.equalTo(@100);
        }];
    }];
    
    [NSView mm_make:^(NSView * _Nonnull view) {
        [self.imageView addSubview:view];
        view.wantsLayer = YES;
        view.layer.backgroundColor = self.layer.backgroundColor;
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.offset(0);
            make.centerY.equalTo(self.imageView);
            make.height.equalTo(@1);
        }];
    }];

    [NSView mm_make:^(NSView * _Nonnull view) {
        [self.imageView addSubview:view];
        view.wantsLayer = YES;
        view.layer.backgroundColor = self.layer.backgroundColor;
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.offset(0);
            make.centerX.equalTo(self.imageView);
            make.width.equalTo(@1);
        }];
    }];
    
    self.locationTextField = [NSTextField mm_make:^(NSTextField * _Nonnull textField) {
        [self addSubview:textField];
        textField.stringValue = @"坐标: (0, 0)";
        textField.editable = NO;
        textField.bordered = NO;
        textField.backgroundColor = NSColor.clearColor;
        textField.font = [NSFont systemFontOfSize:10];
        textField.textColor = [NSColor whiteColor];
        [textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(5);
            make.top.equalTo(self.imageView.mas_bottom).offset(2);
        }];
    }];
    
    self.sizeTextFiled = [NSTextField mm_make:^(NSTextField * _Nonnull textField) {
        [self addSubview:textField];
        textField.stringValue = @"尺寸: (0, 0)";
        textField.editable = NO;
        textField.bordered = NO;
        textField.backgroundColor = NSColor.clearColor;
        textField.font = [NSFont systemFontOfSize:10];
        textField.textColor = [NSColor whiteColor];
        [textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.locationTextField);
            make.top.equalTo(self.locationTextField.mas_bottom);
        }];
    }];

}

- (CGSize)expectSize {
    return CGSizeMake(100, 132);
}

@end
