//
//  Snip.m
//  Bob
//
//  Created by ripper on 2019/11/27.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "Snip.h"

@interface Snip ()

@property (nonatomic, strong) NSMutableArray<SnipWindowController *> *windowControllers;
@property (nonatomic, copy) void(^completion)(NSImage * _Nullable image);
@property (nonatomic, strong) MMEventMonitor *mouseMoveMonitor;
@property (nonatomic, strong) MMEventMonitor *rightMouseDownMonitor;
@property (nonatomic, weak) SnipWindowController *currentMainWindowController;

@end

@implementation Snip

static Snip *_instance;
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

- (NSMutableArray *)windowControllers {
    if (!_windowControllers) {
        _windowControllers = [NSMutableArray array];
    }
    return _windowControllers;
}

- (MMEventMonitor *)mouseMoveMonitor {
    if (!_mouseMoveMonitor) {
        _mouseMoveMonitor = [MMEventMonitor bothMonitorWithEvent:NSEventMaskMouseMoved handler:^(NSEvent * _Nonnull event) {
            [self mouseMoved:event];
        }];
    }
    return _mouseMoveMonitor;
}

- (MMEventMonitor *)rightMouseDownMonitor {
    if (!_rightMouseDownMonitor) {
        _rightMouseDownMonitor = [MMEventMonitor bothMonitorWithEvent:NSEventMaskRightMouseDown handler:^(NSEvent * _Nonnull event) {
            [self stop];
        }];
    }
    return _rightMouseDownMonitor;
}

#pragma mark -

- (void)startWithCompletion:(void (^)(NSImage * _Nullable))completion {
    if (self.isSnapshotting) {
        if (completion) {
            self.completion = completion;
        }
        return;
    }
    self.isSnapshotting = YES;
    self.completion = completion;
    
    [self.windowControllers makeObjectsPerformSelector:@selector(close)];
    [self.windowControllers removeAllObjects];

    [NSScreen.screens enumerateObjectsUsingBlock:^(NSScreen * _Nonnull screen, NSUInteger idx, BOOL * _Nonnull stop) {
        SnipWindowController *windowController = [SnipWindowController new];
        [windowController setStartBlock:^(SnipWindowController * _Nonnull windowController) {
            NSLog(@"截图开始");
        }];
        [windowController setEndBlock:^(SnipWindowController * _Nonnull windowController, NSImage * _Nullable image) {
            NSLog(@"截图结束：%@", image ? @"成功" : @"失败");
            [self stopWithImage:image];
        }];
        [windowController captureWithScreen:screen];
        [self.windowControllers addObject:windowController];
    }];
    
    [self.mouseMoveMonitor start];
    [self.rightMouseDownMonitor start];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(screenChanged:) name:NSWorkspaceActiveSpaceDidChangeNotification object:[NSWorkspace sharedWorkspace]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenChanged:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    
    [self mouseMoved:nil];
}

- (void)stopWithImage:(NSImage *)image {
    self.isSnapshotting = NO;
    
    [self.mouseMoveMonitor stop];
    [self.rightMouseDownMonitor stop];
    self.mouseMoveMonitor = nil;
    self.rightMouseDownMonitor = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

    [self.windowControllers makeObjectsPerformSelector:@selector(close)];
    [self.windowControllers removeAllObjects];
    
    self.currentMainWindowController = nil;
    
    [CATransaction flush];
    
    // 回调，中断也要回调
    if (self.completion) {
        self.completion(image);
    }
    self.completion = nil;
}

- (void)stop {
    if (!self.isSnapshotting) {
        return;
    }
    [self stopWithImage:nil];
}

#pragma mark -

- (void)mouseMoved:(NSEvent *)event {
    // NSLog(@"鼠标移动 %@", self.currentMainWindowController);
    
    NSPoint mouseLocation = [NSEvent mouseLocation];
    if (!self.currentMainWindowController) {
        [self.windowControllers enumerateObjectsUsingBlock:^(SnipWindowController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (NSPointInRect(mouseLocation, obj.window.frame)) {
                self.currentMainWindowController = obj;
                [obj.window makeMainWindow];
                [obj.window makeKeyWindow];
                [obj.snipViewController showAndUpdateFocusView];
                *stop = YES;
            }
        }];
        return;
    }
    
    if (NSPointInRect(mouseLocation, self.currentMainWindowController.window.frame)) {
        // 在当前的 main window
        [self.currentMainWindowController.snipViewController showAndUpdateFocusView];
    }else {
        // 不在当前 main window
        if (self.currentMainWindowController.snipViewController.isStart) {
            // 如果已经开始拖拽
            [self.currentMainWindowController.snipViewController showAndUpdateFocusView];
        }else {
            // 切换 main window
            SnipWindowController *newMain = [self.windowControllers mm_find:^id(SnipWindowController * _Nonnull obj, NSUInteger idx) {
                return NSPointInRect(mouseLocation, obj.window.frame) ? obj : nil;
            }];
            if (newMain) {
                [self.currentMainWindowController.snipViewController hiddenFocusView];
                self.currentMainWindowController = newMain;
                [newMain.window makeMainWindow];
                [newMain.window makeKeyWindow];
                [newMain.snipViewController showAndUpdateFocusView];
            }else {
                [self.currentMainWindowController.snipViewController showAndUpdateFocusView];
            }
        }
    }
    
    if (!self.currentMainWindowController.window.isMainWindow ||
        !self.currentMainWindowController.window.isKeyWindow) {
        NSLog(@"设置 main window");
        [self.currentMainWindowController.window makeMainWindow];
        [self.currentMainWindowController.window makeKeyWindow];
    }
}

- (void)screenChanged:(NSNotification *)notification {
    NSLog(@"屏幕改变 %@", notification);
    [self stop];
}

@end
