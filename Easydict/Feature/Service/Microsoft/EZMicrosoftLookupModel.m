//
//  EZMicrosoftLookupModel.m
//  Easydict
//
//  Created by ChoiKarl on 2023/8/10.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZMicrosoftLookupModel.h"

@implementation EZMicrosoftLookupBackTranslationsModel

@end

@implementation EZMicrosoftLookupTranslationsModel
+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"backTranslations": [EZMicrosoftLookupBackTranslationsModel class]
    };
}

@end

@implementation EZMicrosoftLookupModel
+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"translations": [EZMicrosoftLookupTranslationsModel class]
    };
}

@end
