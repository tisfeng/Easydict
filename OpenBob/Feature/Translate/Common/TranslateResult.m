//
//  TranslateResult.m
//  Bob
//
//  Created by ripper on 2019/11/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "TranslateResult.h"
#import "EZServiceStorage.h"

NSString *const EZServiceTypeGoogle = @"Google";
NSString *const EZServiceTypeBaidu = @"Baidu";
NSString *const EZServiceTypeYoudao = @"Youdao";


@implementation TranslatePhonetic

@end


@implementation TranslatePart

@end


@implementation TranslateExchange

@end


@implementation TranslateSimpleWord

@end


@implementation TranslateWordResult

@end


@implementation TranslateResult

- (instancetype)init {
    if (self = [super init]) {
        _normalResults = @[@""];
//        _isShowing = [[EZServiceStorage shared] getServiceInfo:self.serviceType].enabled;

    }
    return self;
}

@end
