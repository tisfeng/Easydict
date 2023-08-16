//
//  EZBingRequest.h
//  Easydict
//
//  Created by ChoiKarl on 2023/8/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NSString *getTranslatorHost(void);

typedef void(^BingTranslateCompletion)(NSData * _Nullable translateData, NSData * _Nullable lookupData, NSError * _Nullable translateError, NSError * _Nullable lookupError);

@interface EZBingRequest : NSObject

- (void)translateWithFrom:(NSString *)from to:(NSString *)to text:(NSString *)text completionHandler:(BingTranslateCompletion)completion;

- (void)reset;
@end

NS_ASSUME_NONNULL_END
