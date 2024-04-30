//
//  EZBingLookupModel.h
//  Easydict
//
//  Created by choykarl on 2023/8/10.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZBingLookupBackTranslationsModel : NSObject
@property (nonatomic, copy) NSString *normalizedText;
@property (nonatomic, copy) NSString *displayText;
@property (nonatomic, assign) NSInteger numExamples;
@property (nonatomic, assign) NSInteger frequencyCount;
@end

@interface EZBingLookupTranslationsModel : NSObject
@property (nonatomic, copy) NSString *normalizedTarget;
@property (nonatomic, copy) NSString *displayTarget;
@property (nonatomic, copy) NSString *posTag;
@property (nonatomic, assign) double confidence;
@property (nonatomic, copy) NSString *prefixWord;
@property (nonatomic, strong) NSArray<EZBingLookupBackTranslationsModel *> *backTranslations;
@end

@interface EZBingLookupModel : NSObject
@property (nonatomic, copy) NSString *normalizedSource;
@property (nonatomic, copy) NSString *displaySource;
@property (nonatomic, strong) NSArray<EZBingLookupTranslationsModel *> *translations;
@end

NS_ASSUME_NONNULL_END
