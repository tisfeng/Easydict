//
//  EZPreferencesWindowController.m
//  Easydict
//
//  Created by tisfeng on 2022/12/15.
//  Copyright © 2022 izual. All rights reserved.
//

#import <MASPreferences/MASPreferences.h>

NS_ASSUME_NONNULL_BEGIN


@interface EZPreferencesWindowController : MASPreferencesWindowController

@property (nonatomic, assign, readonly) BOOL isShowing;

+ (instancetype)shared;

- (void)show;

@end

NS_ASSUME_NONNULL_END
