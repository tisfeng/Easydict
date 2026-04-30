//
//  EDTextField.h
//  Easydict
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZQueryMenuTextView.h"

NS_ASSUME_NONNULL_BEGIN

// Since there seems to be a bug in NSTextField, even if the line spacing is set, it will be automatically reset to 0 after clicking, which cannot be solved for the time being, so I have to use NSTextView.
@interface EZLabel : EZQueryMenuTextView

// Nullable: the backing ivar is nil before `setText:` runs, e.g. when
// `setLineSpacing:` / `setFont:` trigger `updateDisplayedText` during init.
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, strong, nullable) NSColor *textForegroundColor;

@property (nonatomic, assign) CGFloat lineSpacing; // default 4

@property (nonatomic, assign) CGFloat paragraphSpacing; // default 0

- (CGSize)oneLineSize;

/// Builds the attributed string from `text` and pushes it into `textStorage`.
/// Exposed so subclasses (e.g. MarkdownLabel) can substitute their own
/// attribute pipeline while reusing the rest of EZLabel's setup.
- (void)updateDisplayedText;

@end

NS_ASSUME_NONNULL_END
