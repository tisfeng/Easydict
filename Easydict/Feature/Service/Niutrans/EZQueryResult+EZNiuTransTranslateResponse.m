//
//  EZQueryResult+EZNiuTransTranslateResponse.m
//  Easydict
//
//  Created by tisfeng on 2023/2/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZQueryResult+EZNiuTransTranslateResponse.h"


@implementation EZQueryResult (EZNiuTransTranslateResponse)

- (instancetype)setupWithNiuTransTranslateResponse:(EZNiuTransTranslateResponse *)niuTransTranslateResponse {
    NSString *translatedText = niuTransTranslateResponse.result.texts.firstObject.text;
    if (translatedText) {
        self.translatedResults = [translatedText.trim toParagraphs];
    }
    self.raw = niuTransTranslateResponse;

    return self;
}

@end


