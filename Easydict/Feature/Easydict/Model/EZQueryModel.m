//
//  EZQueryModel.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryModel.h"

@implementation EZQueryModel

- (void)reset {
    self.queryText = @"";
    self.sourceLanguage = Language_auto;
    self.targetLanguage = Language_auto;
    self.viewHeight = 0;
}

- (NSString *)sourceLanguageName {
    return LanguageDescFromEnum(self.sourceLanguage);
}

- (NSString *)targetLanguageName {
    return LanguageDescFromEnum(self.targetLanguage);
}

@end
