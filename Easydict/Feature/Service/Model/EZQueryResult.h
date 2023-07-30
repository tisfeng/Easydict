//
//  EZQueryResult.h
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZQueryModel.h"
#import "EZEnumTypes.h"
#import "EZLanguageModel.h"
#import "EZError.h"

NS_ASSUME_NONNULL_BEGIN

@class EZQueryService;

@interface EZWordPhonetic : NSObject

@property (nonatomic, copy) NSString *word;
@property (nonatomic, copy) EZLanguage language;

/// 此语种对应的音标值
@property (nonatomic, copy, nullable) NSString *value;
/// 此音标对应的语音地址
@property (nonatomic, copy, nullable) NSString *speakURL;

/// 音标类型，美/英
@property (nonatomic, copy, nullable) NSString *name;

// 口音，us, uk
@property (nonatomic, copy, nullable) NSString *accent;

@end


@interface EZTranslatePart : NSObject

/// 单词属性，例如 'n.'、'vi.' 等
@property (nonatomic, copy, nullable) NSString *part;
/// 此单词属性下单词的释义
@property (nonatomic, strong) NSArray<NSString *> *means;

@end


@interface EZTranslateExchange : NSObject

/// 形式的名字
@property (nonatomic, copy) NSString *name;
/// 对应形式的单词，可能是多个
@property (nonatomic, strong) NSArray<NSString *> *words;

@end


@interface EZTranslateSimpleWord : NSObject

/// 单词或短语
@property (nonatomic, copy) NSString *word;
/// 单词或短语属性
@property (nonatomic, copy, nullable) NSString *part; // adj.
/// 单词或短语意思
@property (nonatomic, strong, nullable) NSArray<NSString *> *means; // 美好的

@property (nonatomic, copy) NSString *meansText; // means join @"; "

///  move part to meansText
@property (nonatomic, assign) BOOL showPartMeans; // adj. 美好的

@end


@interface EZTranslateWordResult : NSObject

/// 音标
@property (nonatomic, copy, nullable) NSArray<EZWordPhonetic *> *phonetics;
/// 词性词义
@property (nonatomic, copy, nullable) NSArray<EZTranslatePart *> *parts;
/// 其他形式
@property (nonatomic, copy, nullable) NSArray<EZTranslateExchange *> *exchanges;
/// 中文查词时会有，单词短语数组
@property (nonatomic, copy, nullable) NSArray<EZTranslateSimpleWord *> *simpleWords;

/// 标签：四级，六级，考研
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;

/// 词源
@property (nonatomic, copy, nullable) NSString *etymology;

@end


@interface EZQueryResult : NSObject

@property (nonatomic, strong) EZQueryModel *queryModel;

@property (nonatomic, copy) EZServiceType serviceType;
@property (nonatomic, weak) EZQueryService *service;

@property (assign) BOOL isShowing;
@property (nonatomic, assign) CGFloat viewHeight;

@property (assign) BOOL isLoading;
@property (assign) BOOL isFinished; // For OpenAI


/// 此次查询的文本
@property (nonatomic, copy) NSString *queryText;

// TODO: Need to make sure the from and to language is correct, not from API.

/// 由翻译接口提供的源语种，可能会与查询对象的 from 不同
@property (nonatomic, copy) EZLanguage from;
/// 由翻译接口提供的目标语种，注意可能会与查询对象的 to 不同
@property (nonatomic, copy) EZLanguage to;
/// 中文查词或英文查词的情况下，翻译接口会返回这个单词（词组）的详细释义
@property (nonatomic, strong, nullable) EZTranslateWordResult *wordResult;
/// 普通翻译结果，可以有多条（一个段落对应一个翻译结果）
@property (nonatomic, strong, nullable) NSArray<NSString *> *translatedResults;

/// This is normalResults joined by @"\n"
@property (nonatomic, copy) NSString *translatedText;

@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, copy, nullable) NSString *errorMessage;
@property (nonatomic, assign) EZErrorType errorType;

@property (nonatomic, assign) BOOL manulShow;

/// If (self.hasTranslatedResult || self.error || self.errorMessage.length), then hasShowingResult = YES, that means will show result view.
@property (nonatomic, assign, readonly) BOOL hasShowingResult;

/// If (self.wordResult && self.translatedText.length), YES
@property (nonatomic, assign, readonly) BOOL hasTranslatedResult;

/// EZErrorTypeUnsupportedLanguage || EZErrorTypeNoResultsFound
@property (nonatomic, assign, readonly) BOOL isWarningErrorType;

/// 查询文本的发音地址
@property (nonatomic, copy, nullable) NSString *fromSpeakURL;
/// 翻译后的发音地址
@property (nonatomic, copy, nullable) NSString *toSpeakURL;
/// 翻译接口提供的原始的、未经转换的查询结果
@property (nonatomic, strong, nullable) id raw;

@property (nonatomic, copy, nullable) NSString *promptTitle;
@property (nonatomic, copy, nullable) NSString *promptURL;

@property (nonatomic, assign) BOOL showBigWord;
@property (nonatomic, assign) CGFloat translateResultsTopInset;

@property (nonatomic, copy, nullable) NSString *HTMLString;

/// 未查询到结果，如系统词典查单词时，查询了句子
@property (nonatomic, assign) BOOL noResultsFound;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
