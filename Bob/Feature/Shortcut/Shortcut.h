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

static NSString *const SelectionShortcutKey = @"SelectionShortcutKey";
static NSString *const SnipShortcutKey = @"SnipShortcutKey";
static NSString *const InputShortcutKey = @"InputShortcutKey";

@interface Shortcut : NSObject

+ (void)setup;

+ (void)readShortcutForKey:(NSString *)key completion:(void (^NS_NOESCAPE)(MASShortcut * _Nullable shorcut))completion;

@end

NS_ASSUME_NONNULL_END
