//
//  DetectText.h
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslateService.h"
#import "TranslateLanguage.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZDetectManager : NSObject

@property (nonatomic, assign) Language language;

- (void)detect:(NSString *)text completion:(nonnull void (^)(Language language, NSError *_Nullable))completion;

@end

NS_ASSUME_NONNULL_END
