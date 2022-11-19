//
//  EZFixedWindowController.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZFixedQueryWindowController : NSWindowController

+ (instancetype)shared;

- (void)selectionTranslate;

- (void)snipTranslate;

- (void)inputTranslate;

- (void)showMiniWindow;

- (void)rerty;

- (void)activeLastFrontmostApplication;

@end

NS_ASSUME_NONNULL_END
