//
//  NSObject+EZDarkMode.h
//  Easydict
//
//  Created by tisfeng on 2022/12/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^EZAppearanceChangeHandler)(id owner, BOOL isDarkMode);

@interface NSObject (EZDarkMode)

@property (nonatomic, readonly) BOOL isDarkMode;

/// Executes the handler immediately and on future appearance changes.
/// The block receives the current owner and whether the effective appearance is dark mode.
- (void)executeOnAppearanceChange:(nullable EZAppearanceChangeHandler)handler;

@end

NS_ASSUME_NONNULL_END
