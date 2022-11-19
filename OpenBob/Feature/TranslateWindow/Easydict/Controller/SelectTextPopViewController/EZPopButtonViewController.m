//
//  EZSelectTextPopViewController.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/17.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZPopButtonViewController.h"
#import "EZMiniWindowController.h"

static CGFloat kPopButtonWidth = 25;

@interface EZPopButtonViewController ()

@end

@implementation EZPopButtonViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, kPopButtonWidth, kPopButtonWidth)];
    self.view.wantsLayer = YES;
    self.view.layer.masksToBounds = YES;
    self.view.layer.backgroundColor = NSColor.clearColor.CGColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    EZButton *button = [[EZButton alloc] initWithFrame:self.view.bounds];
    NSImage *image = [NSImage imageNamed:@"Eudic"];
    button.image = image;
    button.backgroundColor = NSColor.clearColor;
    self.popButton = button;
    [self.view addSubview:button];
    button.center = self.view.center;
    
    mm_weakify(self);
    [button setHoverBlock:^(EZButton * _Nonnull button) {
        NSLog(@"hover pop button");
        mm_strongify(self);
        [self showPopButton];
    }];
    [button setClickBlock:^(EZButton * _Nonnull button) {
        [self showPopButton];
    }];
}

- (void)showPopButton {
    if(self.hoverBlock) {
        self.hoverBlock();
    } else if (self.clickBlock) {
        self.clickBlock();
    }
}

@end
