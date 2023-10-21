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

- (NSString *)splitCodeText;

- (NSString *)removeCommentSymbols;

- (NSString *)removeCommentSymbolPrefixAndJoinTexts;

- (NSString *)removeCommentSymbolPrefix;

/// Is start with comment symbol prefix, // and #
- (BOOL)hasCommentSymbolPrefix;

/// Filter Private Use Area characters
- (NSString *)filterPrivateUseCharacters;

@end

NS_ASSUME_NONNULL_END
