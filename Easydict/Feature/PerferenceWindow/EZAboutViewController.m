//
//  EZAboutViewController.m
//  Easydict
//
//  Created by tisfeng on 2022/12/15.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZAboutViewController.h"


@interface EZAboutViewController ()

@property (weak) IBOutlet NSTextField *versionTextField;
@property (weak) IBOutlet NSTextField *githubTextField;

@end


@implementation EZAboutViewController

- (instancetype)init {
    return [super initWithNibName:[self className] bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.versionTextField.stringValue = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (IBAction)githubTextFieldClicked:(NSClickGestureRecognizer *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.githubTextField.stringValue]];
}


#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return @"关于";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:@"toolbar_about"];
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
