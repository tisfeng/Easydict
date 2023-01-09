//
//  EZQueryModel.m
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryModel.h"
#import "EZConfiguration.h"

NSString *const EZQueryTypeAutoSelect = @"auto_select_query";
NSString *const EZQueryTypeShortcut = @"shortcut_query";
NSString *const EZQueryTypeInput = @"input_query";
NSString *const EZQueryTypeOCR = @"ocr_query";

@implementation EZQueryModel

- (instancetype)init {
    if (self = [super init]) {
        self.userSourceLanguage = EZConfiguration.shared.from;
        self.userTargetLanguage = EZConfiguration.shared.to;
        self.detectedLanguage = EZLanguageAuto;
        self.queryType = EZQueryTypeInput;
    }
    return self;
}

- (EZLanguage)queryFromLanguage {
    EZLanguage fromLanguage = self.userSourceLanguage;
    if ([fromLanguage isEqualToString:EZLanguageAuto]) {
        fromLanguage = self.detectedLanguage;
    }
    return fromLanguage;
}

- (EZLanguage)queryTargetLanguage {
    EZLanguage fromLanguage = self.queryFromLanguage;
    EZLanguage targetLanguage = self.userTargetLanguage;
    if ([targetLanguage isEqualToString:EZLanguageAuto]) {
        targetLanguage = [EZLanguageManager targetLanguageWithSourceLanguage:fromLanguage];
    }
    return targetLanguage;
}

@end
