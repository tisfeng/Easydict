//
//  EZYoudaoOCRResponse.h
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface EZYoudaoOCRResponseLine : NSObject

/// 原文
@property (nonatomic, copy) NSString *context;
/// 翻译结果
@property (nonatomic, copy) NSString *tranContent;

@end


@interface EZYoudaoOCRResponse : NSObject

/// 错误码
@property (nonatomic, copy) NSString *errorCode;
/// ocr所识别出来认为的图片中的语言
@property (nonatomic, copy) NSString *lanFrom;
/// 目标语言
@property (nonatomic, copy) NSString *lanTo;
///图片翻译的具体内容
//@property (nonatomic, strong) NSArray<YoudaoOCRResponseLine *> *resRegions;
/// 图片翻译的具体内容
@property (nonatomic, strong) NSArray<EZYoudaoOCRResponseLine *> *lines;

@end

NS_ASSUME_NONNULL_END
