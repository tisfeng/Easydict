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
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] init];
    NSArray<EZLanguage> *allLanguages = [EZLanguageManager.shared allLanguages];
    for (EZLanguage language in allLanguages) {
        NSString *value = language;
        [orderedDict setObject:value forKey:language];
    }
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:NO from:from to:to completion:completion]) {
        return;
    }
    
    NSString *htmlString = [self getAllIframeHTMLResultOfWord:text languages:@[ from, to ]];
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

/// Get All iframe HTML of word from dictionaries, cost ~0.2s
/// TODO: This code is so ugly, we should refactor it, but I'am bad at HTML and CSS 🥹
- (NSString *)getAllIframeHTMLResultOfWord:(NSString *)word languages:(NSArray<EZLanguage> *)languages {
    // TODO: Maybe we should filter dicts according to languages.
    NSArray<TTTDictionary *> *dicts = [TTTDictionary activeDictionaries];
    
    NSString *lightTextColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextLightColor]];
    NSString *lightBackgroundColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultViewBgLightColor]];
    
    NSString *darkTextColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextDarkColor]];
    NSString *darkBackgroundColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultViewBgDarkColor]];
    
    NSString *lightSeparatorColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextLightColor]];
    NSString *darkSeparatorColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextDarkColor]];
    
    NSString *bigWordTitleH2Class = @"big-word-title";
    NSString *customIframeContainerClass = @"custom-iframe-container";
    
    NSString *customCSS = [NSString stringWithFormat:@"<style>"
                           @".%@ { margin-top: 0px; margin-bottom: 0px; width: 100%%; }"
                           @"body { margin: 10px; color: %@; background-color: %@; }"
                           
                           @"@media (prefers-color-scheme: dark) { "
                           @"body { color: %@; background-color: %@; }"
                           @"}"
                           @"</style>",
                           
                           customIframeContainerClass,
                           lightTextColorString, lightBackgroundColorString,
                           darkTextColorString, darkBackgroundColorString];
    
    NSString *detailsSummaryCSS = [NSString stringWithFormat:@""
                                   @"<style>"
                                   @"  details summary { font-family: 'PingFang SC'; font-weight: 400; font-size: 18px; margin: 0; text-align: center; }"
                                   @"  details summary::-webkit-details-marker { width: 10px; height: 10px; }"
                                   @"  details summary::before, "
                                   @"  details summary::after { "
                                   @"    content: \"\"; "
                                   @"    display: inline-block; "
                                   @"    width: var(--before-after-summary-width, 0px); "
                                   @"    height: 1px; "
                                   @"    background: %@; "
                                   @"    vertical-align: middle; "
                                   @"  } "
                                   @"  "
                                   @"  details[open] summary::before { "
                                   @"    margin-right: 5px; "
                                   @"  } "
                                   @"  "
                                   @"  details[open] summary::after { "
                                   @"    margin-left: 5px; "
                                   @"  } "
                                   @"  "
                                   @"  details:not([open]) summary::before { "
                                   @"    margin-right: 5px; "
                                   @"  } "
                                   @"  "
                                   @"  details:not([open]) summary::after { "
                                   @"    margin-left: 5px; "
                                   @"  } "
                                   @"  "
                                   @"  @media (prefers-color-scheme: dark) { "
                                   @"    details summary::before, "
                                   @"    details summary::after { "
                                   @"      background: %@; "
                                   @"    } "
                                   @"  } "
                                   @"</style>",
                                   
                                   lightSeparatorColorString, darkSeparatorColorString];
    
    NSMutableString *iframesHtmlString = [NSMutableString string];
    
    /// !!!: Since some dict(like Collins) html set h1 { display: none; }, we try to use h2
    NSString *bigWordHtml = [NSString stringWithFormat:@"<h2 class=\"%@\">%@</h2>", bigWordTitleH2Class, word];
    
    for (TTTDictionary *dictionary in dicts) {
        NSMutableString *wordHtmlString = [NSMutableString string];
        
        //  ~/Library/Dictionaries/Apple.dictionary/Contents/
        NSURL *contentsURL = [dictionary.dictionaryURL URLByAppendingPathComponent:@"Contents"];
        
        NSArray<TTTDictionaryEntry *> *entries = [dictionary entriesForSearchTerm:word];
        for (TTTDictionaryEntry *entry in entries) {
            NSString *html = entry.HTMLWithAppCSS;
            NSString *headword = entry.headword;
            
            // LOG --> log,  根据 genju--> 根据  gēnjù
            BOOL isTheSameHeadword = [self containsSubstring:word inString:headword];
            
            if (html.length && isTheSameHeadword) {
                // Replace source relative path with absolute path.
                NSString *contentsPath = [contentsURL.path encode];
                html = [self replacedImagePathOfHTML:html withBasePath:contentsPath];
                html = [self replacedAudioPathOfHTML:html withBasePath:contentsPath];
                
                [wordHtmlString appendString:html];
            }
        }
        
        if (wordHtmlString.length) {
            // Use -webkit-text-fill-color to render system dict.
            //            NSString *textColor = dictionary.isUserDictionary ? @"color" : @"-webkit-text-fill-color";
            
            // Update background color for dark mode
            NSString *dictBackgroundColorCSS = [NSString stringWithFormat:@"<style>"
                                                @"body { background-color: %@; }"
                                                
                                                @"@media (prefers-color-scheme: dark) {"
                                                @"body { background-color: %@; }"
                                                @"}"
                                                @"</style>",
                                                
                                                lightBackgroundColorString, darkBackgroundColorString];
            
            // Create an iframe for each HTML content
            NSString *iframeHTML = [NSString stringWithFormat:@"<iframe class=\"%@\" srcdoc=\" %@ %@ %@ \" ></iframe>", customIframeContainerClass, [customCSS escapedHTMLString], [dictBackgroundColorCSS escapedHTMLString], [wordHtmlString escapedHTMLString]];
            
            NSString *dictName = [NSString stringWithFormat:@"%@", dictionary.shortName];
            NSString *detailsSummaryHtml = [NSString stringWithFormat:@"%@<details open><summary>%@</summary> %@ </details>", bigWordHtml, dictName, iframeHTML];
            
            bigWordHtml = @"";
            
            [iframesHtmlString appendString:detailsSummaryHtml];
        }
    }
    
    // !!!: Chrome does not need, but Safari must need this meta tag, otherwise Chinese characters will be garbled.
    NSString *meta = @"<meta charset=\"UTF-8\" />";
    
    NSString *globalCSS = [NSString stringWithFormat:@"<style>"
                           @".%@ { margin: 8px 0px 5px 10px; font-weight: bold; font-size: 24px; font-family: 'PingFang SC'; }"
                           
                           @"body { margin: 0px; background-color: %@; }"
                           @".%@ { margin: 0px; padding: 0px; width: 100%%; border: 0px solid black; }"
                           
                           @"@media (prefers-color-scheme: dark) {"
                           @"body { background-color: %@; color: %@;}"
                           @"}"
                           @"</style>",
                           
                           bigWordTitleH2Class,
                           lightBackgroundColorString, customIframeContainerClass,
                           darkBackgroundColorString, darkTextColorString];
    
    // TODO: For better debug experience, we should use a local html file.
    NSMutableString *jsCode = [NSMutableString stringWithFormat:
                               @"<script>"
                               @"function calculateSummaryTextWidth(summary) {"
                               @"    const range = document.createRange();"
                               @"    range.selectNodeContents(summary);"
                               @"    const textWidth = range.getBoundingClientRect().width;"
                               @"    return textWidth;"
                               @"}"
                               
                               @"function updateDetailsSummaryLineWidth() {"
                               @"    const detailsSummaryList = document.querySelectorAll('details summary');"
                               @"    for (var i = 0; i < detailsSummaryList.length; i++) {"
                               @"        const summary = detailsSummaryList[i];"
                               @"        const summaryText = summary.innerText;"
                               @"        const computedStyle = getComputedStyle(summary);"
                               @"        const font = {"
                               @"            fontSize: computedStyle.fontSize,"
                               @"            fontWeight: computedStyle.fontWeight,"
                               @"            fontFamily: computedStyle.fontFamily,"
                               @"        };"
                               @""
                               @"        const summaryTextWidth = calculateSummaryTextWidth(summary);"
                               //  @"        console.log(`text: {${summaryText}}, width: ${summaryTextWidth}`);"
                               @""
                               @"        const detailsMargin = 10;"
                               @"        const detailsSummaryTriangleWidth = 20;"
                               @"        const detailsPadding = 10;"
                               @"        let summaryLineWidth ="
                               @"            (document.documentElement.clientWidth -"
                               @"            detailsMargin -"
                               @"            summaryTextWidth -"
                               @"            detailsSummaryTriangleWidth -"
                               @"            detailsPadding) /"
                               @"            2;"
                               @""
                               //  @"        console.log(`summaryLineWidth: ${summaryLineWidth}`);"
                               @""
                               @"        summary.style.setProperty("
                               @"            '--before-after-summary-width',"
                               @"            `${summaryLineWidth}px`"
                               @"        );"
                               @"    }"
                               @"}"
                               
                               @"function convertColorsInIframe(iframe, isDarkMode) {"
                               @"    var iframeDocument = iframe.contentWindow.document;"
                               @"    var spanElements = iframeDocument.querySelectorAll('*');"
                               @"    spanElements.forEach(function (tag) {"
                               @"        brightenColor(tag);"
                               @"        var childElements = tag.querySelectorAll('*');"
                               @"        childElements.forEach(function (child) {});"
                               @"    });"
                               @"    function brightenColor(element) {"
                               @"        var computedStyle = getComputedStyle(element);"
                               @"        var originalColor = computedStyle.color;"
                               @"        var newColor = convertColor(originalColor, isDarkMode);"
                               //                               @"        console.log("
                               //                               @"            `${"
                               //                               @"                isDarkMode ? 'dark' : 'light'"
                               //                               @"            }, originalColor: ${originalColor}, newColor: ${newColor}, innerText: ${"
                               //                               @"                element.innerText"
                               //                               @"            }`"
                               //                               @"        );"
                               @"        element.style.color = newColor;"
                               @"    }"
                               
                               @"function convertColor(colorString, isDarkMode) {"
                               @"    const rgbValues = colorString.match(/\\d+/g);"
                               @"    const r = parseInt(rgbValues[0], 10);"
                               @"    const g = parseInt(rgbValues[1], 10);"
                               @"    const b = parseInt(rgbValues[2], 10);"
                               @"    const brightness = (r + g + b) / 3;"
                               @"    let brightenAmount = 0;"
                               @"    const lowBrightnessThreshold = 40;"
                               @"    const lightLowBrightnessAmount = 255 - lowBrightnessThreshold;"
                               @"    const ratio = 0.6;"
                               @"    if (isDarkMode) {"
                               @"        if (brightness < lowBrightnessThreshold) {"
                               @"            brightenAmount = lightLowBrightnessAmount;"
                               @"        } else {"
                               @"            brightenAmount = lightLowBrightnessAmount * ratio;"
                               @"        }"
                               @"    } else {"
                               @"        if (brightness > lightLowBrightnessAmount) {"
                               @"            brightenAmount = -lightLowBrightnessAmount;"
                               @"        } else {"
                               @"            brightenAmount = -lightLowBrightnessAmount * ratio;"
                               @"        }"
                               @"    }"
                               @"    const adjustedR = Math.min(Math.max(r + brightenAmount, 0), 255);"
                               @"    const adjustedG = Math.min(Math.max(g + brightenAmount, 0), 255);"
                               @"    const adjustedB = Math.min(Math.max(b + brightenAmount, 0), 255);"
                               @"    return `rgb(${adjustedR}, ${adjustedG}, ${adjustedB})`;"
                               @"}"
                               
                               @"}"
                               @"function isDarkMode() {"
                               @"    return ("
                               @"        window.matchMedia &&"
                               @"        window.matchMedia(`(prefers-color-scheme: dark)`).matches"
                               @"    );"
                               @"}"
                               @"function updateAllIframeTextColor(isDarkMode) {"
                               @"    var iframes = document.querySelectorAll('iframe');"
                               @"    for (var i = 0; i < iframes.length; i++) {"
                               @"        var iframe = iframes[i];"
                               @"        convertColorsInIframe(iframe, isDarkMode);"
                               @"    }"
                               @"}"
                               @"function updateAllIframeHeight() {"
                               @"    var iframes = document.querySelectorAll('iframe');"
                               @"    for (var i = 0; i < iframes.length; i++) {"
                               @"        var iframe = iframes[i];"
                               @"        const contentHeight ="
                               @"            iframe.contentWindow.document.documentElement.scrollHeight;"
                               @"        const borderHeight ="
                               @"            parseInt(getComputedStyle(iframe).borderTopWidth) * 2;"
                               @"        const paddingHeight ="
                               @"            parseInt(getComputedStyle(iframe).paddingTop) * 2;"
                               @"        iframe.style.height ="
                               @"            contentHeight + borderHeight + paddingHeight + 'px';"
                               @"    }"
                               @"}"
                               @"window.onload = function () {"
                               @"    updateDetailsSummaryLineWidth();"
                               @"    updateAllIframeHeight();"
                               @"    if (isDarkMode()) {"
                               @"        updateAllIframeTextColor(true);"
                               @"    }"
                               @"    var colorSchemeListener = window.matchMedia("
                               @"        `(prefers-color-scheme: dark)`"
                               @"    );"
                               @"    colorSchemeListener.addEventListener(`change`, function (event) {"
                               @"        var isDarkMode = event.matches;"
                               //  @"        console.log(`color scheme changed: ${isDarkMode ? 'dark' : 'light'}`);"
                               @"        updateAllIframeTextColor(isDarkMode);"
                               @"    });"
                               @"};"
                               
                               
                               @"</script>"];
    
    NSString *htmlString = nil;
    
    if (iframesHtmlString.length) {
        htmlString = [NSString stringWithFormat:@"<html><head> %@ %@ %@ %@ </head> <body> %@ </body></html>",
                      meta, globalCSS, detailsSummaryCSS, jsCode, iframesHtmlString];
    }
    
    return htmlString;
}

