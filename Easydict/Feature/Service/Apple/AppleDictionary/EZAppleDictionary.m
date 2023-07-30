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
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:NO from:from to:to completion:completion]) {
        return;
    }
    
    NSString *htmlString = [self getHTMLOfText:text languages:@[from, to]];
    self.result.HTMLString = htmlString;
    
    if (htmlString.length == 0) {
        self.result.noResultsFound = YES;
        self.result.errorType = EZErrorTypeNoResultsFound;
    }
    
    completion(self.result, nil);
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"Apple Dictionary not support ocr");
}

#pragma mark -

- (NSString *)getHTMLOfText:(NSString *)text languages:(NSArray<EZLanguage> *)languages {
    NSMutableString *htmlString = [NSMutableString string];;
    
    NSSet *availableDictionaries =  [TTTDictionary availableDictionaries];
    for (TTTDictionary *dictionary in availableDictionaries) {
        NSLog(@"dictionary: %@ (%@)", dictionary.name, dictionary.shortName);
    }
    
    /**
     // Simplified Chinese
     NSString * const DCSSimplifiedChinese_EnglishDictionaryName = @"牛津英汉汉英词典"; // 简体中文-英文
     NSString * const DCSSimplifiedChineseDictionaryName = @"现代汉语规范词典"; // 简体中文
     NSString * const DCSSimplifiedChineseIdiomDictionaryName = @"汉语成语词典"; // 简体中文成语
     NSString * const DCSSimplifiedChineseThesaurusDictionaryName = @"现代汉语同义词典"; // 简体中文同义词词典
     NSString * const DCSSimplifiedChinese_DictionaryName = @"超級クラウン中日辞典 / クラウン日中辞典"; // 简体中文-日文

     // Traditional Chinese
     NSString * const DCSTraditionalChineseDictionaryName = @"五南國語活用辭典"; // 繁体中文
     NSString * const DCSTraditionalChineseHongkongDictionaryName = @"商務新詞典（全新版）"; // 繁体中文（香港）
     NSString * const DCSTraditionalChinese_EnglishDictionaryName = @"譯典通英漢雙向字典"; // 繁体中文-英文
     NSString * const DCSTraditionalChinese_EnglishIdiomDictionaryName = @"漢英對照成語詞典"; // 繁体中文-英文习语

     // English
     NSString * const DCSNewOxfordAmericanDictionaryName = @"New Oxford American Dictionary"; // 美式英文
     NSString * const DCSOxfordAmericanWritersThesaurus = @"Oxford American Writer’s Thesaurus"; // 美式英文同义词词典
     NSString * const DCSOxfordDictionaryOfEnglish = @"Oxford Dictionary of English"; // 英式英文
     NSString * const DCSOxfordThesaurusOfEnglish = @"Oxford Thesaurus of English"; // 英式英文同义词词典

     // Japanese
     NSString * const DCSJapaneseSupaDaijirinDictionaryName = @"スーパー大辞林"; // 日文
     NSString * const DCSJapanese_EnglishDictionaryName = @"ウィズダム英和辞典 / ウィズダム和英辞典"; // 日文-英文

     NSString * const DCSWikipediaDictionaryName = @"维基百科";
     NSString * const DCSAppleDictionaryName = @"Apple 词典";
     */
    NSMutableArray *queryDictNames = @[
        DCSSimplifiedChinese_EnglishDictionaryName, // 牛津英汉汉英词典
        DCSSimplifiedChineseDictionaryName, // 现代汉语规范词典
        DCSSimplifiedChineseIdiomDictionaryName, // 汉语成语词典
        DCSSimplifiedChineseThesaurusDictionaryName, // 现代汉语同义词典
        
        DCSTraditionalChineseDictionaryName,
        DCSTraditionalChineseHongkongDictionaryName,
        
        DCSNewOxfordAmericanDictionaryName,
        DCSOxfordAmericanWritersThesaurus,
        
        DCSWikipediaDictionaryName,
        DCSAppleDictionaryName,
    ].mutableCopy;
    
    if ([languages containsObject:EZLanguageTraditionalChinese]) {
        [queryDictNames addObjectsFromArray:@[
            DCSTraditionalChinese_EnglishDictionaryName,
            DCSTraditionalChinese_EnglishIdiomDictionaryName,
        ]];
    }
    
    NSMutableArray<TTTDictionary *> *dicts = [NSMutableArray array];
    for (NSString *name in queryDictNames) {
        TTTDictionary *dict = [TTTDictionary dictionaryNamed:name];
        if (dict) {
            [dicts addObject:dict];
        }
    }
    
    NSString *lightSeparatorColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextLightColor]];
    NSString *darkSeparatorColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextDarkColor]];

    NSString *cssStyle = [NSString stringWithFormat:@"<style>"
                         @"h1 { font-weight: 500; font-size: 22px; margin: 0; text-align: center; }"
                         @"h1::before, h1::after { content: ''; flex: 1; border-top: 1px solid black; margin: 0 2px; }"
                         @".separator { display: flex; align-items: center; }"
                         @".separator::before, .separator::after { content: ''; flex: 1; border-top: 1px solid %@; }"
                         @".separator::before { margin-right: 2px; }"
                         @".separator::after { margin-left: 2px; }"
                         @"p { margin-bottom: 40px; }"
                         @"@media (prefers-color-scheme: dark) {"
                         @".separator::before, .separator::after { border-top-color: %@; }"
                         @"}"
                         @"</style>", lightSeparatorColorString, darkSeparatorColorString];

    
    for (TTTDictionary *dictionary in dicts) {
        NSString *dictName = [NSString stringWithFormat:@"%@", dictionary.shortName ?: dictionary.name];
        // 使用 <div> 标签包装标题和分割线的内容
        NSString *titleHtml = [NSString stringWithFormat:@"<div class=\"separator\"><h1>%@</h1></div>", dictName];
        
        for (TTTDictionaryEntry *entry in [dictionary entriesForSearchTerm:text]) {
            NSString *html = entry.HTMLWithAppCSS;
            NSString *headword = entry.headword;
            
            // LOG --> log,  根据 genju--> 根据  gēnjù
            BOOL isTheSameHeadword = [self containsSubstring:text inString:headword];
            
            if (html.length && isTheSameHeadword) {
                // Add cssStyle and titleHtml when there is a html result, and only add once.

                [htmlString appendString:cssStyle];
                cssStyle = @"";
                
                [htmlString appendString:titleHtml];
                titleHtml = @"";

                [htmlString appendFormat:@"<p>%@</p>", html];
            }
        }
    }
        
    return htmlString;
}

- (BOOL)containsSubstring:(NSString *)substring inString:(NSString *)string {
    NSStringCompareOptions options = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    
    // 将文本和子字符串转换为不区分大小写和重音的标准化字符串
    NSString *normalizedString = [string stringByFoldingWithOptions:options locale:[NSLocale currentLocale]];
    NSString *normalizedSubstring = [substring stringByFoldingWithOptions:options locale:[NSLocale currentLocale]];
    
    // 使用范围搜索方法检查标准化后的字符串是否包含标准化后的子字符串
    NSRange range = [normalizedString rangeOfString:normalizedSubstring options:NSLiteralSearch];
    return range.location != NSNotFound;
}

@end
