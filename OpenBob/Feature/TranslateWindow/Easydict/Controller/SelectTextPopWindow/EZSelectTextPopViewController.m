//
//  EZSelectTextPopViewController.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/17.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZSelectTextPopViewController.h"
#import "EZButton.h"

static CGFloat kSelectTextPopViewWidth = 50;

@interface EZSelectTextPopViewController ()

@end

@implementation EZSelectTextPopViewController

- (void)loadView {
    CGRect rect = CGRectMake(0, 0, kSelectTextPopViewWidth, kSelectTextPopViewWidth);
    self.view = [[NSView alloc] initWithFrame:rect];
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
    
//    CGRect rect = CGRectMake(0, 0, kSelectTextPopViewWidth, kSelectTextPopViewWidth);
    EZButton *button = [[EZButton alloc] initWithFrame:self.view.bounds];
    
    NSImage *image = [NSImage imageNamed:@"magnifier"];
    button.image = image;
    [button setClickBlock:^(EZButton * _Nonnull button) {
        NSLog(@"click button magnifier");
    }];
    
    [self.view addSubview:button];
}

@end
