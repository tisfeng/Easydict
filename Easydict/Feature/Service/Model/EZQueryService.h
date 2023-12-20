//
//  EZQueryService.h
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZQueryResult.h"
#import "EZError.h"
#import "EZOCRResult.h"
#import "EZQueryModel.h"
#import "EZLayoutManager.h"
#import "EZAudioPlayer.h"
#import "MMOrderedDictionary.h"

NS_ASSUME_NONNULL_BEGIN

//@class EZAudioPlayer;

NS_SWIFT_NAME(QueryService)
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

@property (nonatomic, copy, nullable) void (^autoCopyTranslatedTextBlock)(EZQueryResult *result, NSError *_Nullable error);

/// 支持的语言
- (NSArray<EZLanguage> *)languages;

/// 语言枚举转字符串，不支持则返回空
- (nullable NSString *)languageCodeForLanguage:(EZLanguage)lang;

/// 语言字符串转枚举，不支持则返回Auto
- (EZLanguage)languageEnumFromCode:(NSString *)langString;

/// 语言在支持的语言数组中的位置，不包含则返回0
- (NSInteger)indexForLanguage:(EZLanguage)lang;

/// 预处理查询，如遇到不支持的语言，直接报错提示。
- (BOOL)prehandleQueryTextLanguage:(NSString *)text
                              from:(EZLanguage)from
                                to:(EZLanguage)to
                        completion:(void (^)(EZQueryResult *result, NSError *_Nullable error))completion;

/// Get TTS langauge code.
- (NSString *)getTTSLanguageCode:(EZLanguage)language;

- (void)startQuery:(EZQueryModel *)queryModel completion:(void (^)(EZQueryResult *result, NSError *_Nullable error))completion;

@end


#pragma mark - 必须重写的子类方法

@interface EZQueryService ()

/// 服务类型
- (EZServiceType)serviceType;

/// 服务名字
- (NSString *)name;

/// 服务网站链接
- (nullable NSString *)link;

/// 单词直达链接，如果为空，则使用 link
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel;

/// 支持的语言字典
- (MMOrderedDictionary *)supportLanguagesDictionary;

/// 文本翻译
/// @param text 查询文本
/// @param from 文本语言
/// @param to 目标语言
/// @param completion 回调
- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *result, NSError *_Nullable error))completion;


#pragma mark - 可选重写的子类方法

/// 如果服务不支持繁体中文，可重写返回 YES 来支持。
- (BOOL)autoConvertTraditionalChinese;

/// Service usage status, default is EZServiceUsageStatusDefault 0
- (EZServiceUsageStatus)serviceUsageStatus;

/// Query text type, default is EZQueryTextTypeTranslation | EZQueryTextTypeSentence
- (EZQueryTextType)queryTextType;

/// Intelligent query text type, default is EZQueryTextTypeTranslation | EZQueryTextTypeSentence
- (EZQueryTextType)intelligentQueryTextType;

/// Check if user has private API key.
- (BOOL)hasPrivateAPIKey;

- (BOOL)needPrivateAPIKey;

- (NSInteger)totalFreeQueryCharacterCount;

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
