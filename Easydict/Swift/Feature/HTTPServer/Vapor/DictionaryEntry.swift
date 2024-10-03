//
//  DictionaryEntry.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/2.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - DictionaryEntry

/**
 @interface EZTranslateWordResult : NSObject

 /// 音标
 @property (nonatomic, copy, nullable) NSArray<EZWordPhonetic *> *phonetics;
 /// 词性词义
 @property (nonatomic, copy, nullable) NSArray<EZTranslatePart *> *parts;
 /// 其他形式
 @property (nonatomic, copy, nullable) NSArray<EZTranslateExchange *> *exchanges;
 /// 中文查词时会有，单词短语数组
 @property (nonatomic, copy, nullable) NSArray<EZTranslateSimpleWord *> *simpleWords;
 /// 标签：四级，六级，考研
 @property (nonatomic, copy, nullable) NSArray<NSString *> *tags;
 /// 词源
 @property (nonatomic, copy, nullable) NSString *etymology;
 /// 同义词
 @property (nonatomic, copy, nullable) NSArray<EZTranslatePart *> *synonyms;
 /// 反义词
 @property (nonatomic, copy, nullable) NSArray<EZTranslatePart *> *antonyms;
 /// 搭配
 @property (nonatomic, copy, nullable) NSArray<EZTranslatePart *> *collocation;

 @end

 @interface EZWordPhonetic : NSObject

 @property (nonatomic, copy) NSString *word;
 @property (nonatomic, copy) EZLanguage language;

 /// 此语种对应的音标值
 @property (nonatomic, copy, nullable) NSString *value;
 /// 此音标对应的语音地址
 @property (nonatomic, copy, nullable) NSString *speakURL;

 /// 音标类型，美/英
 @property (nonatomic, copy, nullable) NSString *name;

 // 口音，us, uk
 @property (nonatomic, copy, nullable) NSString *accent;

 @end

 @interface EZTranslatePart : NSObject

 /// 单词属性，例如 'n.'、'vi.' 等
 @property (nonatomic, copy, nullable) NSString *part;
 /// 此单词属性下单词的释义
 @property (nonatomic, strong) NSArray<NSString *> *means;

 @end

 @interface EZTranslateExchange : NSObject

 /// 形式的名字
 @property (nonatomic, copy) NSString *name;
 /// 对应形式的单词，可能是多个
 @property (nonatomic, strong) NSArray<NSString *> *words;

 @end

 @interface EZTranslateSimpleWord : NSObject

 /// 单词或短语属性
 @property (nonatomic, copy, nullable) NSString *part; // adj.
 /// 单词或短语
 @property (nonatomic, copy) NSString *word;
 /// 单词或短语意思
 @property (nonatomic, strong, nullable) NSArray<NSString *> *means; // 美好的

 @property (nonatomic, copy) NSString *meansText; // means join @"; "

 ///  move part to meansText
 @property (nonatomic, assign) BOOL showPartMeans; // adj. 美好的

 @end
 */

/// Dictionary Word Entry
struct DictionaryEntry: Codable {
    var phonetics: [WordPhonetic]?
    var parts: [WordPart]?
    var exchanges: [WordExchange]?
    var simpleWords: [SimpleWordEntry]?
    var tags: [String]?
    var etymology: String?
    var synonyms: [WordPart]?
    var antonyms: [WordPart]?
    var collocation: [WordPart]?
}

// MARK: - WordPhonetic

struct WordPhonetic: Codable {
    var word: String
    var language: String
    var value: String? // 此语种对应的音标值，例如 [ɡʊd]
    var speakURL: String?
    var accent: String? // 口音，us, uk
}

// MARK: - WordPart

struct WordPart: Codable {
    var part: String? // 单词属性，例如 'n.'、'vi.' 等
    var means: [String] // 此单词属性下单词的释义，可能有多个
}

// MARK: - WordExchange

struct WordExchange: Codable {
    var name: String // 形式的名字，例如 "过去式"、"复数" 等
    var words: [String] // 对应形式的单词，可能有多个
}

// MARK: - SimpleWordEntry

struct SimpleWordEntry: Codable {
    var part: String? // 单词或短语属性，例如 "adj."、"adv." 等
    var word: String // 单词或短语
    var means: [String]? // 单词或短语意思
}
