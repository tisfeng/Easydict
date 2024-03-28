//
//  MASShortcutBinder+EZMASShortcutBinder.m
//  Easydict
//
//  Created by Sharker on 2023/12/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import "MASShortcutBinder+EZMASShortcutBinder.h"
#import "EZWindowManager.h"

@implementation MASShortcutBinder (EZMASShortcutBinder)
- (void)ez_bindShortcutWithDefaultsKey:(NSString *)defaultsKeyName toAction:(dispatch_block_t)action {
    EZWindowManager *windowManager = [EZWindowManager shared];
    [windowManager.popButtonWindow close];
    [self bindShortcutWithDefaultsKey:defaultsKeyName toAction:action];
}
@end
