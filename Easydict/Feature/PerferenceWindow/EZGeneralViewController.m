//
//  EZGeneralViewController.m
//  Easydict
//
//  Created by tisfeng on 2022/12/15.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZGeneralViewController.h"
#import "EZShortcut.h"
#import "EZConfiguration.h"


@interface EZGeneralViewController ()

@property (weak) IBOutlet MASShortcutView *selectionShortcutView;
@property (weak) IBOutlet MASShortcutView *snipShortcutView;
@property (weak) IBOutlet MASShortcutView *inputShortcutView;
@property (weak) IBOutlet MASShortcutView *showMiniShortcutView;

@property (weak) IBOutlet NSButton *autoCopyTranslateResultButton;
@property (weak) IBOutlet NSButton *launchAtStartupButton;
@property (weak) IBOutlet NSButton *autoCheckUpdateButton;

@end


@implementation EZGeneralViewController

- (instancetype)init {
    return [super initWithNibName:[self className] bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

    self.selectionShortcutView.style = MASShortcutViewStyleTexturedRect;
    [self.selectionShortcutView setAssociatedUserDefaultsKey:EZSelectionShortcutKey];

    self.snipShortcutView.style = MASShortcutViewStyleTexturedRect;
    [self.snipShortcutView setAssociatedUserDefaultsKey:EZSnipShortcutKey];

    self.inputShortcutView.style = MASShortcutViewStyleTexturedRect;
    [self.inputShortcutView setAssociatedUserDefaultsKey:EZInputShortcutKey];
    
    self.showMiniShortcutView.style = MASShortcutViewStyleTexturedRect;
    [self.showMiniShortcutView setAssociatedUserDefaultsKey:EZShowMiniShortcutKey];

    self.autoCopyTranslateResultButton.mm_isOn = EZConfiguration.shared.autoSelectText;
    self.launchAtStartupButton.mm_isOn = EZConfiguration.shared.launchAtStartup;
    self.autoCheckUpdateButton.mm_isOn = EZConfiguration.shared.automaticallyChecksForUpdates;
}

#pragma mark - event

- (IBAction)autoSelectTextButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.autoSelectText = sender.mm_isOn;
    
    if (sender.mm_isOn) {
        [self checkAppIsTrusted];
    }
}

- (BOOL)checkAppIsTrusted {
    BOOL isTrusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef) @{(__bridge NSString *)kAXTrustedCheckOptionPrompt : @YES});
    NSLog(@"isTrusted: %d", isTrusted);

    return isTrusted == YES;
}

- (IBAction)launchAtStartupButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.launchAtStartup = sender.mm_isOn;
}

- (IBAction)autoCheckUpdateButtonClicked:(NSButton *)sender {
    EZConfiguration.shared.automaticallyChecksForUpdates = sender.mm_isOn;
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return self.className;
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"general", nil);
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
