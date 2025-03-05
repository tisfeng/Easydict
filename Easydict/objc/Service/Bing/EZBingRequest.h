//
//  EZBingRequest.h
//  Easydict
//
//  Created by choykarl on 2023/8/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageManager.h"
#import "EZBingConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^BingTranslateCompletion)(NSData * _Nullable translateData, NSData * _Nullable lookupData, NSError * _Nullable translateError, NSError * _Nullable lookupError);

@interface EZBingRequest : NSObject

@property (nonatomic, strong) EZBingConfig *bingConfig;

- (void)translateText:(NSString *)text from:(NSString *)from to:(NSString *)to  completionHandler:(BingTranslateCompletion)completion;

- (void)reset;

- (void)fetchTextToAudio:(NSString *)text
            fromLanguage:(EZLanguage)from
                  accent:(NSString * _Nullable)accent
              completion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion;

- (void)translateTextFromDict:(NSString *)text completion:(void (^)(NSDictionary * _Nullable json, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
