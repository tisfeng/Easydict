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

@interface EZAppleDictionary : EZQueryService

@property (nonatomic, copy) NSString *htmlFilePath;

- (NSArray<NSString *> *)queryEntryHTMLsOfWord:(NSString *)word
                               fromToLanguages:(nullable NSArray<EZLanguage> *)languages
                                  inDictionaryName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
