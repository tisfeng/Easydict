//
//  MASShortcutBinder+EZMASShortcutBinder.h
//  Easydict
//
//  Created by Sharker on 2023/12/30.
//  Copyright © 2023 izual. All rights reserved.
//

@import MASShortcut;

NS_ASSUME_NONNULL_BEGIN

@interface MASShortcutBinder (EZMASShortcutBinder)
// hidden pop button when user playing shortcut
- (void)ez_bindShortcutWithDefaultsKey: (NSString*) defaultsKeyName toAction: (dispatch_block_t) action;
@end

NS_ASSUME_NONNULL_END
