//
//  EZNiuTransTranslateResponse.h
//  Easydict
//
//  Created by BigGuang97 on 2023/11/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class EZNiuTransTranslateResponse;

#pragma mark - Object interfaces

/**
 https://niutrans.com/documents/contents/trans_text#languageList
 
 sccuess:
 {
     from: "zh",
     to: "en",
     tgt_text: "Hello"
 }
 
 failure
 {
     "apikey" : "",
     "error_code" : "13002",
     "error_msg" : "apikey is empty",
     "from" : "en",
     "src_text" : "good",
     "to" : "zh"
 }
 */

@interface EZNiuTransTranslateResponse : NSObject

@property (nonatomic, copy) NSString *from;
@property (nonatomic, copy) NSString *to;

@property (nonatomic, copy, nullable) NSString *tgtText;

@property (nonatomic, copy, nullable) NSString *srcText;
@property (nonatomic, copy, nullable) NSString *errorMsg;
@property (nonatomic, copy, nullable) NSString *errorCode;
@property (nonatomic, copy, nullable) NSString *apikey;

@end

NS_ASSUME_NONNULL_END
