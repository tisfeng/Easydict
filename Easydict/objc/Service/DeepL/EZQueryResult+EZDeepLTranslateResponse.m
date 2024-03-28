//
//  EZQueryResult+EZDeepLTranslateResponse.m
//  Easydict
//
//  Created by tisfeng on 2023/2/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZQueryResult+EZDeepLTranslateResponse.h"

@implementation EZQueryResult (EZDeepLTranslateResponse)

- (instancetype)setupWithDeepLTranslateResponse:(EZDeepLTranslateResponse *)deepLTranslateResponse {
    NSString *translatedText = deepLTranslateResponse.result.texts.firstObject.text;
    if (translatedText) {
        self.translatedResults = [translatedText.trim toParagraphs];
    }
    self.raw = deepLTranslateResponse;

    return self;
}

@end
