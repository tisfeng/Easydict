//
//  EZMicrosoftTranslateModel.h
//  Easydict
//
//  Created by ChoiKarl on 2023/8/10.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 检测出的from语言
@interface EZMicrosoftDetectedLanguageModel : NSObject
/// example：en、zh-Hans...
@property (nonatomic, copy) NSString *language;
@property (nonatomic, assign) double score;
@end

@interface EZMicrosoftTransliterationModel : NSObject
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *script;
@end

@interface EZMicrosoftSentLenModel : NSObject
@property (nonatomic, strong) NSArray<NSNumber *> *srcSentLen;
@property (nonatomic, strong) NSArray<NSNumber *> *transSentLen;
@end

/// 翻译结果
@interface EZMicrosoftTranslationsModel : NSObject
/// 翻译结果
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) EZMicrosoftTransliterationModel *transliteration;
/// 翻译源语言
/// example：en、zh-Hans...
@property (nonatomic, copy) NSString *to;
@property (nonatomic, strong) EZMicrosoftSentLenModel *sentLen;
@end


@interface EZMicrosoftTranslateModel : NSObject
@property (nonatomic, strong) EZMicrosoftDetectedLanguageModel *detectedLanguage;
@property (nonatomic, strong) NSArray<EZMicrosoftTranslationsModel *> *translations;
@end

NS_ASSUME_NONNULL_END
