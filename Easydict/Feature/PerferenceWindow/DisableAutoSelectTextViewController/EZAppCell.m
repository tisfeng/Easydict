//
//  EZAppCell.m
//  Easydict
//
//  Created by tisfeng on 2023/6/16.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZAppCell.h"
#import "NSImage+EZResize.h"

@interface EZAppCell ()

@property (nonatomic, strong) NSImageView *iconView;
@property (nonatomic, strong) NSTextField *nameLabel;

@end

@implementation EZAppCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = EZCornerRadius_8;
        self.layer.masksToBounds = YES;

        self.iconView = [[NSImageView alloc] init];
        self.nameLabel = [NSTextField labelWithString:@""];
        self.nameLabel.textColor = [NSColor blackColor];
        [self.nameLabel excuteLight:^(NSTextField *nameLabel) {
            nameLabel.textColor = [NSColor blackColor];
        } dark:^(NSTextField *nameLabel) {
            nameLabel.textColor = [NSColor whiteColor];
        }];
        
        [self addSubview:self.iconView];
        [self addSubview:self.nameLabel];
        
        [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(3);
            make.centerY.equalTo(self);
            make.width.height.mas_equalTo(24);
        }];
        
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.iconView.mas_right).offset(8);
            make.centerY.equalTo(self.iconView);
        }];
    }
    return self;
}


- (void)setModel:(EZAppModel *)model {
    _model = model;
    
    NSURL *appURL = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:model.appBundleID];
    NSBundle *appBundle = [[NSBundle alloc] initWithURL:appURL];
    
    NSString *iconFileName = appBundle.infoDictionary[@"CFBundleIconFile"];
    NSImage *appIcon = [appBundle imageForResource:iconFileName];
    self.iconView.image = appIcon;
    
    NSString *appName = [appBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!appName) {
        appName = [appBundle objectForInfoDictionaryKey:@"CFBundleName"];
    }
    self.nameLabel.attributedStringValue = [NSAttributedString mm_attributedStringWithString:appName font:[NSFont systemFontOfSize:13]];
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
