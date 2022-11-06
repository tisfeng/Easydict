//
//  GoogleTranslate.h
//  Bob
//
//  Created by ripper on 2019/12/18.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "TranslateService.h"

/**
 * 谷歌翻译参考链接 104
 * https://translate.google.cn/
 * https://cloud.google.com/translate/?hl=zh-CN
 */


NS_ASSUME_NONNULL_BEGIN


@interface GoogleTranslate : TranslateService

/// 是否使用国内谷歌翻译
@property (nonatomic, assign) BOOL isCN;

@end

NS_ASSUME_NONNULL_END