#pragma mark -

/**
 Replace HTML all src relative path with absolute path
 
 src="us_pron.png" -->
 src="/Users/tisfeng/Library/Dictionaries/Apple%20Dictionary.dictionary/Contents/us_pron.png"
 */
- (NSString *)replacedImagePathOfHTML:(NSString *)HTML withBasePath:(NSString *)basePath {
    NSString *pattern = @"src=\"(.*?)\"";
    NSString *replacement = [NSString stringWithFormat:@"src=\"%@/$1\"", basePath];
    NSString *absolutePathHTML = [HTML stringByReplacingOccurrencesOfString:pattern
                                                                 withString:replacement
                                                                    options:NSRegularExpressionSearch
                                                                      range:NSMakeRange(0, HTML.length)];
    return absolutePathHTML;
}

/**
 Replace HTML all audio relative path with absolute path
 
 &quot; == "
 
 javascript:new Audio(&quot;uk/apple__gb_1.mp3&quot;) -->
 javascript:new Audio('/Users/tisfeng/Library/Contents/uk/apple__gb_1.mp3')
 */
- (NSString *)replacedAudioPathOfHTML:(NSString *)HTML withBasePath:(NSString *)basePath {
    NSString *pattern = @"new Audio\\(&quot;(.*?)&quot;\\)";
    NSString *replacement = [NSString stringWithFormat:@"new Audio('%@/$1')", basePath];
    NSString *absolutePathHTML = [HTML stringByReplacingOccurrencesOfString:pattern
                                                                 withString:replacement
                                                                    options:NSRegularExpressionSearch
                                                                      range:NSMakeRange(0, HTML.length)];
    return absolutePathHTML;
}

