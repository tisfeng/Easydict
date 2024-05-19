//
//  EZStatusItem.m
//  Easydict
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZMenuItemManager.h"
#import "EZWindowManager.h"
#import "Snip.h"
#import <ZipArchive.h>
#import "EZRightClickDetector.h"
#import "EZConfiguration.h"
#import <Sparkle/SPUStandardUpdaterController.h>
#import <Sparkle/SPUUpdater.h>

@interface EZMenuItemManager () <NSMenuDelegate>

@property (weak) IBOutlet NSMenu *menu;

@property (weak) IBOutlet NSMenuItem *versionItem;
@property (weak) IBOutlet NSMenuItem *selectionItem;
@property (weak) IBOutlet NSMenuItem *snipItem;
@property (weak) IBOutlet NSMenuItem *inputItem;
@property (weak) IBOutlet NSMenuItem *showMiniItem;
@property (weak) IBOutlet NSMenuItem *screenshotOCRItem;
@property (weak) IBOutlet NSMenuItem *settingsItem;
@property (weak) IBOutlet NSMenuItem *checkForUpdateItem;
@property (weak) IBOutlet NSMenuItem *helpItem;
@property (weak) IBOutlet NSMenuItem *quitItem;

@property (copy) NSString *appVersion;
@property (nonatomic, copy) NSString *versionTitle;

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

- (NSString *)versionTitle {
    if (!_versionTitle) {
        _versionTitle = [NSString stringWithFormat:@"Easydict  %@", self.appVersion];
    }
    return _versionTitle;
}


- (void)setup {
    if (self.statusItem) {
        return;
    }
    if (Configuration.shared.hideMenuBarIcon) {
        return;
    }
    
    NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [statusItem setMenu:self.menu];
    self.statusItem = statusItem;
    
    NSStatusBarButton *button = statusItem.button;
    
#if DEBUG
    NSImage *image = [NSImage imageNamed:@"rounded_menu_bar_icon"];
#else
    NSImage *image = [NSImage imageNamed:@"square_menu_bar_icon"];
#endif
    
    [button setImage:image];
    [button setImageScaling:NSImageScaleProportionallyUpOrDown];
    [button setToolTip:@"Easydict 🍃"];
    image.template = YES;
    
    self.appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.versionItem.title = self.versionTitle;
        
    [self updateVersionItem];
}

- (void)testRightClick {
    NSStatusBarButton *button = self.statusItem.button;
    
    button.action = @selector(leftClickAction:);
    
    EZRightClickDetector *rightClickDetector = [[EZRightClickDetector alloc] initWithFrame:button.frame];
    rightClickDetector.onRightMouseClicked = ^(NSEvent *event){
        MMLogInfo(@"onRightMouseClicked");
//        [self.statusItem setMenu:self.menu];
//
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
    
    MMLogInfo(@"right click");
}

- (void)leftClickAction:(id)sender {
    MMLogInfo(@"left click");
}


- (void)remove {
    if (self.statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
        self.statusItem = nil;
    }
}

#pragma mark - Status bar action

- (IBAction)versionAction:(NSMenuItem *)sender {
    NSString *versionURL = [NSString stringWithFormat:@"%@/releases", EZGithubRepoEasydictURL];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:versionURL]];
}

- (IBAction)translateAction:(NSMenuItem *)sender {
    MMLogInfo(@"select text translate");
    [EZWindowManager.shared selectTextTranslate];
}

- (IBAction)snipAction:(NSMenuItem *)sender {
    MMLogInfo(@"screenshot translate");
    [EZWindowManager.shared snipTranslate];
}

- (IBAction)inputTranslate:(NSMenuItem *)sender {
    MMLogInfo(@"input translate");
    [EZWindowManager.shared inputTranslate];
}

- (IBAction)showMiniFloatingWindow:(NSMenuItem *)sender {
    MMLogInfo(@"show mini windown");
    [EZWindowManager.shared showMiniFloatingWindow];
}

