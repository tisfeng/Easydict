//
//  EZTextView.h
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZTextView : NSTextView

/// Paste text block
@property (nonatomic, copy) void (^pasteTextBlock)(NSString *text);


@property (nonatomic, copy) NSString *placeholderText;

@property (nonatomic, copy) NSAttributedString *placeholderAttributedString;

/// paragraphSpacing
@property (nonatomic, assign) CGFloat paragraphSpacing;

/// Update text, paragraphStyle, and scroll to end of textView.
- (void)updateTextAndParagraphStyle:(NSString *)text;

/// Update text block, callback when updateTextAndParagraphStyle: calls.
@property (nonatomic, copy) void (^updateTextBlock)(NSString *text);

@end

NS_ASSUME_NONNULL_END
