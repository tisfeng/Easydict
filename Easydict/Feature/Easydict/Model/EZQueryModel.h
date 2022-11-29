//
//  EZQueryModel.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslateLanguage.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZQueryModel : NSObject

@property (nonatomic, copy) NSString *queryText;
@property (nonatomic, assign) Language sourceLanguage;
@property (nonatomic, assign) Language targetLanguage;

@property (nonatomic, copy) NSString *sourceLanguageName;
@property (nonatomic, copy) NSString *targetLanguageName;

@property (nonatomic, assign) CGFloat viewHeight;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
