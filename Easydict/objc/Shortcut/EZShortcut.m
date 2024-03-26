//
//  EZShortcut.m
//  Easydict
//
//  Created by tisfeng on 2022/11/27.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZShortcut.h"
#import "EZWindowManager.h"
#import "MASShortcutBinder+EZMASShortcutBinder.h"

@implementation EZShortcut

+ (void)setup {
    // Most apps need default shortcut, delete these lines if this is not your case.
    
    MASShortcut *inputShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_A modifierFlags:NSEventModifierFlagOption];
    NSData *inputShortcutData = [NSKeyedArchiver archivedDataWithRootObject:inputShortcut requiringSecureCoding:NO error:nil];
    
    MASShortcut *snipShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_S modifierFlags:NSEventModifierFlagOption];
    NSData *snipShortcutData = [NSKeyedArchiver archivedDataWithRootObject:snipShortcut requiringSecureCoding:NO error:nil];
    
    MASShortcut *selectionShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_D modifierFlags:NSEventModifierFlagOption];
    NSData *selectionShortcutData = [NSKeyedArchiver archivedDataWithRootObject:selectionShortcut requiringSecureCoding:NO error:nil];
    
    MASShortcut *showMiniShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_F modifierFlags:NSEventModifierFlagOption];
    NSData *showMiniShortcutData = [NSKeyedArchiver archivedDataWithRootObject:showMiniShortcut requiringSecureCoding:NO error:nil];
    
    MASShortcut *screenshotOCRShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_S modifierFlags:NSEventModifierFlagShift | NSEventModifierFlagOption];
    NSData *screenshotOCRShortcutData = [NSKeyedArchiver archivedDataWithRootObject:screenshotOCRShortcut requiringSecureCoding:NO error:nil];
    
    // Register default values to be used for the first app start.
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        EZInputShortcutKey : inputShortcutData,
        EZSelectionShortcutKey : selectionShortcutData,
        EZSnipShortcutKey : snipShortcutData,
        EZShowMiniShortcutKey : showMiniShortcutData,
        EZScreenshotOCRShortcutKey: screenshotOCRShortcutData,
    }];
    
    EZWindowManager *windowManager = [EZWindowManager shared];
    
    /**
     'NSKeyedUnarchiveFromData' should not be used to for un-archiving and will be removed in a future release
     
     But it's not easy to fix this warning, see: https://github.com/cocoabits/MASShortcut/issues/158
     
     [[MASShortcutBinder sharedBinder] setBindingOptions:@{NSValueTransformerNameBindingOption: NSSecureUnarchiveFromDataTransformerName}];
     */

    [[MASShortcutBinder sharedBinder] ez_bindShortcutWithDefaultsKey:EZSelectionShortcutKey toAction:^{
        [windowManager selectTextTranslate];
    }];
    
    [[MASShortcutBinder sharedBinder] ez_bindShortcutWithDefaultsKey:EZSnipShortcutKey toAction:^{
        [windowManager snipTranslate];
    }];
    
    [[MASShortcutBinder sharedBinder] ez_bindShortcutWithDefaultsKey:EZInputShortcutKey toAction:^{
        [windowManager inputTranslate];
    }];
    
    [[MASShortcutBinder sharedBinder] ez_bindShortcutWithDefaultsKey:EZShowMiniShortcutKey toAction:^{
        [windowManager showMiniFloatingWindow];
    }];
    
    [[MASShortcutBinder sharedBinder] ez_bindShortcutWithDefaultsKey:EZScreenshotOCRShortcutKey toAction:^{
        [windowManager screenshotOCR];
    }];
    
    [[MASShortcutValidator sharedValidator] setAllowAnyShortcutWithOptionModifier:YES];
}

+ (void)readShortcutForKey:(NSString *)key completion:(void (^NS_NOESCAPE)(MASShortcut *_Nullable shorcut))completion {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (data) {
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
