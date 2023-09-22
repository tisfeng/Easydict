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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Note: this method may cost long time(>1.0s), if the html is very large.
        NSString *htmlString = [self getAllIframeHTMLResultOfWord:text languages:@[ from, to ]];
        self.result.HTMLString = htmlString;
        
        if (htmlString.length == 0) {
            self.result.noResultsFound = YES;
            self.result.errorType = EZErrorTypeNoResultsFound;
        }
        
        completion(self.result, nil);
    });
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
    
    NSString *baseHtmlPath = [[NSBundle mainBundle] pathForResource:@"apple-dictionary" ofType:@"html"];
    NSString *baseHtmlString = [NSString stringWithContentsOfFile:baseHtmlPath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *lightTextColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextLightColor]];
    NSString *lightBackgroundColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultViewBgLightColor]];
    
//    NSString *darkTextColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextDarkColor]];
    NSString *darkBackgroundColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultViewBgDarkColor]];
    
    NSString *bigWordTitleH2Class = @"big-word-title";
    NSString *customIframeContainerClass = @"custom-iframe-container";
    
    NSString *customCSS = [NSString stringWithFormat:@"<style>"
                           @".%@ { margin-top: 0px; margin-bottom: 0px; width: 100%%; }"
                           @"body { margin: 10px; color: %@; background-color: %@; font-family: 'system-ui'; }"
                           
                           @"@media (prefers-color-scheme: dark) { "
                           @"body {"
                           @"background-color: %@;"
                           @"filter: invert(0.85) hue-rotate(185deg) saturate(200%%) brightness(120%%);"
                           @"}"
                           @"}"
                           @"</style>",
                           
                           customIframeContainerClass,
                           lightTextColorString, lightBackgroundColorString,
                           darkBackgroundColorString];
    
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
                NSString *contentsPath = contentsURL.path;
                
                // System seems to automatically adapt the image path internally.
//                html = [self replacedImagePathOfHTML:html withBasePath:contentsPath];
                
                html = [self replacedAudioPathOfHTML:html withBasePath:contentsPath];
                
                [wordHtmlString appendString:html];
            }
        }
        
        if (wordHtmlString.length) {
            // Use -webkit-text-fill-color to render system dict.
            //            NSString *textColor = dictionary.isUserDictionary ? @"color" : @"-webkit-text-fill-color";
            
            NSString *dictHTML = [NSString stringWithFormat:@"%@\n\n%@", customCSS, wordHtmlString];
            
            // Create an iframe for each HTML content
            NSString *iframeHTML = [NSString stringWithFormat:@"<iframe class=\"%@\" srcdoc=\"%@\"></iframe>", customIframeContainerClass, [dictHTML escapedXMLString]];
            
            NSString *dictName = [NSString stringWithFormat:@"%@", dictionary.shortName];
            NSString *detailsSummaryHtml = [NSString stringWithFormat:@"%@<details open><summary>%@</summary> %@ </details>", bigWordHtml, dictName, iframeHTML];
            
            bigWordHtml = @"";
            
            [iframesHtmlString appendString:detailsSummaryHtml];
            
            NSURL *dictionaryURL = [TTTDictionary userDictionaryDirectoryURL];
            NSString *htmlDirectory = [dictionaryURL URLByAppendingPathComponent:EZAppleDictionaryHTMLDirectory].path;
            // Create if not exist
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:htmlDirectory]) {
                NSError *error;
                if (![fileManager createDirectoryAtPath:htmlDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
                    NSLog(@"createDirectoryAtPath error: %@", error);
                }
            }

            NSString *htmlFilePath = [htmlDirectory stringByAppendingFormat:@"/%@.html", dictName];
            NSError *error;
            if (![dictHTML writeToFile:htmlFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
                NSLog(@"writeToFile error: %@", error);
            }
        }
    }
    
    NSString *htmlString = nil;
    if (iframesHtmlString.length) {
        // Insert iframesHtmlString <body> </body> in baseHtmlString
        htmlString = [baseHtmlString stringByReplacingOccurrencesOfString:@"</body>"
                                                               withString:[NSString stringWithFormat:@"%@ </body>", iframesHtmlString]];
        
        NSURL *dictionaryURL = [TTTDictionary userDictionaryDirectoryURL];
        NSString *htmlDirectory = [dictionaryURL URLByAppendingPathComponent:EZAppleDictionaryHTMLDirectory].path;
        NSString *htmlFilePath = [htmlDirectory stringByAppendingFormat:@"/%@", EZAppleDictionaryHTMLDictFilePath];
        self.htmlFilePath = htmlFilePath;
        [htmlString writeToFile:htmlFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
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
 
 &quot; is " in HTML
 
 javascript:new Audio(&quot;uk/apple__gb_1.mp3&quot;) -->
 javascript:new Audio('/Users/tisfeng/Library/Contents/uk/apple__gb_1.mp3')
 */
- (NSString *)replacedAudioPathOfHTML:(NSString *)HTML withBasePath:(NSString *)basePath {
    NSString *pattern = @"new Audio\\((.*?)\\)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];

    NSMutableString *mutableHTML = [HTML mutableCopy];

    [regex enumerateMatchesInString:mutableHTML options:0 range:NSMakeRange(0, mutableHTML.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        NSRange matchRange = [result rangeAtIndex:1];
        NSString *filePath = [mutableHTML substringWithRange:matchRange];
        NSString *relativePath = [filePath stringByReplacingOccurrencesOfString:@"&quot;" withString:@""];

        NSString *fileBasePath = basePath;

        NSArray *array = [relativePath componentsSeparatedByString:@"/"];
        BOOL isDirectoryPath = array.count > 1;
        if (isDirectoryPath) {
            NSString *directoryName = array.firstObject;
            NSString *directoryPath = [self findFilePathInDirectory:basePath withTargetDirectory:directoryName];
            fileBasePath = [directoryPath stringByDeletingLastPathComponent];
        }
        
        NSString *absolutePath = [fileBasePath stringByAppendingPathComponent:relativePath];
        NSString *replacement = [NSString stringWithFormat:@"new Audio('%@')", absolutePath];
        [mutableHTML replaceCharactersInRange:result.range withString:replacement];
    }];

    return [mutableHTML copy];
}


/// Find file path in directory.
- (NSString *)findFilePathInDirectory:(NSString *)directoryPath withTargetDirectory:(NSString *)targetDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) {
        NSLog(@"Error reading directory: %@", error);
        return nil;
    }
        
    for (NSString *content in contents) {
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:content];
        
        BOOL isDirectory;
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        
        if (isDirectory) {
            if ([content isEqualToString:targetDirectory]) {
                return fullPath;
            }
            
            NSString *subDirectoryPath = [self findFilePathInDirectory:fullPath withTargetDirectory:targetDirectory];
            if (subDirectoryPath) {
                return subDirectoryPath;
            }
        }
    }
    
    return nil;
}


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
    
    BOOL isContained = [normalizedString containsString:normalizedSubstring];
    //    isContain = [normalizedString isEqualToString:normalizedSubstring];
    
    /**
     Since some user dict word result is too redundant, we need to remove some useless words.
     
     Such as 简明英汉词典, when look up "log", the results are: -log, log-, log, we should filter the first two.
     */
    
    if (isContained) {
        // remove substring
        NSString *remainedText = [normalizedString stringByReplacingOccurrencesOfString:normalizedSubstring withString:@""];
        if ([remainedText isEqualToString:@"-"]) {
            isContained = NO;
        }
    }
    
    return isContained;
}

@end
