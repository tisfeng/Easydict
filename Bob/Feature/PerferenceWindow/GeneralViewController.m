//
//  GeneralViewController.m
//  Bob
//
//  Created by ripper on 2019/12/9.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "GeneralViewController.h"
#import "Shortcut.h"
#import "Configuration.h"

@interface GeneralViewController ()

@property (weak) IBOutlet MASShortcutView *selectionShortcutView;
@property (weak) IBOutlet MASShortcutView *snipShortcutView;
@property (weak) IBOutlet MASShortcutView *inputShortcutView;
@property (weak) IBOutlet NSButton *autoCopyTranslateResultButton;
@property (weak) IBOutlet NSButton *launchAtStartupButton;
@property (weak) IBOutlet NSButton *autoCheckUpdateButton;

@end

@implementation GeneralViewController

- (instancetype)init {
    return [super initWithNibName:[self className] bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.selectionShortcutView.style = MASShortcutViewStyleTexturedRect;
    [self.selectionShortcutView setAssociatedUserDefaultsKey:SelectionShortcutKey];
    
    self.snipShortcutView.style = MASShortcutViewStyleTexturedRect;
    [self.snipShortcutView setAssociatedUserDefaultsKey:SnipShortcutKey];
    
    self.inputShortcutView.style = MASShortcutViewStyleTexturedRect;
    [self.inputShortcutView setAssociatedUserDefaultsKey:InputShortcutKey];

    self.autoCopyTranslateResultButton.mm_isOn = Configuration.shared.autoCopyTranslateResult;
    self.launchAtStartupButton.mm_isOn = Configuration.shared.launchAtStartup;
    self.autoCheckUpdateButton.mm_isOn = Configuration.shared.automaticallyChecksForUpdates;
}

#pragma mark - event

- (IBAction)autoCopyTranslateResultButtonClicked:(NSButton *)sender {
    Configuration.shared.autoCopyTranslateResult = sender.mm_isOn;
}

- (IBAction)launchAtStartupButtonClicked:(NSButton *)sender {
    Configuration.shared.launchAtStartup = sender.mm_isOn;
}

- (IBAction)autoCheckUpdateButtonClicked:(NSButton *)sender {
    Configuration.shared.automaticallyChecksForUpdates = sender.mm_isOn;
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return @"通用";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:@"toolbar_general"];
}

- (BOOL)hasResizableWidth {
    return NO;
}

- (BOOL)hasResizableHeight {
    return NO;
}

@end
