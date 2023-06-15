//
//  EZQueryService.h
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZQueryResult.h"
#import "EZTranslateError.h"
#import "EZOCRResult.h"
#import "EZQueryModel.h"
#import "EZLayoutManager.h"
#import "EZAudioPlayer.h"
#import "EZError.h"

NS_ASSUME_NONNULL_BEGIN

//@class EZAudioPlayer;

@interface EZQueryService : NSObject

@property (nonatomic, strong) EZQueryModel *queryModel;

/// 翻译结果
@property (nonatomic, strong) EZQueryResult *result;

/// In the settings page, whether the service is enabled or not.
@property (nonatomic, assign) BOOL enabled;
/// In the query page, whether to allow this service query.
@property (nonatomic, assign) BOOL enabledQuery;

@property (nonatomic, assign) BOOL enabledAutoQuery;

@property (nonatomic, assign) EZWindowType windowType;

@property (nonatomic, strong) EZAudioPlayer *audioPlayer;

@property (nonatomic, copy, nullable) void (^didFinishBlock)(EZQueryResult *result, NSError *error);
@property (nonatomic, copy, nullable) void (^autoCopyTranslatedTextBlock)(EZQueryResult *result, NSError *error);


/// 支持的语言
- (NSArray<EZLanguage> *)languages;

/// 语言枚举转字符串，不支持则返回空
- (NSString *_Nullable)languageCodeForLanguage:(EZLanguage)lang;

/// 语言字符串转枚举，不支持则返回Auto
- (EZLanguage)languageEnumFromCode:(NSString *)langString;


/// 语言在支持的语言数组中的位置，不包含则返回0
- (NSInteger)indexForLanguage:(EZLanguage)lang;


/// 是否提前处理查询，如不支持的语言
/// - Parameters:
/// - isAutoConvert: 是否使用本地中文简繁体转换，如 API 服务支持繁简体，则最好交给 API。
- (BOOL)prehandleQueryTextLanguage:(NSString *)text autoConvertChineseText:(BOOL)isAutoConvert from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion;

/// Get TTS langauge code.
- (NSString *)getTTSLanguageCode:(EZLanguage)language;

@end


/// 以下方法供子类重写，且必须重写
@interface EZQueryService ()

/// 当前翻译对象唯一标识符, OpenAI
- (EZServiceType)serviceType;

/// Query text type: dictionary ,translation, sentence.
- (EZQueryTextType)queryTextType;

- (EZQueryTextType)intelligentQueryTextType;

/// Service usage status.
- (EZServiceUsageStatus)serviceUsageStatus;

/// 翻译的名字
- (NSString *)name;

/// 翻译网站首页
- (nullable NSString *)link;

/// 单词直达链接
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel;

/// 支持的语言字典
- (MMOrderedDictionary *)supportLanguagesDictionary;


#pragma mark - Old Methods

/// 文本翻译
/// @param text 查询文本
/// @param from 文本语言
/// @param to 目标语言
/// @param completion 回调
- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion;

/// 获取文本的语言
/// @param text 文本
/// @param completion 回调
- (void)detectText:(NSString *)text completion:(void (^)(EZLanguage detectedLanguage, NSError *_Nullable error))completion;

/// 获取文本的音频的URL地址
/// @param text 文本
/// @param from 文本语言
/// @param completion 回调
- (void)textToAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(void (^)(NSString *_Nullable url, NSError *_Nullable error))completion;

/// 识别图片文本
/// @param image image对象
/// @param from 文本语言
/// @param to 目标语言
/// @param completion 回调
- (void)ocr:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZOCRResult *_Nullable result, NSError *_Nullable error))completion;


- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion;


/// 图片翻译，识图+翻译
/// @param image image对象
/// @param from 文本语言
/// @param to 目标语言
/// @param ocrSuccess 只有OCR识别成功才回调，willInvokeTranslateAPI代表是否会发送翻译请求（有的OCR接口自带翻译功能）
/// @param completion 回调
- (void)ocrAndTranslate:(NSImage *)image
                   from:(EZLanguage)from
                     to:(EZLanguage)to
             ocrSuccess:(void (^)(EZOCRResult *result, BOOL willInvokeTranslateAPI))ocrSuccess
             completion:(void (^)(EZOCRResult *_Nullable EZOCRResult, EZQueryResult *_Nullable result, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
