//
//  EZBaiduTranslateResponse.h
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface EZBaiduTranslateResponsePart : NSObject

/// 单词属性，例如 'n.'、'vi.' 等
@property (nonatomic, copy, nullable) NSString *part;
/// 部分单词没有 part，只有 part_name，例如 “Referer”
@property (nonatomic, copy, nullable) NSString *part_name;
/// 此单词属性下单词的释义（可能是 string 类型，也可能是 dictionary，需要手动判断）
@property (nonatomic, strong) NSArray *means;

@end


@interface EZBaiduTranslateResponseSymbol : NSObject

/// 词性及释义
@property (nonatomic, strong) NSArray<EZBaiduTranslateResponsePart *> *parts;
/// 美语音标
@property (nonatomic, copy) NSString *ph_am;
/// 英语音标
@property (nonatomic, copy) NSString *ph_en;

@end

@interface EZBaiduTranslateResponseTags : NSObject

@property (nonatomic, copy, nullable) NSArray<NSString *> *core;
@property (nonatomic, copy, nullable) NSArray<NSString *> *other;

@end

@interface EZBaiduTranslateResponseExchange : NSObject

/// 第三人称单数
@property (nonatomic, copy, nullable) NSArray<NSString *> *word_third;
/// 复数
@property (nonatomic, copy, nullable) NSArray<NSString *> *word_pl;
/// 比较级
@property (nonatomic, copy, nullable) NSArray<NSString *> *word_er;
/// 最高级
@property (nonatomic, copy, nullable) NSArray<NSString *> *word_est;
/// 过去式
@property (nonatomic, copy, nullable) NSArray<NSString *> *word_past;
/// 过去分词
@property (nonatomic, copy, nullable) NSArray<NSString *> *word_done;
/// 现在分词
@property (nonatomic, copy, nullable) NSArray<NSString *> *word_ing;
/// 词根
@property (nonatomic, copy, nullable) NSArray<NSString *> *word_proto;

@end


@interface EZBaiduTranslateResponseSimpleMean : NSObject

/// 虽然这是一个数组，但是它一直都只有一个元素
@property (nonatomic, strong) NSArray<EZBaiduTranslateResponseSymbol *> *symbols;

@property (nonatomic, strong) EZBaiduTranslateResponseTags *tags;

/// 单词的其他变形
@property (nonatomic, strong) EZBaiduTranslateResponseExchange *exchange;
/// 中文查词时会有
@property (nonatomic, strong) NSArray<NSString *> *word_means;

@end


@interface EZBaiduTranslateResponseDictResult : NSObject

@property (nonatomic, strong, nullable) EZBaiduTranslateResponseSimpleMean *simple_means;

@end


@interface EZBaiduTranslateResponseData : NSObject

/// 查询的文本
@property (nonatomic, copy) NSString *src;
/// 查询结果
@property (nonatomic, copy) NSString *dst;

/// 是否有换行前缀 \n
@property (nonatomic, assign) BOOL prefixWrap;

@end


@interface EZBaiduTranslateResponseTransResult : NSObject

@property (nonatomic, strong) NSArray<EZBaiduTranslateResponseData *> *data;
@property (nonatomic, copy) NSString *from;
@property (nonatomic, copy) NSString *to;

@end


@interface EZBaiduTranslateResponse : NSObject

/// 查询失败时会有值，997 表示 token 有误，此时应该获取 BAIDUID 后重试
@property (nonatomic, assign) NSInteger error;
/// 针对英语单词会提供词典数据。若当前翻译没有词典数据，则这个属性为nil
@property (nonatomic, strong, nullable) EZBaiduTranslateResponseDictResult *dict_result;
/// 普通结果
@property (nonatomic, strong) EZBaiduTranslateResponseTransResult *trans_result;

@end

NS_ASSUME_NONNULL_END
