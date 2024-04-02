//
//  EZServiceCell.m
//  Easydict
//
//  Created by tisfeng on 2022/12/25.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZServiceCell.h"
#import "NSImage+EZResize.h"

@interface EZServiceCell ()

@property (nonatomic, strong) NSImageView *iconView;
@property (nonatomic, strong) NSTextField *nameLabel;
@property (nonatomic, strong) NSButton *toggleButton;

@end

@implementation EZServiceCell

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
        
        
        self.toggleButton = [[NSButton alloc] init];
        [self.toggleButton setTarget:self];
        [self.toggleButton setAction:@selector(clickToggleButton:)];
        
        [self.toggleButton setButtonType:NSButtonTypeToggle];
        self.toggleButton.imageScaling = NSImageScaleProportionallyDown;
        self.toggleButton.bordered = NO;
        self.toggleButton.bezelStyle = NSBezelStyleTexturedSquare;
        
        CGSize imageSize = CGSizeMake(35, 35);
        
        // Since using the system's dark mode image, the image is still a dark image even after switching to light mode, so we need to switch it manually.
        [self.toggleButton excuteLight:^(NSButton *button) {
            button.image = [[NSImage imageNamed:@"toggle_off_blue_light"] resizeToSize:imageSize];
        } dark:^(NSButton *button) {
            button.image = [[NSImage imageNamed:@"toggle_off_blue_dark"] resizeToSize:imageSize];
        }];
        
        NSImage *switchOnImage = [[NSImage imageNamed:@"toggle_on_blue"] resizeToSize:imageSize];
        [self.toggleButton setAlternateImage:switchOnImage];
        
        [self addSubview:self.iconView];
        [self addSubview:self.nameLabel];
        [self addSubview:self.toggleButton];
        
        
        [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(self).offset(9);
            make.width.height.mas_equalTo(20);
        }];
        
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.iconView.mas_right).offset(10);
            make.centerY.equalTo(self.iconView);
            make.right.lessThanOrEqualTo(self.toggleButton.mas_left).offset(-10);
        }];
        
        [self.toggleButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-10);
            make.centerY.equalTo(self.iconView);
        }];
    }
    return self;
}

- (void)setService:(EZQueryService *)service {
    _service = service;
    
    EZServiceType serviceType = service.serviceType;
    self.iconView.image = [NSImage imageNamed:serviceType];
    
    self.nameLabel.attributedStringValue = [NSAttributedString mm_attributedStringWithString:service.name font:[NSFont systemFontOfSize:13]];
    
    self.toggleButton.mm_isOn = service.enabled;
}

- (void)clickToggleButton:(NSButton *)button {
    if (self.clickToggleButton) {
        self.clickToggleButton(button);
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
