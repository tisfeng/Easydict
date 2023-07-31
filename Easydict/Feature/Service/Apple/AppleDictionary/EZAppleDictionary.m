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

- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    return [NSString stringWithFormat:@"dict://%@", self.queryModel.queryText];
}

- (NSString *)name {
    return NSLocalizedString(@"system_dictionary", nil);
}

- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, EZLanguageAuto,
                                        EZLanguageSimplifiedChinese, EZLanguageSimplifiedChinese,
                                        EZLanguageTraditionalChinese, EZLanguageTraditionalChinese,
                                        EZLanguageEnglish, EZLanguageEnglish,
                                        EZLanguageJapanese, EZLanguageJapanese,
                                        EZLanguageKorean, EZLanguageKorean,
                                        EZLanguageFrench, EZLanguageFrench,
                                        EZLanguageGerman, EZLanguageGerman,
                                        EZLanguageSpanish, EZLanguageSpanish,
                                        EZLanguageItalian, EZLanguageItalian,
                                        EZLanguagePortuguese, EZLanguagePortuguese,
                                        EZLanguageDutch, EZLanguageDutch,
                                        nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:NO from:from to:to completion:completion]) {
        return;
    }
    
    NSString *htmlString = [self getHTMLOfText:text languages:@[ from, to ]];
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
    //    NSSet *availableDictionaries =  [TTTDictionary availableDictionaries];
    //    NSLog(@"availableDictionaries: %@", availableDictionaries);
    
    NSMutableArray *queryDictNames = [NSMutableArray array];
    
    // Simplified Chinese
    if ([languages containsObject:EZLanguageSimplifiedChinese]) {
        [queryDictNames addObjectsFromArray:@[
            DCSSimplifiedChinese_EnglishDictionaryName, // 简体中文-英文
        ]];
        
        if ([languages containsObject:EZLanguageJapanese]) {
            [queryDictNames addObjectsFromArray:@[
                DCSSimplifiedChinese_JapaneseDictionaryName, // 简体中文-日文
            ]];
        }
    }
    
    // Traditional Chinese
    if ([languages containsObject:EZLanguageTraditionalChinese]) {
        [queryDictNames addObjectsFromArray:@[
            DCSTraditionalChineseDictionaryName,              // 繁体中文
            DCSTraditionalChineseHongkongDictionaryName,      // 繁体中文（香港）
            DCSTraditionalChinese_EnglishDictionaryName,      // 繁体中文-英文
            DCSTraditionalChinese_EnglishIdiomDictionaryName, // 繁体中文-英文习语
        ]];
    }
    
    // Japanese
    if ([languages containsObject:EZLanguageJapanese]) {
        [queryDictNames addObjectsFromArray:@[
            DCSJapanese_EnglishDictionaryName, // 日文-英文
            DCSJapaneseDictionaryName,         // 日文
        ]];
    }
    
    // French
    if ([languages containsObject:EZLanguageFrench]) {
        [queryDictNames addObjectsFromArray:@[
            DCSFrench_EnglishDictionaryName, // 法文-英文
            DCSFrenchDictionaryName,         // 法文
        ]];
    }
    
    // German
    if ([languages containsObject:EZLanguageGerman]) {
        [queryDictNames addObjectsFromArray:@[
            DCSGerman_EnglishDictionaryName, // 德文-英文
            DCSGermanDictionaryName,         // 德文
        ]];
    }
    
    // Italian
    if ([languages containsObject:EZLanguageItalian]) {
        [queryDictNames addObjectsFromArray:@[
            DCSItalian_EnglishDictionaryName, // 意大利文-英文
            DCSItalianDictionaryName,         // 意大利文
        ]];
    }
    
    // Spanish
    if ([languages containsObject:EZLanguageSpanish]) {
        [queryDictNames addObjectsFromArray:@[
            DCSSpanish_EnglishDictionaryName, // 西班牙文-英文
            DCSSpanishDictionaryName,         // 西班牙文
        ]];
    }
    
    // Portuguese
    if ([languages containsObject:EZLanguagePortuguese]) {
        [queryDictNames addObjectsFromArray:@[
            DCSPortuguese_EnglishDictionaryName, // 葡萄牙文-英文
            DCSPortugueseDictionaryName,         // 葡萄牙文
        ]];
    }
    
    // Dutch
    if ([languages containsObject:EZLanguageDutch]) {
        [queryDictNames addObjectsFromArray:@[
            DCSDutch_EnglishDictionaryName, // 荷兰文-英文
            DCSDutchDictionaryName,         // 荷兰文
        ]];
    }
    
    // Korean
    if ([languages containsObject:EZLanguageKorean]) {
        [queryDictNames addObjectsFromArray:@[
            DCSKorean_EnglishDictionaryName, // 韩文-英文
            DCSKoreanDictionaryName,         // 韩文
        ]];
    }
    
    
    // Default dicts
    [queryDictNames addObjectsFromArray:@[
        DCSSimplifiedChineseDictionaryName,          // 简体中文
        DCSSimplifiedChineseIdiomDictionaryName,     // 简体中文成语
        DCSSimplifiedChineseThesaurusDictionaryName, // 简体中文同义词词典
        
        DCSNewOxfordAmericanDictionaryName, // 美式英文
        DCSOxfordAmericanWritersThesaurus,  // 美式英文同义词词典
        
        DCSWikipediaDictionaryName, // 维基百科
        DCSAppleDictionaryName,     // Apple 词典
    ]];
    
    NSMutableArray<TTTDictionary *> *dicts = [NSMutableArray array];
    for (NSString *name in queryDictNames) {
        TTTDictionary *dict = [TTTDictionary dictionaryNamed:name];
        if (dict) {
            [dicts addObject:dict];
        }
    }
    
    NSString *lightSeparatorColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextLightColor]];
    NSString *darkSeparatorColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextDarkColor]];
    
    NSString *liteLightSeparatorColorString = @"#BDBDBD";
    NSString *liteDarkSeparatorColorString = @"#5B5A5A";
    
    NSString *customCssStyle = [NSString stringWithFormat:@"<style>"
                                @"h1 { font-weight: 700; font-size: 25px; margin-top: 25px; margin-bottom: 25px; }"
                                @"h2 { font-weight: 500; font-size: 20px; margin: 0; text-align: center; }"
                                @"h2::before, h2::after { content: ''; flex: 1; border-top: 1px solid black; margin: 0 2px; }"
                                @".separator { display: flex; align-items: center; }"
                                @".separator::before, .separator::after { content: ''; flex: 1; border-top: 1px solid %@; }"
                                @".separator::before { margin-right: 2px; }"
                                @".separator::after { margin-left: 2px; }"
                                @"p { margin-bottom: 30px; }"
                                
                                @"span.x_xo0>span.x_xoLblBlk {"
                                @"display: block;"
                                @"font-variant: small-caps;"
                                @"font-size: 90%%;"
                                @"display: block;"
                                @"padding-bottom: 0.3em;"
                                @"border-bottom: solid thin %@;"
                                @"color: -apple-system-secondary-label;"
                                @"margin-top: 2em;"
                                @"margin-bottom: 0.5em;"
                                @"}"
                                
                                @"@media (prefers-color-scheme: dark) {"
                                @".separator::before, .separator::after { border-top-color: %@; }"
                                @"span.x_xo0>span.x_xoLblBlk {"
                                @"border-bottom-color: %@;"
                                @"}"
                                @"</style>",
                                lightSeparatorColorString, liteLightSeparatorColorString,
                                darkSeparatorColorString, liteDarkSeparatorColorString];
    
    
    NSMutableString *htmlString = [NSMutableString string];
    
    NSString *bigWordHtml = [NSString stringWithFormat:@"<h1>%@</h1>", text];
    
    for (TTTDictionary *dictionary in dicts) {
        NSString *dictName = [NSString stringWithFormat:@"%@", dictionary.shortName ?: dictionary.name];
        // 使用 <div> 标签包装标题和分割线的内容
        NSString *titleHtml = [NSString stringWithFormat:@"<div class=\"separator\"><h2>%@</h2></div>", dictName];
        
        for (TTTDictionaryEntry *entry in [dictionary entriesForSearchTerm:text]) {
            NSString *html = entry.HTMLWithAppCSS;
            NSString *headword = entry.headword;
            
            // LOG --> log,  根据 genju--> 根据  gēnjù
            BOOL isTheSameHeadword = [self containsSubstring:text inString:headword];
            
            if (html.length && isTheSameHeadword) {
                // Add titleHtml when there is a html result, and only add once.
                
                [htmlString appendString:bigWordHtml];
                bigWordHtml = @"";
                
                [htmlString appendString:titleHtml];
                titleHtml = @"";
                
                [htmlString appendFormat:@"<p>%@</p>", html];
            }
        }
    }
    
    if (htmlString.length) {
        [self removeOriginBorderBottomCssStyle:htmlString];
        
        // 找到第一个 <body> 元素
        NSRange bodyRange = [htmlString rangeOfString:@"<body>"];
        
        // 在元素前面插入 CSS 样式
        [htmlString insertString:customCssStyle atIndex:bodyRange.location];
    }
    
    return htmlString;
}

- (void)removeOriginBorderBottomCssStyle:(NSMutableString *)htmlString {
    // 使用正则表达式匹配 span.x_xo0>span.x_xoLblBlk 和其后的花括号中的所有内容
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?s)span\\.x_xo0 > span\\.x_xoLblBlk\\s*\\{[^}]*border-bottom:[^}]*\\}" options:0 error:&error];
    
    if (!error) {
        [regex replaceMatchesInString:htmlString options:0 range:NSMakeRange(0, [htmlString length]) withTemplate:@""];
    } else {
        NSLog(@"Error in creating regex: %@", [error localizedDescription]);
    }
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
