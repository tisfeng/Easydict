//
//  EZSelectTextEvent.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZEventMonitor : NSObject

@property (nonatomic, copy) void (^selectedTextBlock)(NSString *selectedText);
@property (nonatomic, copy) void (^dismissPopButtonBlock)(void);


@property (nonatomic, assign) NSEventMask mask;
@property (nonatomic, copy) void (^handler)(NSEvent *event);

- (void)getSelectedText:(void (^)(NSString *_Nullable text, AXError error))completion;

- (void)getText:(void (^)(NSString *_Nullable text))completion;


- (void)addLocalMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler;
- (void)addGlobalMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler;
- (void)bothMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler;

- (void)start;

- (void)stop;

- (void)startMonitor;

- (BOOL)checkAppIsTrusted;


@end

NS_ASSUME_NONNULL_END
