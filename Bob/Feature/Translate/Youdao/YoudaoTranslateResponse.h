//
//  YoudaoTranslateResponse.h
//  Bob
//
//  Created by ripper on 2019/12/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YoudaoTranslateResponseWeb : NSObject

/// 原文
@property (nonatomic, copy) NSString *key;
/// 意思
@property (nonatomic, copy) NSArray<NSString *> *value;

@end

@interface YoudaoTranslateResponseBasic : NSObject

/// 默认音标，默认是英式音标，英文查词成功，一定存在
@property (nonatomic, copy) NSString *phonetic;
/// 美式音标，英文查词成功，一定存在
@property (nonatomic, copy) NSString *us_phonetic;
/// 英式音标，英文查词成功，一定存在
@property (nonatomic, copy) NSString *uk_phonetic;
/// 美式发音，英文查词成功，一定存在
@property (nonatomic, copy) NSString *us_speech;
/// 英式发音，英文查词成功，一定存在
@property (nonatomic, copy) NSString *uk_speech;
/// 基本释义 英文查词是NSString，中文查词是NSDictionary
@property (nonatomic, copy) NSArray *explains;

@end

@interface YoudaoTranslateResponse : NSObject

/// 错误返回码 一定存在
@property (nonatomic, copy) NSString *errorCode;
/// 源语言原文 查询正确时，一定存在
@property (nonatomic, copy) NSString *query;
/// 翻译结果 查询正确时，一定存在
@property (nonatomic, strong) NSArray<NSString *> *translation;
/// 词义 基本词典，查词时才有
@property (nonatomic, strong) YoudaoTranslateResponseBasic *basic;
/// 词义 网络释义，该结果不一定存在
@property (nonatomic, strong) NSArray<YoudaoTranslateResponseWeb *> *web;
/// 源语言和目标语言 e.g."zh-CHS2ja" 用"2"分割 一定存在
@property (nonatomic, copy) NSString *l;
/// 词典deeplink 查询语种为支持语言时，存在
@property (nonatomic, copy) NSString *dict;
/// webdeeplink 查询语种为支持语言时，存在
@property (nonatomic, copy) NSString *webdict;
/// 翻译结果发音地址 翻译成功一定存在，需要应用绑定语音合成实例才能正常播放；否则返回110错误码
@property (nonatomic, copy) NSString *tSpeakUrl;
/// 源语言发音地址 翻译成功一定存在，需要应用绑定语音合成实例才能正常播放；否则返回110错误码
@property (nonatomic, copy) NSString *speakUrl;
/// 单词校验后的结果 主要校验字母大小写、单词前含符号、中文简繁体
@property (nonatomic, strong) NSArray *returnPhrase;

@end

NS_ASSUME_NONNULL_END
