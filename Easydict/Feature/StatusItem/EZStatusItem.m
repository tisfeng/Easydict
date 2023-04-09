//
//  EZStatusItem.m
//  Easydict
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZStatusItem.h"
#import "EZPreferencesWindowController.h"
#import "EZWindowManager.h"
#import "Snip.h"
#import "EZShortcut.h"
#import <SSZipArchive/SSZipArchive.h>

@interface EZStatusItem () <NSMenuDelegate>

@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *bobItem;
@property (nonatomic, weak) IBOutlet NSMenuItem *selectionItem;
@property (nonatomic, weak) IBOutlet NSMenuItem *snipItem;
@property (weak) IBOutlet NSMenuItem *inputItem;
@property (weak) IBOutlet NSMenuItem *showMiniItem;

@end


@implementation EZStatusItem

static EZStatusItem *_instance;
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
    
    NSStatusItem *item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [item.button setToolTip:@"Easydict"];
#if DEBUG
    NSImage *image = [NSImage imageNamed:@"status_icon_debug"];
#else
    NSImage *image = [NSImage imageNamed:@"status_icon"];
#endif
    image.template = YES;
    [item.button setImage:image];
    [item.button setImageScaling:NSImageScaleProportionallyUpOrDown];
    [item setMenu:self.menu];
    self.statusItem = item;
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.bobItem.title = [NSString stringWithFormat:@"Easydict  %@", version];
}

- (void)remove {
    if (self.statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
        self.statusItem = nil;
    }
}

#pragma mark -
- (IBAction)translateAction:(NSMenuItem *)sender {
    NSLog(@"划词翻译");
    [EZWindowManager.shared selectTextTranslate];
}

- (IBAction)snipAction:(NSMenuItem *)sender {
    NSLog(@"截图翻译");
    [EZWindowManager.shared snipTranslate];
}

- (IBAction)inputTranslate:(NSMenuItem *)sender {
    NSLog(@"输入翻译");
    [EZWindowManager.shared inputTranslate];
}

- (IBAction)showMiniFloatingWindow:(NSMenuItem *)sender {
    NSLog(@"显示迷你窗口");
    [EZWindowManager.shared showMiniFloatingWindow];
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

#pragma mark -

- (IBAction)clearInputAction:(NSMenuItem *)sender {
    NSLog(@"Clear input");
    
    EZBaseQueryViewController *queryViewController = EZWindowManager.shared.floatingWindow.queryViewController;
    [queryViewController clearInput];
}

- (IBAction)clearAllAction:(NSMenuItem *)sender {
    NSLog(@"Clear All");
    
    EZBaseQueryViewController *queryViewController = EZWindowManager.shared.floatingWindow.queryViewController;
    [queryViewController clearAll];
}

- (IBAction)pinAction:(NSMenuItem *)sender {
    NSLog(@"Pin");
    
    EZBaseQueryWindow *queryWindow = EZWindowManager.shared.floatingWindow;
    queryWindow.titleBar.pin = !queryWindow.titleBar.pin;
}

- (IBAction)translateRetryAction:(NSMenuItem *)sender {
    NSLog(@"Retry");
    [EZWindowManager.shared rerty];
}

- (IBAction)closeWindowAction:(NSMenuItem *)sender {
    NSLog(@"Close window");
    if (Snip.shared.isSnapshotting) {
        [Snip.shared stop];
    } else {
        [EZWindowManager.shared closeFloatingWindow];
        [EZPreferencesWindowController.shared close];
    }
}


#pragma mark -

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
    };
    
    configItemShortcut(self.selectionItem, EZSelectionShortcutKey);
    configItemShortcut(self.snipItem, EZSnipShortcutKey);
    configItemShortcut(self.inputItem, EZInputShortcutKey);
    configItemShortcut(self.showMiniItem, EZShowMiniShortcutKey);
}

@end
