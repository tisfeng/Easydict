//
//  YoudaoOCRResponse.m
//  Bob
//
//  Created by ripper on 2019/12/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "YoudaoOCRResponse.h"

@implementation YoudaoOCRResponseLine

@end

@implementation YoudaoOCRResponse

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"lines": YoudaoOCRResponseLine.class,
    };
}

@end
