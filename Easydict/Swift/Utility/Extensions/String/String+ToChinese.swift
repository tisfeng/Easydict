//
//  String+ToChinese.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/5.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

/**
 @implementation NSString (EZChineseText)

 /// Convert Simplified Chinese to Traditional Chinese.  开门 --> 開門
 - (NSString *)toTraditionalChineseText {
     NSString *traditionalChinese = [self stringByApplyingTransform:@"Hans-Hant" reverse:NO];
     return traditionalChinese;
 }

 /// Convert Traditional Chinese to Simplified Chinese.  開門 --> 开门
 - (NSString *)toSimplifiedChineseText {
     NSString *simplifiedChinese = [self stringByApplyingTransform:@"Hant-Hans" reverse:NO];
     return simplifiedChinese;
 }

 /// Is simplified Chinese.
 /// !!!: Characters in the text must be all simplified Chinese word, otherwise it will return NO.
 - (BOOL)isSimplifiedChinese {
     /**
      We need to remove symbol characters, otherwise the result will be incorrect.

      「真个别离难，不似相逢好」--> “真个别离难，不似相逢好”
      */
     NSString *pureText = [self removeNonNormalCharacters];
     NSString *simplifiedChinese = [pureText toSimplifiedChineseText];
     if ([simplifiedChinese isEqualToString:pureText]) {
         return YES;
     }
     return NO;
 }

 @end
 */

extension String {
    /// Convert Simplified Chinese to Traditional Chinese. 开门 --> 開門
    func toTraditionalChineseText() -> String {
        applyingTransform(.init("Hans-Hant"), reverse: false) ?? self
    }

    /// Convert Traditional Chinese to Simplified Chinese. 開門 --> 开门
    func toSimplifiedChineseText() -> String {
        applyingTransform(.init("Hant-Hans"), reverse: false) ?? self
    }
}
