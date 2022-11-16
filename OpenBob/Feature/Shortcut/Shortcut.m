//
//  Shortcut.m
//  Bob
//
//  Created by ripper on 2019/12/9.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "Shortcut.h"
#import "EZMiniWindowController.h"


@implementation Shortcut

+ (void)setup {
    // Most apps need default shortcut, delete these lines if this is not your case
    MASShortcut *selectionShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_D modifierFlags:NSEventModifierFlagOption];
//    NSData *selectionShortcutData = [NSKeyedArchiver archivedDataWithRootObject:selectionShortcut];
    NSData *selectionShortcutData = [NSKeyedArchiver archivedDataWithRootObject:selectionShortcut requiringSecureCoding:NO error:nil];
    
    MASShortcut *snipShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_S modifierFlags:NSEventModifierFlagOption];
//    NSData *snipShortcutData = [NSKeyedArchiver archivedDataWithRootObject:snipShortcut];
    NSData *snipShortcutData = [NSKeyedArchiver archivedDataWithRootObject:snipShortcut requiringSecureCoding:NO error:nil];

    
    MASShortcut *inputShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_A modifierFlags:NSEventModifierFlagOption];
//    NSData *inputShortcutData = [NSKeyedArchiver archivedDataWithRootObject:inputShortcut];
    NSData *inputShortcutData = [NSKeyedArchiver archivedDataWithRootObject:inputShortcut requiringSecureCoding:NO error:nil];


    // Register default values to be used for the first app start
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        SelectionShortcutKey : selectionShortcutData,
        SnipShortcutKey : snipShortcutData,
        InputShortcutKey : inputShortcutData,
    }];

    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:SelectionShortcutKey toAction:^{
        [EZMiniWindowController.shared selectionTranslate];
    }];

    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:SnipShortcutKey toAction:^{
        [EZMiniWindowController.shared snipTranslate];
    }];

    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:InputShortcutKey toAction:^{
        [EZMiniWindowController.shared inputTranslate];
    }];

    [[MASShortcutValidator sharedValidator] setAllowAnyShortcutWithOptionModifier:YES];
}

+ (void)readShortcutForKey:(NSString *)key completion:(void (^NS_NOESCAPE)(MASShortcut *_Nullable shorcut))completion {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (data) {
//        MASShortcut *shortcut = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        MASShortcut *shortcut = [NSKeyedUnarchiver unarchivedObjectOfClass:MASShortcut.class fromData:data error:nil];

        if (shortcut && [shortcut isKindOfClass:MASShortcut.class]) {
            if (shortcut.keyCodeStringForKeyEquivalent.length || shortcut.modifierFlags) {
                completion(shortcut);
            } else {
                completion(nil);
            }
        } else {
            completion(nil);
        }
    } else {
        completion(nil);
    }
}

@end
