//
//  TranslateTypeMap.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "TranslateTypeMap.h"
#import "GoogleTranslate.h"
#import "BaiduTranslate.h"
#import "YoudaoTranslate.h"

@implementation TranslateTypeMap

+ (Translate *)translateWithType:(EDQueryType)type {
    NSDictionary *dict = @{
        EDQueryTypeGoogle : GoogleTranslate.new,
        EDQueryTypeBaidu : BaiduTranslate.new,
        EDQueryTypeYoudao : YoudaoTranslate.new
    };
    return dict[type];
}

@end
