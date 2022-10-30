//
//  Translate.h
//  Bob
//
//  Created by ripper on 2019/12/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslateLanguage.h"
#import "TranslateResult.h"
#import "TranslateError.h"
#import "OCRResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface Translate : NSObject

/// 支持的语言
- (NSArray<NSNumber *> *)languages;

/// 语言枚举转字符串，不支持则返回空
- (NSString * _Nullable)languageStringFromEnum:(Language)lang;

/// 语言字符串转枚举，不支持则返回Auto
- (Language)languageEnumFromString:(NSString *)langString;

/// 语言在支持的语言数组中的位置，不包含则返回0
- (NSInteger)indexForLanguage:(Language)lang;

@end

/// 以下方法供子类重写，且必须重写
@interface Translate ()

/// 当前翻译对象唯一标识符
- (NSString *)identifier;

/// 翻译的名字
- (NSString *)name;

/// 翻译网站首页
- (NSString *)link;

/// 支持的语言字典
- (MMOrderedDictionary *)supportLanguagesDictionary;

/// 文本翻译
/// @param text 查询文本
/// @param from 文本语言
/// @param to 目标语言
/// @param completion 回调
- (void)translate:(NSString *)text from:(Language)from to:(Language)to completion:(void (^)(TranslateResult * _Nullable result, NSError * _Nullable error))completion;

/// 获取文本的语言
/// @param text 文本
/// @param completion 回调
- (void)detect:(NSString *)text completion:(void (^)(Language lang, NSError * _Nullable error))completion;

/// 获取文本的音频的URL地址
/// @param text 文本
/// @param from 文本语言
/// @param completion 回调
- (void)audio:(NSString *)text from:(Language)from completion:(void (^)(NSString * _Nullable url, NSError * _Nullable error))completion;

/// 识别图片文本
/// @param image image对象
/// @param from 文本语言
/// @param to 目标语言
/// @param completion 回调
- (void)ocr:(NSImage *)image from:(Language)from to:(Language)to completion:(void (^)(OCRResult * _Nullable result, NSError * _Nullable error))completion;

/// 图片翻译，识图+翻译
/// @param image image对象
/// @param from 文本语言
/// @param to 目标语言
/// @param ocrSuccess 只有OCR识别成功才回调，willInvokeTranslateAPI代表是否会发送翻译请求（有的OCR接口自带翻译功能）
/// @param completion 回调
- (void)ocrAndTranslate:(NSImage *)image
                   from:(Language)from
                     to:(Language)to
             ocrSuccess:(void (^)(OCRResult * result, BOOL willInvokeTranslateAPI))ocrSuccess
             completion:(void (^)(OCRResult * _Nullable ocrResult, TranslateResult * _Nullable result, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
