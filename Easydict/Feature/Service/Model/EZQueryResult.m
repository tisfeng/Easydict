//
//  EZQueryResult.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryResult.h"
#import "EZLocalStorage.h"

NSString *const EZServiceTypeGoogle = @"Google";
NSString *const EZServiceTypeBaidu = @"Baidu";
NSString *const EZServiceTypeYoudao = @"Youdao";
NSString *const EZServiceTypeApple = @"Apple";
NSString *const EZServiceTypeDeepL = @"DeepL";


@implementation EZTranslatePhonetic : NSObject

@end


@implementation EZTranslatePart : NSObject

@end


@implementation EZTranslateExchange : NSObject

@end


@implementation EZTranslateSimpleWord : NSObject

@end


@implementation EZTranslateWordResult

@end


@implementation EZQueryResult

- (instancetype)init {
    if (self = [super init]) {
//        _normalResults = @[@""];
//        _isShowing = [[EZServiceStorage shared] getServiceInfo:self.serviceType].enabled;

    }
    return self;
}

- (NSString *)translatedText {
    NSString *text = [self.normalResults componentsJoinedByString:@"\n"];
    return text;
}

- (BOOL)isEmpty {
    if (!self.wordResult && self.translatedText.length == 0 && !self.error) {
        return YES;
    }
    return NO;
}

@end