//- (NSString *)replacedAudioPathOfHTML:(NSString *)HTML withBasePath:(NSString *)basePath {
//    NSString *pattern = @"new Audio\\(&quot;(.*?)&quot;\\)";
//    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
//
//    NSMutableString *modifiedHTML = [HTML mutableCopy];
//
//    [regex enumerateMatchesInString:modifiedHTML options:0 range:NSMakeRange(0, modifiedHTML.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
//        NSRange matchRange = [result rangeAtIndex:1];
//        NSString *encodedRelativePath = [modifiedHTML substringWithRange:matchRange];
//
//        NSString *absolutePath = [basePath stringByAppendingPathComponent:encodedRelativePath];
//        NSString *replacement = [NSString stringWithFormat:@"new Audio('%@')", absolutePath];
//        [modifiedHTML replaceCharactersInRange:result.range withString:replacement];
//    }];
//
//    return [modifiedHTML copy];
//}


/// Get dict name width
- (CGFloat)getDictNameWidth:(NSString *)dictName {
    NSFont *boldPingFangFont = [NSFont fontWithName:@"PingFangSC-Regular" size:18];
    
    NSDictionary *attributes = @{NSFontAttributeName : boldPingFangFont};
    CGFloat width = [dictName sizeWithAttributes:attributes].width;
    
    width = [dictName mm_widthWithFont:boldPingFangFont];
    
    NSLog(@"%@ width: %.1f", dictName, width);
    
    return width;
}

