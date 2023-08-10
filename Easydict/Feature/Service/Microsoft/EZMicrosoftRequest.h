//
//  EZMicrosoftRequest.h
//  Easydict
//
//  Created by ChoiKarl on 2023/8/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kTranslatorHost = @"https://www.bing.com/translator";

typedef void(^MicrosoftTranslateCompletion)(NSData * _Nullable translateData, NSData * _Nullable lookupData, NSError * _Nullable translateError, NSError * _Nullable lookupError);

@interface EZMicrosoftRequest : NSObject

- (void)translateWithFrom:(NSString *)from to:(NSString *)to text:(NSString *)text completionHandler:(MicrosoftTranslateCompletion)completion;
@end

NS_ASSUME_NONNULL_END
