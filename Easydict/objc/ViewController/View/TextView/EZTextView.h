//
//  EZTextView.h
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZQueryMenuTextView.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZTextView : EZQueryMenuTextView

/// Paste text block
@property (nonatomic, copy) void (^pasteTextBlock)(NSString *text);


@property (nonatomic, copy) NSString *placeholderText;

@property (nonatomic, copy) NSAttributedString *placeholderAttributedString;

@property (nonatomic, assign) CGFloat customParagraphSpacing; // Should be non-zero, > 0


/// Update text, paragraphStyle.
- (void)updateTextAndParagraphStyle:(NSString *)text;

/// Update text block, callback when updateTextAndParagraphStyle: calls.
@property (nonatomic, copy) void (^updateTextBlock)(NSString *text);

@end

NS_ASSUME_NONNULL_END
