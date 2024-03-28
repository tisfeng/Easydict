//
//  EZDeepLTranslateResponse.m
//  Easydict
//
//  Created by tisfeng on 2023/2/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZDeepLTranslateResponse.h"

@implementation EZDeepLTranslateResponse

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"identifier" : @"id",
    };
}

@end

@implementation EZDeepLTranslateResponseResult

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"isLangIsConfident" : @"lang_is_confident",
    };
}

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"texts" : [EZDeepLTranslateResponseText class],
    };
}

@end

@implementation EZDeepLTranslateResponseText

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"alternatives" : [EZDeepLTranslateResponseAlternative class],
    };
}

@end

@implementation EZDeepLTranslateResponseAlternative

@end