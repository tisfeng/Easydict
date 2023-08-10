//
//  EZMicrosoftTranslateModel.m
//  Easydict
//
//  Created by ChoiKarl on 2023/8/10.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZMicrosoftTranslateModel.h"
#import "MJExtension.h"

@implementation EZMicrosoftDetectedLanguageModel

@end

@implementation EZMicrosoftTransliterationModel

@end

@implementation EZMicrosoftSentLenModel
+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"srcSentLen": [NSNumber class],
        @"transSentLen": [NSNumber class]
    };
}
@end

@implementation EZMicrosoftTranslationsModel

@end

@implementation EZMicrosoftTranslateModel
+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"translations": [EZMicrosoftTranslationsModel class]  
    };
}
@end
