//
//  YoudaoTranslateResponse.m
//  Bob
//
//  Created by ripper on 2019/12/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "YoudaoTranslateResponse.h"

@implementation YoudaoTranslateResponseWeb

+(NSDictionary *)mj_objectClassInArray {
    return @{
        @"value": NSString.class,
    };
}

@end

@implementation YoudaoTranslateResponseBasic

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"explains": NSString.class,
    };
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"us_phonetic": @"us-phonetic",
        @"uk_phonetic": @"uk-phonetic",
        @"us_speech": @"us-speech",
        @"uk_speech": @"uk-speech",
    };
}

@end


@implementation YoudaoTranslateResponse

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"translation": NSString.class,
        @"web": YoudaoTranslateResponseWeb.class,
    };
}

@end
