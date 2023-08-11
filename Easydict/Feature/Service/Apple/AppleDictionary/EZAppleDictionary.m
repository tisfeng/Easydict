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
#import "EZWindowManager.h"

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
    return [NSString stringWithFormat:@"dict://%@", self.queryModel.queryText.encode];
}

- (NSString *)name {
    return NSLocalizedString(@"apple_dictionary", nil);
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
    
    NSString *htmlString = [self getHTMLResultOfWord:text languages:@[ from, to ]];
    self.result.HTMLString = htmlString;
    
    if (htmlString.length == 0) {
        self.result.noResultsFound = YES;
        self.result.errorType = EZErrorTypeNoResultsFound;
    }
    
    completion(self.result, nil);
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"Apple Dictionary does not support ocr");
}

#pragma mark -

/// Get HTML result of word, cost ~0.2s
- (NSString *)getHTMLResultOfWord:(NSString *)text languages:(NSArray<EZLanguage> *)languages {
    NSString *buildInDictsHtmlString = [self getBuildInDictsHTMLResultOfWord:text languages:languages];
    NSMutableString *customDictsHtmlString = [self getCustomDictsHTMLResultOfWord:text languages:languages].mutableCopy;
    
    if (!customDictsHtmlString.length) {
        return buildInDictsHtmlString;
    }
    
    if (buildInDictsHtmlString.length) {
        // html = [NSString stringWithFormat:@"<html>><body>%@%@</body></html>", buildInDictsHtmlString, iframeHtmlString];
        
        NSRange bodyRange = [customDictsHtmlString rangeOfString:@"<body>"];
        [customDictsHtmlString insertString:buildInDictsHtmlString atIndex:bodyRange.location + bodyRange.length];
        return customDictsHtmlString;
    }
    
    return customDictsHtmlString;
}

/// Get HTML result of word from cutom dictionaries.
- (NSString *)getCustomDictsHTMLResultOfWord:(NSString *)text languages:(NSArray<EZLanguage> *)languages {
    NSArray<TTTDictionary *> *dicts = [self getEnabledDictionariesOfLanguages:languages];
    
    NSString *lightBackgroundColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultViewBgLightColor]];
    NSString *lightColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextLightColor]];
    
    NSString *darkBackgroundColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultViewBgDarkColor]];
    NSString *darkColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextDarkColor]];
    
    NSString *lightSeparatorColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextLightColor]];
    NSString *darkSeparatorColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextDarkColor]];

    NSString *liteLightSeparatorColorString = @"#BDBDBD";
    NSString *liteDarkSeparatorColorString = @"#5B5A5A";
    NSString *bigWordTitleH2Class = @"big-word-title";
    NSString *dictNameClassH2Class = @"dict-name";
    NSString *customIframeContainerClass = @"custom-iframe-container";

    
    // TODO: We should update this width when resizing window frame.
    
    // FIXME: This width needs to be adjusted.
    CGFloat iframeWidth = EZWindowManager.shared.floatingWindow.width - EZHorizontalCellSpacing_12 * 2 - 2 * 2 - 25;
    
    NSString *iframeCSS = [NSString stringWithFormat:@"<style>"
                                @".%@ { margin 0px; padding: 0px; width: %fpx; border: 1px solid black; }"
                                @"</style>",
                                 customIframeContainerClass, iframeWidth];
    
    // Custom CSS styles for headings, separator, and paragraphs
    NSString *customCSS = [NSString stringWithFormat:@"<style>"
                                @"iframe { margin: 0px; }"
                                @".%@ { font-weight: 600; font-size: 25px; margin-top: 0px; margin-bottom: 10px; }"
                                @".%@ { font-weight: 500; font-size: 18px; margin: 0; text-align: center; }"
                                @".%@::before, .%@::after { content: ''; flex: 1; border-top: 1px solid black; margin: 0 2px; }"
                                @".separator { display: flex; align-items: center; }"
                                @".separator::before, .separator::after { content: ''; flex: 1; border-top: 1px solid %@; }"
                                @".separator::before { margin-right: 2px; }"
                                @".separator::after { margin-left: 2px; }"
                                
                                @".%@ { margin-top: 5px; margin-bottom: 15px; width: 100%%; }"
                           
                                @"body { color: %@; background-color: %@; }"

                                @"@media (prefers-color-scheme: dark) {"
                                @"body { color: %@; background-color: %@; }"
                                @"}"
                                @"</style>",
                                
                                bigWordTitleH2Class, dictNameClassH2Class, dictNameClassH2Class, dictNameClassH2Class, lightSeparatorColorString, customIframeContainerClass, lightColorString, lightBackgroundColorString, darkColorString, darkBackgroundColorString];
    
    NSString *adjustIframeHeight = @""
    @"function adjustIframeHeight(iframeId) {"
    @"  const iframe = document.getElementById(iframeId);"
    @"  if (iframe) {"
    @"    const contentHeight = iframe.contentWindow.document.documentElement.scrollHeight;"
    @"    const borderHeight = parseInt(getComputedStyle(iframe).borderTopWidth) * 2;"
    @"    const paddingHeight = parseInt(getComputedStyle(iframe).paddingTop) * 2;"
    @"    iframe.style.height = contentHeight + borderHeight + paddingHeight + \"px\";"
    @"  }"
    @"}";
    
