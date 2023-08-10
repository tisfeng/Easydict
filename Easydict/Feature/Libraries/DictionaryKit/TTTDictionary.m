// TTTDictionary.m
//
// Copyright (c) 2014 Mattt Thompson
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "TTTDictionary.h"

#import <CoreServices/CoreServices.h>

// Simplified Chinese
NSString *const DCSSimplifiedChineseDictionaryName = @"现代汉语规范词典"; // 简体中文
NSString *const DCSSimplifiedChineseIdiomDictionaryName = @"汉语成语词典"; // 简体中文成语
NSString *const DCSSimplifiedChineseThesaurusDictionaryName = @"现代汉语同义词典"; // 简体中文同义词词典
NSString *const DCSSimplifiedChinese_EnglishDictionaryName = @"牛津英汉汉英词典"; // 简体中文-英文
NSString *const DCSSimplifiedChinese_JapaneseDictionaryName = @"超級クラウン中日辞典 / クラウン日中辞典"; // 简体中文-日文

// Traditional Chinese
NSString *const DCSTraditionalChineseDictionaryName = @"五南國語活用辭典"; // 繁体中文
NSString *const DCSTraditionalChineseHongkongDictionaryName = @"商務新詞典（全新版）"; // 繁体中文（香港）
NSString *const DCSTraditionalChinese_EnglishDictionaryName = @"譯典通英漢雙向字典"; // 繁体中文-英文
NSString *const DCSTraditionalChinese_EnglishIdiomDictionaryName = @"漢英對照成語詞典"; // 繁体中文-英文习语

// English
NSString *const DCSNewOxfordAmericanDictionaryName = @"New Oxford American Dictionary"; // 美式英文
NSString *const DCSOxfordAmericanWritersThesaurus = @"Oxford American Writer’s Thesaurus"; // 美式英文同义词词典
NSString *const DCSOxfordDictionaryOfEnglish = @"Oxford Dictionary of English"; // 英式英文
NSString *const DCSOxfordThesaurusOfEnglish = @"Oxford Thesaurus of English"; // 英式英文同义词词典

// Japanese
NSString *const DCSJapaneseDictionaryName = @"スーパー大辞林"; // 日文
NSString *const DCSJapanese_EnglishDictionaryName = @"ウィズダム英和辞典 / ウィズダム和英辞典"; // 日文-英文

// French
NSString *const DCSFrenchDictionaryName = @"Multidictionnaire de la langue française"; // 法文
NSString *const DCSFrench_EnglishDictionaryName = @"Oxford-Hachette French Dictionary"; // 法文-英文
NSString *const DCSFrench_GermanDictionaryName = @"ONS Großwörterbuch Französisch Deutsch"; // 法文-德文

// German
NSString *const DCSGermanDictionaryName = @"Duden-Wissensnetz deutsche Sprache"; // 德文
NSString *const DCSGerman_EnglishDictionaryName = @"Oxford German Dictionary"; // 德文-英文

// Italian
NSString *const DCSItalianDictionaryName = @"Dizionario italiano da un affiliato di Oxford University Press"; // 意大利文
NSString *const DCSItalian_EnglishDictionaryName = @"Oxford Paravia Il Dizionario inglese - italiano/italiano - inglese"; // 意大利文-英文

// Spanish
NSString *const DCSSpanishDictionaryName = @"Diccionario General de la Lengua Española Vox"; // 西班牙文
NSString *const DCSSpanish_EnglishDictionaryName = @"Gran Diccionario Oxford - Español-Inglés • Inglés-Español"; // 西班牙文-英文

// Portugues
NSString *const DCSPortugueseDictionaryName = @"Dicionário de Português licenciado para Oxford University Press";// 葡萄牙文
NSString *const DCSPortuguese_EnglishDictionaryName = @"Oxford Portuguese Dictionary - Português-Inglês • Inglês-Português"; // 葡萄牙文-英文

// Dutch
NSString *const DCSDutchDictionaryName = @"Prisma woordenboek Nederlands"; // 荷兰文
NSString *const DCSDutch_EnglishDictionaryName = @"Prisma Handwoordenboek Engels"; // 荷兰文-英文

// Korean
NSString *const DCSKoreanDictionaryName = @"New Ace Korean Language Dictionary"; // 韩文
NSString *const DCSKorean_EnglishDictionaryName = @"뉴에이스 영한사전 / 뉴에이스 한영사전"; // 韩文-英文

NSString *const DCSWikipediaDictionaryName = @"维基百科";
NSString *const DCSAppleDictionaryName = @"Apple 词典";

typedef NS_ENUM(NSInteger, TTTDictionaryRecordVersion) {
    TTTDictionaryVersionHTML = 0,
    TTTDictionaryVersionHTMLWithAppCSS = 1,
    TTTDictionaryVersionHTMLWithPopoverCSS = 2,
    TTTDictionaryVersionText = 3,
};

#pragma mark -

extern CFArrayRef DCSCopyAvailableDictionaries(void);
extern CFStringRef DCSDictionaryGetName(DCSDictionaryRef dictionary);
extern CFStringRef DCSDictionaryGetShortName(DCSDictionaryRef dictionary);
extern DCSDictionaryRef DCSDictionaryCreate(CFURLRef url);
extern CFArrayRef DCSCopyRecordsForSearchString(DCSDictionaryRef dictionary, CFStringRef string, void *, void *);

