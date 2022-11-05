//
//  TranslateTypeMap.h
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Translate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TranslateTypeMap : NSObject

+ (Translate *)translateWithType:(EDQueryType)type;

@end

NS_ASSUME_NONNULL_END
