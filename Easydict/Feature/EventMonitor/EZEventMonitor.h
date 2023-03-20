//
//  EZSelectTextEvent.h
//  Easydict
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZEventMonitor : NSObject

@property (nonatomic, copy) void (^selectedTextBlock)(NSString *selectedText);
@property (nonatomic, copy) void (^dismissPopButtonBlock)(void);
@property (nonatomic, copy) void (^dismissMiniWindowBlock)(void);
@property (nonatomic, copy) void (^dismissFixedWindowBlock)(void);
@property (nonatomic, copy) void (^doubleCommandBlock)(void);

@property (nonatomic, assign) CGRect selectedTextFrame;
@property (nonatomic, assign) CGPoint startPoint; // ⚠️ this may not selected text start point!
@property (nonatomic, assign) CGPoint endPoint;
@property (nonatomic, assign) BOOL isSelectedTextByAuxiliary;

@property (nonatomic, assign) NSEventMask mask;
@property (nonatomic, copy) void (^handler)(NSEvent *event);

/// Use auxiliary to get selected text first, if failed, use shortcut.
- (void)getSelectedText:(void (^)(NSString *_Nullable text))completion;

- (void)addLocalMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler;
- (void)addGlobalMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler;
- (void)bothMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler;

- (void)start;

- (void)stop;

- (void)startMonitor;

- (BOOL)isAccessibilityTrusted;

@end

NS_ASSUME_NONNULL_END
