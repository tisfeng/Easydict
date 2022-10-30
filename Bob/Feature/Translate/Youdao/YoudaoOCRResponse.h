//
//  YoudaoOCRResponse.h
//  Bob
//
//  Created by ripper on 2019/12/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YoudaoOCRResponseLine : NSObject

/// 原文
@property (nonatomic, copy) NSString *context;
/// 翻译结果
@property (nonatomic, copy) NSString *tranContent;

@end

@interface YoudaoOCRResponse : NSObject

/// 错误码
@property (nonatomic, copy) NSString *errorCode;
/// ocr所识别出来认为的图片中的语言
@property (nonatomic, copy) NSString *lanFrom;
/// 目标语言
@property (nonatomic, copy) NSString *lanTo;
///图片翻译的具体内容
//@property (nonatomic, strong) NSArray<YoudaoOCRResponseLine *> *resRegions;
/// 图片翻译的具体内容
@property (nonatomic, strong) NSArray<YoudaoOCRResponseLine *> *lines;

@end

NS_ASSUME_NONNULL_END
