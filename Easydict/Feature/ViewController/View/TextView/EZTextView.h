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

/// property for paste text block
@property (nonatomic, copy) void (^pasteTextBlock)(NSString *text);

@property (nonatomic, copy) NSString *placeholderText;

@property (nonatomic, copy) NSAttributedString *placeholderAttributedString;

/// paragraphSpacing
@property (nonatomic, assign) CGFloat paragraphSpacing;

- (void)updateTextAndParagraphStyle:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
