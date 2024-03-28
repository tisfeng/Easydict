//
//  EZDeepLTranslateResponse.h
//  Easydict
//
//  Created by tisfeng on 2023/2/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 {
   "id" : 138686000,
   "jsonrpc" : "2.0",
       "result" : {
     "detectedLanguages" : {
       "BG" : 0.0098619999999999992,
       "CS" : 0.014202999999999999,
       "DA" : 0.0096659999999999992,
       "DE" : 0.013184,
       "EL" : 0.0093329999999999993,
       "EN" : 0.048519,
       "ES" : 0.012492,
       "ET" : 0.015691,
       "FI" : 0.010624999999999999,
       "FR" : 0.012631,
       "HU" : 0.014985,
       "ID" : 0.013127,
       "IT" : 0.020212000000000001,
       "JA" : 0.011916,
       "KO" : 0.009533999999999999,
       "LT" : 0.013819,
       "LV" : 0.0075459999999999998,
       "NB" : 0.018696000000000001,
       "NL" : 0.022485999999999999,
       "PL" : 0.012322,
       "PT" : 0.016338999999999999,
       "RO" : 0.0093139999999999994,
       "RU" : 0.013193999999999999,
       "SK" : 0.012936,
       "SL" : 0.012615999999999999,
       "SV" : 0.011228999999999999,
       "TR" : 0.013488999999999999,
       "UK" : 0.011316,
       "unsupported" : 0.58784499999999995,
       "ZH" : 0.010874
     },
     "lang" : "EN",
     "lang_is_confident" : false,
     "texts" : [
       {
         "alternatives" : [
           {
             "text" : "不错"
           },
           {
             "text" : "好"
           },
           {
             "text" : "好的"
           }
         ],
         "text" : "很好"
       }
     ]
   }
 }

 */

@class EZDeepLTranslateResponse;
@class EZDeepLTranslateResponseResult;
@class EZDeepLTranslateResponseText;
@class EZDeepLTranslateResponseAlternative;

#pragma mark - Object interfaces

@interface EZDeepLTranslateResponse : NSObject
@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, copy) NSString *jsonrpc;
@property (nonatomic, strong) EZDeepLTranslateResponseResult *result;
@end

@interface EZDeepLTranslateResponseResult : NSObject
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *detectedLanguages;
@property (nonatomic, copy) NSString *lang;
@property (nonatomic, assign) BOOL isLangIsConfident;
@property (nonatomic, copy) NSArray<EZDeepLTranslateResponseText *> *texts;
@end

@interface EZDeepLTranslateResponseText : NSObject
@property (nonatomic, copy) NSArray<EZDeepLTranslateResponseAlternative *> *alternatives;
@property (nonatomic, copy) NSString *text;
@end

@interface EZDeepLTranslateResponseAlternative : NSObject
@property (nonatomic, copy) NSString *text;
@end


NS_ASSUME_NONNULL_END
