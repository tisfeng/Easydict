//
//  EZTextDetectUtils.h
//  Easydict
//
//  Created by tisfeng on 2023/4/15.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZTextDetectUtils : NSObject

+ (EZLanguage)detextText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
