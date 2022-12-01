//
//  EZQueryModel.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryModel.h"
#import "EZConfiguration.h"

@implementation EZQueryModel

- (instancetype)init {
    if (self = [super init]) {
        self.sourceLanguage = EZConfiguration.shared.from;
        self.targetLanguage = EZConfiguration.shared.to;
        self.detectedLanguage = EZLanguageAuto;
    }
    return self;
}

@end
