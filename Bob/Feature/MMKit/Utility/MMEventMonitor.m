//
//  MMEventMonitor.m
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "MMEventMonitor.h"

typedef NS_ENUM(NSUInteger, MMEventMonitorType) {
    MMEventMonitorTypeLocal,
    MMEventMonitorTypeGlobal,
    MMEventMonitorTypeBoth,
};

@interface MMEventMonitor ()

@property (nonatomic, assign) MMEventMonitorType type;
@property (nonatomic, strong) id localMonitor;
@property (nonatomic, strong) id globalMonitor;

@end

@implementation MMEventMonitor

+ (instancetype)monitorWithType:(MMEventMonitorType)type event:(NSEventMask)mask handler:(void (^)(NSEvent * _Nonnull))handler {
    MMEventMonitor *monitor = [self new];
    monitor.type = type;
    monitor.mask = mask;
    monitor.handler = handler;
    return monitor;
}

+ (instancetype)localMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent * _Nonnull))handler {
    return [self monitorWithType:MMEventMonitorTypeLocal event:mask handler:handler];
}

+ (instancetype)globalMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent * _Nonnull))handler {
    return [self monitorWithType:MMEventMonitorTypeGlobal event:mask handler:handler];
}

+ (instancetype)bothMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent * _Nonnull))handler {
    return [self monitorWithType:MMEventMonitorTypeBoth event:mask handler:handler];
}

- (void)start {
    [self stop];
    if (self.type == MMEventMonitorTypeLocal) {
        mm_weakify(self)
        self.localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:self.mask handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
            mm_strongify(self);
            self.handler(event);
            return event;
        }];
    }else if(self.type == MMEventMonitorTypeGlobal) {
        self.globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:self.mask handler:self.handler];
    }else {
        mm_weakify(self)
        self.localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:self.mask handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
            mm_strongify(self);
            self.handler(event);
            return event;
        }];
        self.globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:self.mask handler:self.handler];
    }
}

- (void)stop {
    if (self.localMonitor) {
        [NSEvent removeMonitor:self.localMonitor];
        self.localMonitor = nil;
    }
    if (self.globalMonitor) {
        [NSEvent removeMonitor:self.globalMonitor];
        self.globalMonitor = nil;
    }
}

@end