extern CFDictionaryRef DCSCopyDefinitionMarkup(DCSDictionaryRef dictionary, CFStringRef record);
extern CFStringRef DCSRecordCopyData(CFTypeRef record, long version);
extern CFStringRef DCSRecordCopyDataURL(CFTypeRef record);
extern CFStringRef DCSRecordGetAnchor(CFTypeRef record);
extern CFStringRef DCSRecordGetAssociatedObj(CFTypeRef record);
extern CFStringRef DCSRecordGetHeadword(CFTypeRef record);
extern CFStringRef DCSRecordGetRawHeadword(CFTypeRef record);
extern CFStringRef DCSRecordGetString(CFTypeRef record);
extern DCSDictionaryRef DCSRecordGetSubDictionary(CFTypeRef record);
extern CFStringRef DCSRecordGetTitle(CFTypeRef record);

#pragma mark -

@interface TTTDictionaryEntry ()
@property (readwrite, nonatomic, copy) NSString *headword;
@property (readwrite, nonatomic, copy) NSString *text;
@property (readwrite, nonatomic, copy) NSString *HTML;
@property (readwrite, nonatomic, copy) NSString *HTMLWithAppCSS;
@property (readwrite, nonatomic, copy) NSString *HTMLWithPopoverCSS;

@end

@implementation TTTDictionaryEntry

- (instancetype)initWithRecordRef:(CFTypeRef)record
                    dictionaryRef:(DCSDictionaryRef)dictionary
{
    self = [self init];
    if (!self && record) {
        return nil;
    }

    self.headword = (__bridge NSString *)DCSRecordGetHeadword(record);
    if (self.headword) {
        self.text = (__bridge_transfer NSString*)DCSRecordCopyData(record, TTTDictionaryVersionText);
    }
    
    self.HTML = (__bridge_transfer NSString *)DCSRecordCopyData(record, (long)TTTDictionaryVersionHTML);
    self.HTMLWithAppCSS = (__bridge_transfer NSString *)DCSRecordCopyData(record, (long)TTTDictionaryVersionHTMLWithAppCSS);
    self.HTMLWithPopoverCSS = (__bridge_transfer NSString *)DCSRecordCopyData(record, (long)TTTDictionaryVersionHTMLWithPopoverCSS);
    
    return self;
}

@end

@interface TTTDictionary ()
@property (readwrite, nonatomic, assign) DCSDictionaryRef dictionary;
@property (readwrite, nonatomic, copy) NSString *name;
@property (readwrite, nonatomic, copy) NSString *shortName;
@end

@implementation TTTDictionary

+ (NSSet<TTTDictionary *> *)availableDictionaries {
    static NSSet *_availableDictionaries = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableSet *mutableDictionaries = [NSMutableSet set];
        for (id dictionary in (__bridge_transfer NSArray *)DCSCopyAvailableDictionaries()) {
            [mutableDictionaries addObject:[[TTTDictionary alloc] initWithDictionaryRef:(__bridge DCSDictionaryRef)dictionary]];
        }

        _availableDictionaries = [NSSet setWithSet:mutableDictionaries];
    });

    return _availableDictionaries;
}

+ (instancetype)dictionaryNamed:(NSString *)name {
    static NSDictionary *_availableDictionariesKeyedByName = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *mutableAvailableDictionariesKeyedByName = [NSMutableDictionary dictionaryWithCapacity:[[self availableDictionaries] count]];
        for (TTTDictionary *dictionary in [self availableDictionaries]) {
            mutableAvailableDictionariesKeyedByName[dictionary.name] = dictionary;
        }

        _availableDictionariesKeyedByName = [NSDictionary dictionaryWithDictionary:mutableAvailableDictionariesKeyedByName];
    });

    return _availableDictionariesKeyedByName[name];
}

- (instancetype)initWithDictionaryRef:(DCSDictionaryRef)dictionary {
    self = [self init];
    if (!self || !dictionary) {
        return nil;
    }

    self.dictionary = dictionary;
    self.name = (__bridge NSString *)DCSDictionaryGetName(self.dictionary);
    self.shortName = (__bridge NSString *)DCSDictionaryGetShortName(self.dictionary);
    
    _ID = [NSUUID UUID].UUIDString;

    return self;
}

- (NSArray<TTTDictionaryEntry *> *)entriesForSearchTerm:(NSString *)term {
    CFRange termRange = DCSGetTermRangeInString(self.dictionary, (__bridge CFStringRef)term, 0);
    if (termRange.location == kCFNotFound) {
        return nil;
    }

    term = [term substringWithRange:NSMakeRange(termRange.location, termRange.length)];

    NSArray *records = (__bridge_transfer NSArray *)DCSCopyRecordsForSearchString(self.dictionary, (__bridge CFStringRef)term, NULL, NULL);
    NSMutableArray *mutableEntries = [NSMutableArray arrayWithCapacity:[records count]];
    if (records) {
        for (id record in records) {
            TTTDictionaryEntry *entry = [[TTTDictionaryEntry alloc] initWithRecordRef:(__bridge CFTypeRef)record dictionaryRef:self.dictionary];
            if (entry) {
                [mutableEntries addObject:entry];
            }
        }
    }

    return [NSArray arrayWithArray:mutableEntries];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, name: %@, shortName: %@>", NSStringFromClass([self class]), self, self.name, self.shortName];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[TTTDictionary class]]) {
        return NO;
    }

    return [self.name isEqualToString:[(TTTDictionary *)object name]];
}

- (NSUInteger)hash {
    return [self.name hash];
}

@end
