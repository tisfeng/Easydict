//
//  EZNiuTransTranslateResponse.m
//  Easydict
//
//  Created by tisfeng on 2023/2/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZNiuTransTranslateResponse.h"


@implementation EZNiuTransTranslateResponse

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"identifier" : @"id",
    };
}

@end

@implementation EZNiuTransTranslateResponseResult

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"isLangIsConfident" : @"lang_is_confident",
    };
}

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"texts" : [EZNiuTransTranslateResponseText class],
    };
}

@end

@implementation EZNiuTransTranslateResponseText

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"alternatives" : [EZNiuTransTranslateResponseAlternative class],
    };
}
	
@end

@implementation EZNiuTransTranslateResponseAlternative

@end


