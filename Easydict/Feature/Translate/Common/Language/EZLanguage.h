//
//  EZLanguage.h
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslateLanguage.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZLanguage : NSObject

@property (nonatomic, assign) Language sourceLanguage;
@property (nonatomic, copy) NSString *translateLanguage;
@property (nonatomic, copy) NSString *detectLanguage;

@end

NS_ASSUME_NONNULL_END
