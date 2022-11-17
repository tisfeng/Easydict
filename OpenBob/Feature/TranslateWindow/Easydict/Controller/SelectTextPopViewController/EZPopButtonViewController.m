//
//  EZSelectTextPopViewController.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/17.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZPopButtonViewController.h"
#import "EZButton.h"
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
    button.center = self.view.center;
    [self.view addSubview:button];
    
    mm_weakify(self);
    [button setHoverBlock:^(EZButton * _Nonnull button) {
        mm_strongify(self);
        if(self.hoverBlock) {
            self.hoverBlock();
        }
    }];
}

@end
