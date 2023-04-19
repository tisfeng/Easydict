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
#import "EZRightClickDetector.h"

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
    [item setMenu:self.menu];
    self.statusItem = item;
    
    NSStatusBarButton *button = item.button;
    
#if DEBUG
    NSImage *image = [NSImage imageNamed:@"status_icon_debug"];
#else
    NSImage *image = [NSImage imageNamed:@"status_icon"];
#endif
    
    [button setImage:image];
    [button setImageScaling:NSImageScaleProportionallyUpOrDown];
    [button setToolTip:@"Easydict 🍃"];
    image.template = YES;
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.bobItem.title = [NSString stringWithFormat:@"Easydict  %@", version];
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

#pragma mark - Shorcut

- (IBAction)clearInputAction:(NSMenuItem *)sender {
    [EZWindowManager.shared clearInput];
}

- (IBAction)clearAllAction:(NSMenuItem *)sender {
    [EZWindowManager.shared clearAll];
}

- (IBAction)pinAction:(NSMenuItem *)sender {
    [EZWindowManager.shared pin];
}

- (IBAction)translateRetryAction:(NSMenuItem *)sender {
    [EZWindowManager.shared rerty];
}

- (IBAction)closeWindowAction:(NSMenuItem *)sender {
    [EZWindowManager.shared closeWindow];
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
    };
    
    configItemShortcut(self.selectionItem, EZSelectionShortcutKey);
    configItemShortcut(self.snipItem, EZSnipShortcutKey);
    configItemShortcut(self.inputItem, EZInputShortcutKey);
    configItemShortcut(self.showMiniItem, EZShowMiniShortcutKey);
}

- (void)menuDidClose:(NSMenu *)menu {
    
    //    [self.statusItem setMenu:nil];
    
}

@end
