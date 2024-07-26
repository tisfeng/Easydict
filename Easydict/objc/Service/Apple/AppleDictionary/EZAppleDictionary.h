//
//  EZAppleDictionary.h
//  Easydict
//
//  Created by tisfeng on 2023/7/29.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZQueryService.h"
#import "DictionaryKit.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *EZAppleDictionaryHTMLDirectory = @"Dict HTML";
static NSString *EZAppleDictionaryHTMLDictFilePath = @"all_dict.html";

NS_SWIFT_NAME(AppleDictionary)
@interface EZAppleDictionary : EZQueryService

@property (nonatomic, copy) NSString *htmlFilePath;

@property (nonatomic, copy) NSArray<NSString *> *appleDictionaryNames;

+ (instancetype)shared;

- (instancetype)initWithDictionaryNames:(NSArray<NSString *> *)names;

- (BOOL)queryDictionaryForText:(NSString *)text language:(EZLanguage)language;

@end

NS_ASSUME_NONNULL_END
