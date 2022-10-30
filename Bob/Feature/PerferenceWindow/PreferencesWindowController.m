//
//  PreferencesWindowController.m
//  Bob
//
//  Created by ripper on 2019/12/9.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "GeneralViewController.h"
#import "AboutViewController.h"

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController

static PreferencesWindowController *_instance;
+ (instancetype)shared {
    if (!_instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSArray *viewControllers = @[
                [GeneralViewController new],
                [AboutViewController new],
            ];
            _instance = [[self alloc] initWithViewControllers:viewControllers];
        });
    }
    return _instance;
}

#pragma mark -

- (void)show {
    [self.window makeKeyAndOrderFront:nil];
    if (!self.window.isKeyWindow) {
        [NSApp activateIgnoringOtherApps:YES];
    }
    [self.window center];
}

@end
