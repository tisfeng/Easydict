//
//  EZPreferencesWindowController.m
//  Easydict
//
//  Created by tisfeng on 2022/12/15.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZPreferencesWindowController.h"
#import "EZSettingViewController.h"
#import "EZAboutViewController.h"
#import "EZServiceViewController.h"
#import "EZPrivacyViewController.h"
#import "EZDisableAutoSelectTextViewController.h"

@interface EZPreferencesWindowController ()

@end

@implementation EZPreferencesWindowController

static EZPreferencesWindowController *_instance;
+ (instancetype)shared {
    if (!_instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSArray *viewControllers = @[
                [[EZSettingViewController alloc] init],
                [[EZServiceViewController alloc] init],
                [[EZDisableAutoSelectTextViewController alloc] init],
                [[EZPrivacyViewController alloc] init],
                [[EZAboutViewController alloc] init],
            ];
            
            NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
            _instance = [[self alloc] initWithViewControllers:viewControllers title:appName];
        });
    }
    return _instance;
}

#pragma mark -

- (void)show {
    _isShowing = YES;
    
    [self.window makeKeyAndOrderFront:nil];
    if (!self.window.isKeyWindow) {
        [NSApp activateIgnoringOtherApps:YES];
    }
    [self.window center];
}

- (void)windowWillClose:(NSNotification *)notification {
    _isShowing = NO;
}

@end
