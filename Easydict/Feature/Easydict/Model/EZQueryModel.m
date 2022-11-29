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
    self.fromLanguage = Language_auto;
    self.toLanguage = Language_auto;
    self.viewHeight = 0;
}

@end
