//
//  EZYoudaoOCRResponse.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZYoudaoOCRResponse.h"

@implementation EZYoudaoOCRResponseLine

@end


@implementation EZYoudaoOCRResponse

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"lines" : EZYoudaoOCRResponseLine.class,
    };
}

@end
