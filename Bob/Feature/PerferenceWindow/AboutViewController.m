//
//  AboutViewController.m
//  Bob
//
//  Created by ripper on 2019/12/9.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@property (weak) IBOutlet NSTextField *versionTextField;
@property (weak) IBOutlet NSTextField *githubTextField;

@end

@implementation AboutViewController

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
