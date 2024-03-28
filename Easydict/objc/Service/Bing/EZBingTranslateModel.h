//
//  EZBingTranslateModel.h
//  Easydict
//
//  Created by choykarl on 2023/8/10.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 检测出的from语言
@interface EZBingDetectedLanguageModel : NSObject
/// example：en、zh-Hans...
@property (nonatomic, copy) NSString *language;
@property (nonatomic, assign) double score;
@end

@interface EZBingTransliterationModel : NSObject
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *script;
@end

@interface EZBingSentLenModel : NSObject
@property (nonatomic, strong) NSArray<NSNumber *> *srcSentLen;
@property (nonatomic, strong) NSArray<NSNumber *> *transSentLen;
@end

/// 翻译结果
@interface EZBingTranslationsModel : NSObject
/// 翻译结果
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) EZBingTransliterationModel *transliteration;
/// 翻译源语言
/// example：en、zh-Hans...
@property (nonatomic, copy) NSString *to;
@property (nonatomic, strong) EZBingSentLenModel *sentLen;
@end


@interface EZBingTranslateModel : NSObject
@property (nonatomic, strong) EZBingDetectedLanguageModel *detectedLanguage;
@property (nonatomic, strong) NSArray<EZBingTranslationsModel *> *translations;
@end

NS_ASSUME_NONNULL_END