- (NSArray<TTTDictionary *> *)getUserActiveDictionaries {
    NSArray *availableDictionaries = [TTTDictionary activeDictionaries];
    
    NSMutableArray *userDicts = [NSMutableArray array];
    
    // Add all custom dicts
    for (TTTDictionary *dictionary in availableDictionaries) {
        if (dictionary.isUserDictionary) {
            [userDicts addObject:dictionary];
        }
    }
    
    return userDicts;
}

- (NSArray<TTTDictionary *> *)getSystemActiveDictionaries {
    NSArray *activeDictionaries = [TTTDictionary activeDictionaries];
    
    NSMutableArray *systemDicts = [NSMutableArray array];
    
    // Add all system dicts
    for (TTTDictionary *dictionary in activeDictionaries) {
        if (!dictionary.isUserDictionary) {
            [systemDicts addObject:dictionary];
        }
    }
    
    return systemDicts;
}


- (NSArray<TTTDictionary *> *)getEnabledDictionariesOfLanguages:(NSArray<EZLanguage> *)languages {
    NSArray *availableDictionaries = [TTTDictionary activeDictionaries];
    NSLog(@"availableDictionaries: %@", availableDictionaries);
    
    NSMutableArray *queryDictNames = [NSMutableArray arrayWithArray:@[
        
    ]];
    
    // Add all custom dicts
    for (TTTDictionary *dictionary in availableDictionaries) {
        if (dictionary.isUserDictionary) {
            [queryDictNames addObject:dictionary];
        }
    }
    
    
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
        [queryDictNames removeAllObjects];
        
        [queryDictNames addObjectsFromArray:@[
            //            @"简明英汉字典",
            //            @"柯林斯高阶英汉双解词典",
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
        if (dict && ![dicts containsObject:dict]) {
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
