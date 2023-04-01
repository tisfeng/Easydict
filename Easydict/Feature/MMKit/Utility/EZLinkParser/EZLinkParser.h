//
//  EZLinkParser.h
//  Easydict
//
//  Created by tisfeng on 2023/2/25.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZLinkParser : NSObject

// Check if text started with easydict://
- (BOOL)isEasydictSchema:(NSString *)text;

/// Open URL with text, return YES if text is started with Easydict://.
- (BOOL)openURLWithText:(NSString *)text completion:(void (^)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
