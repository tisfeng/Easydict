//
//  StatusItem.m
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "StatusItem.h"
#import "PreferencesWindowController.h"
#import "TranslateWindowController.h"
#import "Snip.h"
#import "Shortcut.h"
#import "Configuration.h"
#import <SSZipArchive/SSZipArchive.h>

@interface StatusItem ()<NSMenuDelegate>

@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *bobItem;
@property (nonatomic, weak) IBOutlet NSMenuItem *selectionItem;
@property (nonatomic, weak) IBOutlet NSMenuItem *snipItem;
@property (weak) IBOutlet NSMenuItem *inputItem;

@end

@implementation StatusItem

static StatusItem *_instance;
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
    if (self.statusItem) return;

    NSStatusItem *item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [item.button setToolTip:@"Bob"];
#if DEBUG
    NSImage *image = [NSImage imageNamed:@"logo_status_debug"];
#else
    NSImage *image = [NSImage imageNamed:@"logo_status"];
#endif
    image.template = YES;
    [item.button setImage:image];
    [item.button setImageScaling:NSImageScaleProportionallyUpOrDown];
    [item setMenu:self.menu];
    self.statusItem = item;
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.bobItem.title = [NSString stringWithFormat:@"Bob %@", version];
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
    [TranslateWindowController.shared selectionTranslate];
}

- (IBAction)snipAction:(NSMenuItem *)sender {
    NSLog(@"截图翻译");
    [TranslateWindowController.shared snipTranslate];
}

- (IBAction)inputTranslate:(NSMenuItem *)sender {
    NSLog(@"输入翻译");
    [TranslateWindowController.shared inputTranslate];
}

- (IBAction)baiduTranslationWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://fanyi.baidu.com/"]];
}

- (IBAction)youdaoTranslationWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://fanyi.youdao.com/"]];
}

- (IBAction)youdaoDictWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://dict.youdao.com/"]];
}

- (IBAction)googleCNTranslationWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://translate.google.cn/"]];
}

- (IBAction)googleTranslationWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://translate.google.com/"]];
}

- (IBAction)preferenceAction:(NSMenuItem *)sender {
    NSLog(@"偏好设置");
    if (Snip.shared.isSnapshotting) {
        [Snip.shared stop];
    }
    if (!Configuration.shared.isPin) {
        [TranslateWindowController.shared close];
    }
    [PreferencesWindowController.shared show];
}

- (IBAction)documentationAction:(NSMenuItem *)sender {
    NSLog(@"使用教程");
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/ripperhe/Bob"]];
}

- (IBAction)exportLogAction:(id)sender {
    NSLog(@"导出日志");
    NSString *logPath = [MMManagerForLog rootLogDirectory];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH-mm-ss-SSS"];
    NSString *dataString = [dateFormatter stringFromDate:[NSDate date]];
    NSString *downloadDirectory = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES).firstObject;
    NSString *zipPath = [downloadDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Bob log %@.zip", dataString]];
    BOOL result = [SSZipArchive createZipFileAtPath:zipPath withContentsOfDirectory:logPath keepParentDirectory:NO];
    if (result) {
        [[NSWorkspace sharedWorkspace] selectFile:zipPath inFileViewerRootedAtPath:@""];
    }else {
        MMLogInfo(@"导出日志失败");
    }
}

- (IBAction)quitAction:(NSMenuItem *)sender {
    NSLog(@"退出应用");
    [NSApplication.sharedApplication terminate:nil];
}

#pragma mark -

- (IBAction)translateRetryAction:(NSMenuItem *)sender {
    NSLog(@"翻译重试");
    [TranslateWindowController.shared rerty];
}

- (IBAction)closeWindowAction:(NSMenuItem *)sender {
    NSLog(@"关闭 Window");
    if (Snip.shared.isSnapshotting) {
        [Snip.shared stop];
    }else {
        [[[NSApplication sharedApplication] keyWindow] close];
        [TranslateWindowController.shared activeLastFrontmostApplication];
    }
}

- (IBAction)qqGroupAction:(id)sender {
    NSLog(@"QQ 群");
    [NSPasteboard mm_generalPasteboardSetString:@"971584165"];
}

#pragma mark -

- (void)menuWillOpen:(NSMenu *)menu {
    void(^configItemShortcut)(NSMenuItem *item, NSString *key) = ^(NSMenuItem *item, NSString *key) {
        @try {
            [Shortcut readShortcutForKey:key completion:^(MASShortcut * _Nullable shorcut) {
                if (shorcut) {
                    item.keyEquivalent = shorcut.keyCodeStringForKeyEquivalent;
                    item.keyEquivalentModifierMask = shorcut.modifierFlags;
                }else {
                    item.keyEquivalent = @"";
                    item.keyEquivalentModifierMask = 0;
                }
            }];
        } @catch (NSException *exception) {
            item.keyEquivalent = @"";
            item.keyEquivalentModifierMask = 0;
        }
    };
    
    configItemShortcut(self.selectionItem, SelectionShortcutKey);
    configItemShortcut(self.snipItem, SnipShortcutKey);
    configItemShortcut(self.inputItem, InputShortcutKey);
}

@end
