//
//  NSString+EZHandleInputText.h
//  Easydict
//
//  Created by tisfeng on 2023/10/12.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EZHandleInputText)

/// Split code text by snake case and camel case.
- (NSString *)splitCodeText;

/// Remove comment block symbols, /* */
- (NSString *)removeCommentBlockSymbols;

/// Check if all line starts with a comment symbol, #,//,*
- (BOOL)allLineStartsWithCommentSymbol;

/**
 Split camel and snake case text
 https://github.com/tisfeng/Easydict/issues/135#issuecomment-1750498120
 
 _anchoredDraggable_State --> anchored Draggable State
 */
- (NSString *)segmentWords;
@end

NS_ASSUME_NONNULL_END
