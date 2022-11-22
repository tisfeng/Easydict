//
//  Shortcut.h
//  Bob
//
//  Created by ripper on 2019/12/9.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MASShortcut/Shortcut.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZSelectionShortcutKey = @"EZSelectionShortcutKey";
static NSString *const EZSnipShortcutKey = @"EZSnipShortcutKey";
static NSString *const EZInputShortcutKey = @"EZInputShortcutKey";


@interface Shortcut : NSObject

+ (void)setup;

+ (void)readShortcutForKey:(NSString *)key completion:(void (^NS_NOESCAPE)(MASShortcut *_Nullable shorcut))completion;

@end

NS_ASSUME_NONNULL_END
