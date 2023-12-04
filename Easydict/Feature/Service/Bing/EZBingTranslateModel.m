//
//  EZBingTranslateModel.m
//  Easydict
//
//  Created by choykarl on 2023/8/10.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZBingTranslateModel.h"
#import "MJExtension.h"

@implementation EZBingDetectedLanguageModel

@end

@implementation EZBingTransliterationModel

@end

@implementation EZBingSentLenModel
+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"srcSentLen": [NSNumber class],
        @"transSentLen": [NSNumber class]
    };
}
@end

@implementation EZBingTranslationsModel

@end

@implementation EZBingTranslateModel
+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"translations": [EZBingTranslationsModel class]
    };
}
@end
