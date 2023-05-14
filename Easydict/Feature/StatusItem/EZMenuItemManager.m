//
//  EZStatusItem.m
//  Easydict
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZMenuItemManager.h"
#import "EZPreferencesWindowController.h"
#import "EZWindowManager.h"
#import "Snip.h"
#import "EZShortcut.h"
#import <SSZipArchive/SSZipArchive.h>
#import "EZRightClickDetector.h"

@interface EZMenuItemManager () <NSMenuDelegate>

@property (weak) IBOutlet NSMenu *menu;

@property (weak) IBOutlet NSMenuItem *versionItem;
@property (weak) IBOutlet NSMenuItem *selectionItem;
@property (weak) IBOutlet NSMenuItem *snipItem;
@property (weak) IBOutlet NSMenuItem *inputItem;
@property (weak) IBOutlet NSMenuItem *showMiniItem;
@property (weak) IBOutlet NSMenuItem *screenshotOCRItem;

@property (weak) IBOutlet NSMenuItem *preferencesItem;
@property (weak) IBOutlet NSMenuItem *checkForUpdateItem;
@property (weak) IBOutlet NSMenuItem *helpItem;
@property (weak) IBOutlet NSMenuItem *quitItem;

@property (copy) NSString *version;

@end


@implementation EZMenuItemManager

static EZMenuItemManager *_instance;
+ (instancetype)shared {
    if (!_instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[self alloc] init];
        });
    }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (void)setup {
    if (self.statusItem) {
        return;
    }
    
    NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [statusItem setMenu:self.menu];
    self.menu.minimumWidth = 185;
    self.statusItem = statusItem;
    
    NSStatusBarButton *button = statusItem.button;
    
#if DEBUG
    NSImage *image = [NSImage imageNamed:@"status_icon_debug"];
#else
    NSImage *image = [NSImage imageNamed:@"status_icon"];
#endif
    
    [button setImage:image];
    [button setImageScaling:NSImageScaleProportionallyUpOrDown];
    [button setToolTip:@"Easydict 🍃"];
    image.template = YES;
    
    self.version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *versionTitle = [NSString stringWithFormat:@"Easydict  %@", self.version];
    self.versionItem.title = versionTitle;
    
    NSArray *items = @[self.versionItem, self.preferencesItem, self.checkForUpdateItem, self.helpItem, self.quitItem];
    [self increaseMenuItemsHeight:items lineHeightRatio:1.2];
}

- (void)testRightClick {
    NSStatusBarButton *button = self.statusItem.button;
    
    button.action = @selector(leftClickAction:);
    
    EZRightClickDetector *rightClickDetector = [[EZRightClickDetector alloc] initWithFrame:button.frame];
    rightClickDetector.onRightMouseClicked = ^(NSEvent *event){
        NSLog(@"onRightMouseClicked");
        //        [self.statusItem setMenu:self.menu];
        
        //        [button performClick:nil];
    };
    [button addSubview:rightClickDetector];
    
    
    // Add right click functionality
    //    NSClickGestureRecognizer *gesture = [[NSClickGestureRecognizer alloc] init];
    //    gesture.buttonMask = 1; // right mouse
    //    gesture.target = self;
    //    gesture.action = @selector(rightClickAction:);
    //    [button addGestureRecognizer:gesture];
}

- (void)rightClickAction:(NSGestureRecognizer *)sender {
    //    NSButton *button = (NSButton *)sender.view;
    
    // Handle your right click event here
    
    NSLog(@"right click");
}

- (void)leftClickAction:(id)sender {
    NSLog(@"left click");
}


- (void)remove {
    if (self.statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
        self.statusItem = nil;
    }
}

#pragma mark - Status bar action

- (IBAction)versionAction:(NSMenuItem *)sender {
    NSString *versionURL = [NSString stringWithFormat:@"%@/releases/tag/%@", EZRepoGithubURL, self.version];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:versionURL]];
}

- (IBAction)translateAction:(NSMenuItem *)sender {
    NSLog(@"select text translate");
    [EZWindowManager.shared selectTextTranslate];
}

- (IBAction)snipAction:(NSMenuItem *)sender {
    NSLog(@"screenshot translate");
    [EZWindowManager.shared snipTranslate];
}

- (IBAction)inputTranslate:(NSMenuItem *)sender {
    NSLog(@"input translate");
    [EZWindowManager.shared inputTranslate];
}

- (IBAction)showMiniFloatingWindow:(NSMenuItem *)sender {
    NSLog(@"show mini windown");
    [EZWindowManager.shared showMiniFloatingWindow];
}

- (IBAction)screenshotOCRAction:(NSMenuItem *)sender {
    NSLog(@"screenshot OCR");
    [EZWindowManager.shared screenshotOCR];
}


- (IBAction)preferenceAction:(NSMenuItem *)sender {
    NSLog(@"偏好设置");
    if (Snip.shared.isSnapshotting) {
        [Snip.shared stop];
    }
    [EZPreferencesWindowController.shared show];
}