//    NSString *adjustIframeHeight = @""
//      "function adjustIframeHeight(iframeId) {"
//      "    var iframe = document.getElementById(iframeId);"
//      "    if (iframe) {"
//      "        iframe.style.height = iframe.contentWindow.document.body.scrollHeight + 'px';"
//      "    }"
//      "}";
    
    NSMutableString *jsCode = [ NSMutableString stringWithFormat:@"<script>"
                               @"%@"
                               @"</script>", adjustIframeHeight];
    
    NSMutableString *iframeHtmlString = [NSMutableString string];
    

    /// !!!: Since some dict(like Collins) html set h1 { display: none; }, we try to use h2
    NSString *bigWordHtml = [NSString stringWithFormat:@"<h2 class=\"%@\">%@</h2>", bigWordTitleH2Class, text];

    for (TTTDictionary *dictionary in dicts) {
        NSMutableString *htmlString = [NSMutableString string];

        NSString *dictName = [NSString stringWithFormat:@"%@", dictionary.shortName];
        // Use <div> tag to wrap the title and separator content
        NSString *titleHtml = [NSString stringWithFormat:@"<div class=\"separator\"><h2 class=\"%@\">%@</h2></div>", dictNameClassH2Class, dictName];
        
        if (!dictionary.isBuildIn) {
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
                    
                    [htmlString appendFormat:@"%@", html];
                }
            }
        }
        
        if (htmlString.length) {
            NSString *iframeID = dictionary.ID;
            
            // Create an iframe for each HTML content
            NSString *iframeContent = [NSString stringWithFormat:@"<iframe id=\"%@\" class=\"%@\" srcdoc=\"%@%@\" onload=\"adjustIframeHeight('%@')\"></iframe>", iframeID, customIframeContainerClass, [customCSS escapedHTMLString], [htmlString escapedHTMLString], iframeID];

            [iframeHtmlString appendString:iframeContent];
        }
    }
    
    NSString *iframePage = nil;
    
    if (iframeHtmlString.length) {
        iframePage = [NSString stringWithFormat:@"<html><head>%@%@%@</head><body>%@</body></html>", customCSS, iframeCSS, jsCode, iframeHtmlString];
    }
    
    return iframePage;
}