- (IBAction)screenshotOCRAction:(NSMenuItem *)sender {
    MMLogInfo(@"screenshot OCR");
    [EZWindowManager.shared screenshotOCR];
}


- (IBAction)settingAction:(NSMenuItem *)sender {
    MMLogInfo(@"设置...");
    if (Snip.shared.isSnapshotting) {
        [Snip.shared stop];
    }
    // TODO: Sharker remove EZPreferencesWindowController
//    [EZPreferencesWindowController.shared show];
}

- (IBAction)checkForUpdateItem:(id)sender {
    MMLogInfo(@"checkForUpdate");
    [EZConfiguration.shared.updater checkForUpdates];
}

- (IBAction)feedbackAction:(NSMenuItem *)sender {
    MMLogInfo(@"反馈问题");
    NSString *issueURL = [NSString stringWithFormat:@"%@/issues", EZGithubRepoEasydictURL];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:issueURL]];
}

- (IBAction)exportLogAction:(id)sender {
    MMLogInfo(@"导出日志");
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
        MMLogError(@"导出日志失败");
    }
}

- (IBAction)logLogDirectorAction:(NSMenuItem *)sender {
    NSString *logPath = [MMManagerForLog rootLogDirectory];
    NSURL *directoryURL = [NSURL fileURLWithPath:logPath];
    [[NSWorkspace sharedWorkspace] openURL:directoryURL];
}

- (IBAction)quitAction:(NSMenuItem *)sender {
    MMLogInfo(@"退出应用");
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

- (IBAction)copyFirstTranslatedTextAction:(NSMenuItem *)sender {
    [EZWindowManager.shared copyFirstTranslatedText];
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
    [EZWindowManager.shared playOrStopQueryTextAudio];
}

- (IBAction)googleAction:(NSMenuItem *)sender {
    EZBaseQueryWindow *window = EZWindowManager.shared.floatingWindow;
    [window.titleBar.googleButton openLink];
}

- (IBAction)eudicAction:(NSMenuItem *)sender {
    EZBaseQueryWindow *window = EZWindowManager.shared.floatingWindow;
    [window.titleBar.eudicButton openLink];
}

// apple diction action
- (IBAction)appleDictionaryAction:(NSMenuItem *)sender {
    EZBaseQueryWindow *window = EZWindowManager.shared.floatingWindow;
    [window.titleBar.appleDictionaryButton openLink];
}

- (IBAction)increaseFontSizeAction:(NSMenuItem *)sender {
    Configuration.shared.fontSizeIndex += 1;
    
}

- (IBAction)decreaseFontSizeAction:(NSMenuItem *)sender {
    Configuration.shared.fontSizeIndex -= 1;
    
}

#pragma mark - Fetch Github Repo Info

- (void)updateVersionItem {
    [self fetchRepoLatestVersion:EZGithubRepoEasydict completion:^(NSString *lastestVersion) {
        BOOL hasNewVersion = [self.appVersion compare:lastestVersion options:NSNumericSearch] == NSOrderedAscending;
        NSString *versionTitle = self.versionTitle;
        if (hasNewVersion) {
            versionTitle = [NSString stringWithFormat:@"%@  (✨ %@)", self.versionTitle, lastestVersion];
        }
        self.versionItem.title = versionTitle;
    }];
}

- (void)fetchRepoLatestVersion:(NSString *)repo completion:(void (^)(NSString *latestVersion))completion {
    [self fetchRepoLatestRepoInfo:repo completion:^(NSDictionary *lastestVersionDict) {
        NSString *latestVersion = lastestVersionDict[@"tag_name"];
        completion(latestVersion);
    }];
}

- (void)fetchRepoLatestRepoInfo:(NSString *)repo completion:(void (^)(NSDictionary *latestVersionDict))completion {
    NSString *urlString = [NSString stringWithFormat:@"https://api.github.com/repos/%@/releases/latest", repo];
    NSURL *URL = [NSURL URLWithString:urlString];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *dict = responseObject;
        completion(dict);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        MMLogError(@"Error: %@", error);
    }];
}

@end
