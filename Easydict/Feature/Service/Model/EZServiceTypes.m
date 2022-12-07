//
//  TranslateTypeMap.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZServiceTypes.h"
#import "EZGoogleTranslate.h"
#import "EZBaiduTranslate.h"
#import "EZYoudaoTranslate.h"
#import "EZDeppLTranslate.h"

@implementation EZServiceTypes

+ (NSArray<EZServiceType> *)allServiceTypes {
    return [[self serviceDict] allKeys];
}

+ (NSDictionary<EZServiceType, Class> *)serviceDict {
    NSDictionary *dict = @{
        EZServiceTypeGoogle : [EZGoogleTranslate class],
        EZServiceTypeBaidu : [EZBaiduTranslate class],
        EZServiceTypeYoudao : [EZYoudaoTranslate class],
        EZServiceTypeDeepL : [EZDeppLTranslate class],
    };
    return dict;
}

+ (EZQueryService *)serviceWithType:(EZServiceType)type {
    Class Cls = [[self serviceDict] objectForKey:type];
    return [Cls new];
}

@end
