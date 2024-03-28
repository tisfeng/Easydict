//
//  EZBingLookupModel.m
//  Easydict
//
//  Created by choykarl on 2023/8/10.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZBingLookupModel.h"

@implementation EZBingLookupBackTranslationsModel

@end

@implementation EZBingLookupTranslationsModel
+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"backTranslations": [EZBingLookupBackTranslationsModel class]
    };
}

@end

@implementation EZBingLookupModel
+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"translations": [EZBingLookupTranslationsModel class]
    };
}

@end
