//
//  EZQueryMenuTextView.h
//  Easydict
//
//  Created by tisfeng on 2023/10/17.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZQueryMenuTextView : NSTextView

- (void)queryInApp:(id)sender;

/// Returns the selected text, or the word at the insertion point when there is no selection.
- (nullable NSString *)selectedText;

@end

NS_ASSUME_NONNULL_END
