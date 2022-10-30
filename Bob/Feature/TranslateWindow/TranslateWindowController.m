//
//  TranslateWindowController.m
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "TranslateWindowController.h"
#import "TranslateViewController.h"
#import "TranslateWindow.h"
#import "Selection.h"
#import "Snip.h"
#import "Configuration.h"
#import <QuartzCore/QuartzCore.h>
#import <Carbon/Carbon.h>

@interface TranslateWindowController ()

@property (nonatomic, weak) TranslateViewController *viewController;
@property (nonatomic, assign) BOOL hadShow;
@property (nonatomic, strong) NSRunningApplication *lastFrontmostApplication;

@end

@implementation TranslateWindowController

static TranslateWindowController *_instance;
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

- (instancetype)init {
    self = [super init];
    if (self) {
        TranslateWindow *window = [TranslateWindow new];
        TranslateViewController *viewController = [TranslateViewController new];
        viewController.window = window;
        window.contentViewController = viewController;
        self.window = window;
        self.viewController = viewController;
    }
    return self;
}

#pragma mark -

- (void)showAtMouseLocation {
    self.hadShow = YES;
    NSPoint mouseLocation = [NSEvent mouseLocation];
    // 找到鼠标所在屏幕
    NSScreen *screen = [NSScreen.screens mm_find:^id(NSScreen * _Nonnull obj, NSUInteger idx) {
        return NSPointInRect(mouseLocation, obj.frame) ? obj : nil;
    }];
    // 找不到屏幕；可能在边缘，放宽条件
    if (!screen) {
        screen = [NSScreen.screens mm_find:^id _Nullable(NSScreen * _Nonnull obj, NSUInteger idx) {
            return MMPointInRect(mouseLocation, obj.frame) ? obj : nil;
        }];
    }
    if (!screen) return;
    
    // 修正显示位置，用于保证window显示在鼠标所在的screen
    // 如果直接使用mouseLocation，可能会显示到其他screen（应该是由当前window在哪个屏幕的区域更多决定的）
    NSRect windowFrame = self.window.frame;
    NSRect visibleFrame = screen.visibleFrame;
    
    if (mouseLocation.x < visibleFrame.origin.x + 10) {
        mouseLocation.x = visibleFrame.origin.x + 10;
    }
    if (mouseLocation.y < visibleFrame.origin.y + windowFrame.size.height + 10) {
        mouseLocation.y = visibleFrame.origin.y + windowFrame.size.height + 10;
    }
    if (mouseLocation.x > visibleFrame.origin.x + visibleFrame.size.width - windowFrame.size.width - 10) {
        mouseLocation.x = visibleFrame.origin.x + visibleFrame.size.width - windowFrame.size.width - 10;
    }
    if (mouseLocation.y > visibleFrame.origin.y + visibleFrame.size.height - 10) {
        mouseLocation.y = visibleFrame.origin.y + visibleFrame.size.height - 10;
    }
    
    // https://stackoverflow.com/questions/7460092/nswindow-makekeyandorderfront-makes-window-appear-but-not-key-or-front
    [self.window makeKeyAndOrderFront:nil];
    if (!self.window.isKeyWindow) {
        // fail to make key window, then force activate application for key window
        [NSApp activateIgnoringOtherApps:YES];
    }
    [self.window setFrameTopLeftPoint:mouseLocation];
}

- (void)ensureShowAtMouseLocation {
    if (!self.hadShow) {
        [self showAtMouseLocation];
    }
    if (!self.window.visible || !Configuration.shared.isPin) {
        [self showAtMouseLocation];
    }
}

- (void)saveFrontmostApplication {
    NSString *identifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSRunningApplication *frontmostApplication = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if ([frontmostApplication.bundleIdentifier isEqualToString:identifier]) {
        return;
    }
    
    self.lastFrontmostApplication = frontmostApplication;
}

#pragma mark -

- (void)selectionTranslate {
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    [self.viewController resetWithState:@"正在取词..."];
    [Selection getText:^(NSString * _Nullable text) {
        [self ensureShowAtMouseLocation];
        if (text.length) {
            [self.viewController translateText:text];
        }else {
            [self.viewController resetWithState:@"划词翻译没有获取到文本" actionTitle:@"可能的原因 →" action:^{
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/ripperhe/Bob#%E5%88%92%E8%AF%8D%E7%BF%BB%E8%AF%91%E8%8E%B7%E5%8F%96%E4%B8%8D%E5%88%B0%E6%96%87%E6%9C%AC"]];
            }];
            [self.viewController resetQueryViewHeightConstraint];
        }
    }];
}

- (void)snipTranslate {
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    if (!Configuration.shared.isPin && self.window.visible) {
        [self close];
        [CATransaction flush];
    }
    [self.viewController resetWithState:@"正在截图..."];
    [Snip.shared startWithCompletion:^(NSImage * _Nullable image) {
        NSLog(@"获取到图片 %@", image);
        // 缓存最后一张图片，统一放到 MMLogs 文件夹，方便管理
        static NSString *_imagePath = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _imagePath = [[MMManagerForLog logDirectoryWithName:@"Image"] stringByAppendingPathComponent:@"snip_image.png"];
        });
        [[NSFileManager defaultManager] removeItemAtPath:_imagePath error:nil];
        if (image) {
            [image mm_writeToFileAsPNG:_imagePath];
            NSLog(@"已保存图片\n%@", _imagePath);
            [self ensureShowAtMouseLocation];
            [self.viewController translateImage:image];
        }
    }];
}

- (void)inputTranslate {
    [self saveFrontmostApplication];
    if (Snip.shared.isSnapshotting) {
        return;
    }
    Configuration.shared.isFold = NO;
    [self.viewController updateFoldState:NO];
    [self.viewController resetWithState:@"↩︎ 翻译\n⇧ + ↩︎ 换行\n⌘ + R 重试\n⌘ + W 关闭"];
    [self ensureShowAtMouseLocation];
    [self.window makeKeyAndOrderFront:nil];
    if (!self.window.isKeyWindow) {
        // fail to make key window, then force activate application for key window
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (void)rerty {
    if (Snip.shared.isSnapshotting) {
        return;
    }
    if ([[NSApplication sharedApplication] keyWindow] == TranslateWindowController.shared.window) {
        // 执行重试
        [self.viewController retry];
    }
}

- (void)activeLastFrontmostApplication {
    if (!self.lastFrontmostApplication.terminated) {
        [self.lastFrontmostApplication activateWithOptions:NSApplicationActivateAllWindows];
    }
    self.lastFrontmostApplication = nil;
}

@end
