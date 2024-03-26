//
//  EZShortcut.h
//  Easydict
//
//  Created by tisfeng on 2022/11/27.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MASShortcut/Shortcut.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZSelectionShortcutKey = @"EZSelectionShortcutKey";
static NSString *const EZSnipShortcutKey = @"EZSnipShortcutKey";
static NSString *const EZInputShortcutKey = @"EZInputShortcutKey";
static NSString *const EZShowMiniShortcutKey = @"EZShowMiniShortcutKey";
static NSString *const EZScreenshotOCRShortcutKey = @"EZScreenshotOCRShortcutKey";

@interface EZShortcut : NSObject

+ (void)setup;

+ (void)readShortcutForKey:(NSString *)key completion:(void (^NS_NOESCAPE)(MASShortcut *_Nullable shorcut))completion;

@end

NS_ASSUME_NONNULL_END
