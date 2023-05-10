//
//  EZLinkParser.h
//  Easydict
//
//  Created by tisfeng on 2023/2/25.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZSchemaParser : NSObject

// Check if text started with easydict://
- (BOOL)isEasydictSchema:(NSString *)text;

/// Open Easydict URL Schema.
- (void)openURLSchema:(NSString *)URLSchema completion:(void (^)(BOOL isSuccess, NSString *_Nullable returnValue))completion;

@end

NS_ASSUME_NONNULL_END
