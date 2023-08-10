//
//  EZMicrosoftRequest.h
//  Easydict
//
//  Created by ChoiKarl on 2023/8/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^MicrosoftTranslateCompletion)(NSData * _Nullable result, NSData * _Nullable lookup, NSError * _Nullable error);

@interface EZMicrosoftRequest : NSObject

- (void)translateWithFrom:(NSString *)from to:(NSString *)to text:(NSString *)text completionHandler:(MicrosoftTranslateCompletion)completion;
@end

NS_ASSUME_NONNULL_END