- (IBAction)feedbackAction:(NSMenuItem *)sender {
    NSLog(@"反馈问题");
    NSString *issueURL = [NSString stringWithFormat:@"%@/issues", EZRepoGithubURL];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:issueURL]];
}

- (IBAction)exportLogAction:(id)sender {
    NSLog(@"导出日志");
    NSString *logPath = [MMManagerForLog rootLogDirectory];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH-mm-ss-SSS"];
    NSString *dataString = [dateFormatter stringFromDate:[NSDate date]];
    NSString *downloadDirectory = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES).firstObject;
    NSString *zipPath = [downloadDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Easydict log %@.zip", dataString]];
    BOOL result = [SSZipArchive createZipFileAtPath:zipPath withContentsOfDirectory:logPath keepParentDirectory:NO];
    if (result) {
        [[NSWorkspace sharedWorkspace] selectFile:zipPath inFileViewerRootedAtPath:@""];
    } else {
        MMLogInfo(@"导出日志失败");
    }
}

- (IBAction)quitAction:(NSMenuItem *)sender {
    NSLog(@"退出应用");
    [NSApplication.sharedApplication terminate:nil];
}

#pragma mark - Shortcut

- (IBAction)clearInputAction:(NSMenuItem *)sender {
    [EZWindowManager.shared clearInput];
}

- (IBAction)clearAllAction:(NSMenuItem *)sender {
    [EZWindowManager.shared clearAll];
}

- (IBAction)copyQueryTextAction:(NSMenuItem *)sender {
    [EZWindowManager.shared copyQueryText];
}

- (IBAction)pinAction:(NSMenuItem *)sender {
    [EZWindowManager.shared pin];
}

- (IBAction)translateRetryAction:(NSMenuItem *)sender {
    [EZWindowManager.shared rerty];
}

- (IBAction)closeWindowAction:(NSMenuItem *)sender {
    [EZWindowManager.shared closeWindowOrExitSreenshot];
}

- (IBAction)toggleTranslationLanguagesAction:(NSMenuItem *)sender {
    [EZWindowManager.shared toggleTranslationLanguages];
}

- (IBAction)focusInputAction:(NSMenuItem *)sender {
    [EZWindowManager.shared focusInputTextView];
}

- (IBAction)playSoundAction:(NSMenuItem *)sender {
    [EZWindowManager.shared playQueryTextSound];
}

- (IBAction)googleAction:(NSMenuItem *)sender {
    EZBaseQueryWindow *window = EZWindowManager.shared.floatingWindow;
    [window.titleBar.googleButton openLink];
}

- (IBAction)eudicAction:(NSMenuItem *)sender {
    EZBaseQueryWindow *window = EZWindowManager.shared.floatingWindow;
    [window.titleBar.eudicButton openLink];
}

#pragma mark - NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu {
    void (^configItemShortcut)(NSMenuItem *item, NSString *key) = ^(NSMenuItem *item, NSString *key) {
        @try {
            [EZShortcut readShortcutForKey:key completion:^(MASShortcut *_Nullable shorcut) {
                if (shorcut) {
                    item.keyEquivalent = shorcut.keyCodeStringForKeyEquivalent;
                    item.keyEquivalentModifierMask = shorcut.modifierFlags;
                } else {
                    item.keyEquivalent = @"";
                    item.keyEquivalentModifierMask = 0;
                }
            }];
        } @catch (NSException *exception) {
            item.keyEquivalent = @"";
            item.keyEquivalentModifierMask = 0;
        }
        
        [self increaseMenuItemHeight:item lineHeightRatio:1.3];
    };
    
    configItemShortcut(self.selectionItem, EZSelectionShortcutKey);
    configItemShortcut(self.snipItem, EZSnipShortcutKey);
    configItemShortcut(self.inputItem, EZInputShortcutKey);
    configItemShortcut(self.showMiniItem, EZShowMiniShortcutKey);
    configItemShortcut(self.screenshotOCRItem, EZScreenshotOCRShortcutKey);
}

#pragma mark -

/// Increase menu item height. Ref: https://stackoverflow.com/questions/18031666/nsmenuitem-height
- (void)increaseMenuItemHeight:(NSMenuItem *)item lineHeightRatio:(CGFloat)lineHeightRatio {
    NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    CGFloat fontLineHeight = (font.ascender + fabs(font.descender));
    CGFloat lineHeight = fontLineHeight * lineHeightRatio;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.minimumLineHeight = lineHeight;
    style.maximumLineHeight = lineHeight;
    CGFloat baselineOffset = (lineHeight - fontLineHeight) / 2;
    
    item.attributedTitle = [[NSAttributedString alloc] initWithString:item.title attributes:@{
        NSParagraphStyleAttributeName: style,
        NSBaselineOffsetAttributeName: @(baselineOffset)
    }];
}

- (void)increaseMenuItemsHeight:(NSArray<NSMenuItem *> *)itmes lineHeightRatio:(CGFloat)lineHeightRatio {
    for (NSMenuItem *item in itmes) {
        [self increaseMenuItemHeight:item lineHeightRatio:lineHeightRatio];
    }
}

@end
