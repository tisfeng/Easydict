//
//  EZTextDetectUtils.m
//  Easydict
//
//  Created by tisfeng on 2023/4/15.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZTextDetectUtils.h"
#import "EZLanguageManager.h"

@implementation EZTextDetectUtils

+ (EZLanguage)detextText:(NSString *)text {
    
    return [EZLanguageManager firstLanguage];
}

@end
