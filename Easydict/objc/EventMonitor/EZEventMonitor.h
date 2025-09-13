//
//  EZSelectTextEvent.h
//  Easydict
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZEnumTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZEventMonitor : NSObject

@property (nonatomic, copy) NSString *selectedText;
@property (nonatomic, copy) EZActionType actionType;
@property (nonatomic, copy) EZSelectTextType selectTextType;
@property (nonatomic, assign) EZTriggerType triggerType;

@property (nonatomic, strong, nullable) NSRunningApplication *frontmostApplication;
@property (nonatomic, copy, nullable) NSString *browserTabURLString;

@property (nonatomic, assign) CGPoint startPoint; // ⚠️ this may not selected text start point!
@property (nonatomic, assign) CGPoint endPoint;

@property (nonatomic, assign, getter=isSelectedTextEditable) BOOL selectedTextEditable;

@property (nonatomic, copy) void (^selectedTextBlock)(NSString *selectedText);
@property (nonatomic, copy) void (^dismissPopButtonBlock)(void);
@property (nonatomic, copy) void (^dismissAllNotPinndFloatingWindowBlock)(void);
@property (nonatomic, copy) void (^doubleCommandBlock)(void);
@property (nonatomic, copy) void (^leftMouseDownBlock)(CGPoint clickPoint);
@property (nonatomic, copy) void (^rightMouseDownBlock)(CGPoint clickPoint);

+ (instancetype)shared;

- (void)getSelectedTextWithCompletion:(void (^)(NSString *_Nullable text))completion NS_SWIFT_ASYNC_NAME(getSelectedText());

- (void)addLocalMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler;
- (void)addGlobalMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler;
- (void)bothMonitorWithEvent:(NSEventMask)mask handler:(void (^)(NSEvent *_Nonnull))handler;
- (void)addGlobalMonitor:(BOOL)isAutoSelectTextEnabled;

- (void)start;
- (void)stop;
- (void)startMonitor;
- (BOOL)isAccessibilityEnabled;

- (void)updateSelectedTextEditableState;

@end

NS_ASSUME_NONNULL_END
