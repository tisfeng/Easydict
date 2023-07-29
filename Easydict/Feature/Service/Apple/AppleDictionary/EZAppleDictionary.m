//
//  EZAppleDictionary.m
//  Easydict
//
//  Created by tisfeng on 2023/7/29.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZAppleDictionary.h"
#import "EZConfiguration.h"
#import "DictionaryKit.h"

@implementation EZAppleDictionary

#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeAppleDictionary;
}

- (EZQueryTextType)queryTextType {
    return EZQueryTextTypeDictionary;
}

- (EZQueryTextType)intelligentQueryTextType {
    EZQueryTextType type = [EZConfiguration.shared intelligentQueryTextTypeForServiceType:self.serviceType];
    return type;
}

- (NSString *)name {
    return NSLocalizedString(@"system_dictionary", nil);
}

- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                                                        EZLanguageAuto, @"auto",
                                                                        EZLanguageSimplifiedChinese, @"zh",
                                                                        EZLanguageTraditionalChinese, @"zh",
                                                                        EZLanguageEnglish, @"en",
                                                                        nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:YES from:from to:to completion:completion]) {
        return;
    }
    
    NSString *htmlString = @"";
    
    TTTDictionary *dictionary = [TTTDictionary dictionaryNamed:@"牛津英汉汉英词典"]; // DCSOxfordDictionaryOfEnglish
    NSLog(@"%@\n", dictionary.name);
    
    for (TTTDictionaryEntry *entry in [dictionary entriesForSearchTerm:text]) {
        NSLog(@"%@", entry.text);
        
        if (entry.HTML.length) {
            htmlString = entry.HTML;
        }
    }
    
    self.result.HTMLString = htmlString;
    
    completion(self.result, nil);
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"Apple Dictionary not support ocr");
}

@end
