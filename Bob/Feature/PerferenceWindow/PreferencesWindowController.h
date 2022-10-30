//
//  PreferencesWindowController.h
//  Bob
//
//  Created by ripper on 2019/12/9.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <MASPreferences/MASPreferences.h>

NS_ASSUME_NONNULL_BEGIN

@interface PreferencesWindowController : MASPreferencesWindowController

+ (instancetype)shared;

- (void)show;

@end

NS_ASSUME_NONNULL_END