/// Get the HTML result of the built-in dictionaries.
- (NSString *)getBuildInDictsHTMLResultOfWord:(NSString *)text languages:(NSArray<EZLanguage> *)languages {
    NSArray<TTTDictionary *> *dicts = [self getEnabledDictionariesOfLanguages:languages];
    
    NSString *lightSeparatorColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextLightColor]];
    NSString *darkSeparatorColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextDarkColor]];

    NSString *liteLightSeparatorColorString = @"#BDBDBD";
    NSString *liteDarkSeparatorColorString = @"#5B5A5A";
    NSString *bigWordTitleH2Class = @"big-word-title";
    NSString *dictNameClassH2Class = @"dict-name";
    NSString *customParagraphClass = @"custom-paragraph";

    // Custom CSS styles for headings, separator, and paragraphs
    NSString *customCssStyle = [NSString stringWithFormat:@"<style>"
                                @".%@ { font-weight: 600; font-size: 25px; margin-top: -5px; margin-bottom: 10px; }"
                                @".%@ { font-weight: 500; font-size: 18px; margin: 0; text-align: center; }"
                                @".%@::before, .%@::after { content: ''; flex: 1; border-top: 1px solid black; margin: 0 2px; }"
                                @".separator { display: flex; align-items: center; }"
                                @".separator::before, .separator::after { content: ''; flex: 1; border-top: 1px solid %@; }"
                                @".separator::before { margin-right: 2px; }"
                                @".separator::after { margin-left: 2px; }"
                                
                                @".%@ { margin-top: 5px; margin-bottom: 15px; }"
                                @"</style>",
                                
                                bigWordTitleH2Class, dictNameClassH2Class, dictNameClassH2Class, dictNameClassH2Class, lightSeparatorColorString, customParagraphClass];

    // Custom CSS styles for span.x_xo0>span.x_xoLblBlk
    NSString *replaceCssStyle = [NSString stringWithFormat:@"<style>"
                                 @"body { margin: 10px 10px;  }"
                                 @".x_xo0 .x_xoLblBlk {"
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
                                 @".separator::before, .separator::after {"
                                 @"border-top-color: %@;"
                                 @"}"
                                 @".x_xo0 .x_xoLblBlk {"
                                 @"border-bottom-color: %@;"
                                 @"}"
                                 @"@media (prefers-color-scheme: dark) {"
                                 @".separator::before, .separator::after { border-top-color: %@; }"
                                 @".x_xo0 .x_xoLblBlk {"
                                 @"border-bottom-color: %@;"
                                 @"}"
                                 @"}"
                                 @"</style>",
                                 
                                 liteLightSeparatorColorString, lightSeparatorColorString, liteDarkSeparatorColorString,
                                 darkSeparatorColorString, liteDarkSeparatorColorString];

    NSMutableString *htmlString = [NSMutableString string];

    NSString *bigWordHtml = [NSString stringWithFormat:@"<h2 class=\"%@\">%@</h2>", bigWordTitleH2Class, text];

    for (TTTDictionary *dictionary in dicts) {
        NSString *dictName = [NSString stringWithFormat:@"%@", dictionary.shortName];
        // Use <div> tag to wrap the title and separator content
        NSString *titleHtml = [NSString stringWithFormat:@"<div class=\"separator\"><h2 class=\"%@\">%@</h2></div>", dictNameClassH2Class, dictName];
        
        if (dictionary.isBuildIn) {
            for (TTTDictionaryEntry *entry in [dictionary entriesForSearchTerm:text]) {
                NSString *html = entry.HTMLWithAppCSS;
                NSString *headword = entry.headword;
                
                // LOG --> log,  根据 genju--> 根据  gēnjù
                BOOL isTheSameHeadword = [self containsSubstring:text inString:headword];
                
                if (html.length && isTheSameHeadword) {
                    // Add titleHtml when there is a html result, and only add once.
                    
                    [htmlString appendString:customCssStyle];
                    customCssStyle = @"";
                    
                    [htmlString appendString:bigWordHtml];
                    bigWordHtml = @"";
                    
                    [htmlString appendString:titleHtml];
                    titleHtml = @"";
                    
                    [htmlString appendFormat:@"<p class=\"%@\">%@</p>", customParagraphClass, html];
                }
            }
        }
    }

    if (htmlString.length) {
        // TODO: Are we really need to remove the origin border-bottom css style?
        [self removeOriginBorderBottomCssStyle:htmlString];
        
        // Find the first <body> element
        NSRange bodyRange = [htmlString rangeOfString:@"<body>"];
        
        // Replace the system's span.x_xo0>span.x_xoLblBlk style to fix the separator color issue in dark mode.
        [htmlString insertString:replaceCssStyle atIndex:bodyRange.location];
    }
    
    return htmlString;
}

- (NSArray<TTTDictionary *> *)getEnabledDictionariesOfLanguages:(NSArray<EZLanguage> *)languages {
    //    NSSet *availableDictionaries =  [TTTDictionary availableDictionaries];
    //    NSLog(@"availableDictionaries: %@", availableDictionaries);
    
    NSMutableArray *queryDictNames = [NSMutableArray arrayWithArray:@[
        
    ]];
    
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
        DCSAppleDictionaryName,     // Apple 词典
        DCSWikipediaDictionaryName, // 维基百科
        
        DCSSimplifiedChineseDictionaryName,          // 简体中文
        DCSSimplifiedChineseIdiomDictionaryName,     // 简体中文成语
        DCSSimplifiedChineseThesaurusDictionaryName, // 简体中文同义词词典
        
        DCSNewOxfordAmericanDictionaryName, // 美式英文
        DCSOxfordAmericanWritersThesaurus,  // 美式英文同义词词典
    ]];
    
    // test a dict html
    BOOL test = YES;
    if (test) {
//        [queryDictNames removeAllObjects];
        
        [queryDictNames addObjectsFromArray:@[
                        @"简明英汉字典",
                        @"柯林斯高阶英汉双解词典",
            //        @"新世纪英汉大词典",
            //        @"柯林斯高阶英汉双解学习词典",
            //        @"新世纪英汉大词典",
            //        @"有道词语辨析",
            //                    @"牛津高阶英汉双解词典（第8版）",
            //        @"牛津高阶英汉双解词典（第9版）",
            //        @"牛津高阶英汉双解词典(第10版)",
            
            DCSSimplifiedChinese_EnglishDictionaryName,
        ]];
    }
    
    NSMutableArray<TTTDictionary *> *dicts = [NSMutableArray array];
    for (NSString *name in queryDictNames) {
        TTTDictionary *dict = [TTTDictionary dictionaryNamed:name];
        if (dict) {
            [dicts addObject:dict];
        }
    }
    NSLog(@"query dicts: %@", [dicts debugDescription]);
    
    return dicts;
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
