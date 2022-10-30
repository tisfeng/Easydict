//
//  LNFactoryController.h
//  Keep
//
//  Created by chen on 5/26/19.
//  Copyright © 2019 Beijing Calorie Technology Co., Ltd. All rights reserved.
//

#define singleton_h(name) +(instancetype)shared;

#define kInstanceName _instance##name

#define singleton_m(name)                               \
    static id kInstanceName;                            \
                                                        \
    +(instancetype)shared {                             \
        static dispatch_once_t onceToken;               \
        dispatch_once(&onceToken, ^{                    \
            kInstanceName = [[self alloc] init];        \
        });                                             \
        return kInstanceName;                           \
    }                                                   \
    +(id)copy {        \
        return kInstanceName;                           \
    }

