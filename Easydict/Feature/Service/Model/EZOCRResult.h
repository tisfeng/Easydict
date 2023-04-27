//
//  EZOCRResult.h
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageManager.h"

NS_ASSUME_NONNULL_BEGIN


@interface EZOCRText : NSObject

/// 识别的文本
@property (nonatomic, copy) NSString *text;
/// 翻译过后的文本
@property (nonatomic, copy, nullable) NSString *translatedText;

@end


@interface EZOCRResult : NSObject

/// 源语言
@property (nonatomic, copy) EZLanguage from;

/// 目标语言，某些OCR服务带有翻译功能，如有道OCR。
@property (nonatomic, copy) EZLanguage to;

/// 文本识别结果，分句或分段
@property (nonatomic, strong) NSArray<EZOCRText *> *ocrTextArray;

@property (nonatomic, copy) NSArray<NSString *> *texts;

/// 合并过后的文本
@property (nonatomic, copy) NSString *mergedText;

/// OCR接口提供的原始的、未经转换的查询结果
@property (nonatomic, strong) id raw;

@property (nonatomic, assign) CGFloat confidence; // Apple OCR

@end

NS_ASSUME_NONNULL_END
