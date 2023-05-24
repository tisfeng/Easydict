//
//  EZSelectTextPopViewController.m
//  Easydict
//
//  Created by tisfeng on 2022/11/17.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZPopButtonViewController.h"

static CGFloat kPopButtonWidth = 23;

@interface EZPopButtonViewController ()

@end

@implementation EZPopButtonViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, kPopButtonWidth, kPopButtonWidth)];
    self.view.wantsLayer = YES;
    self.view.layer.cornerRadius = 5;
    self.view.layer.masksToBounds = YES;
    self.view.layer.backgroundColor = NSColor.clearColor.CGColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    EZButton *button = [[EZButton alloc] initWithFrame:self.view.bounds];
    NSImage *image = [NSImage imageNamed:@"blue-white-icon"];
    button.image = image;
    button.backgroundColor = NSColor.clearColor;
    self.popButton = button;
    [self.view addSubview:button];
    button.center = self.view.center;
}

@end
