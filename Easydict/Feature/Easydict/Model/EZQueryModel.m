//
//  EZQueryModel.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryModel.h"

@implementation EZQueryModel

- (instancetype)init {
    if (self = [super init]) {
        [self reset];
    }
    return self;
}

- (void)reset {
    self.queryText = @"";
    self.sourceLanguage = EZLanguageAuto;
    self.targetLanguage = EZLanguageAuto;
    self.viewHeight = 0;
}

@end
