//
//  EZDeppLTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZDeppLTranslate.h"
#import "EZWebViewTranslator.h"
#import "EZTranslateError.h"
#import "EZQueryResult+EZDeepLTranslateResponse.h"

static NSString *kDeepLTranslateURL = @"https://www.deepl.com/translator";

@interface EZDeppLTranslate ()

@property (nonatomic, strong) EZWebViewTranslator *webViewTranslator;

@end

@implementation EZDeppLTranslate

- (instancetype)init {
    if (self = [super init]) {
        //        [self.webViewTranslator preloadURL:kDeepLTranslateURL]; // Preload webView.
    }
    return self;
}

- (EZWebViewTranslator *)webViewTranslator {
    if (!_webViewTranslator) {
        NSString *selector = @"#target-dummydiv";
        _webViewTranslator = [[EZWebViewTranslator alloc] init];
        _webViewTranslator.querySelector = selector;
        _webViewTranslator.queryModel = self.queryModel;
    }
    return _webViewTranslator;
}


#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeDeepL;
}

- (NSString *)name {
    return NSLocalizedString(@"deepL_translate", nil);
}

- (NSString *)link {
    return kDeepLTranslateURL;
}

// https://www.deepl.com/translator#en/zh/good
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *from = [self languageCodeForLanguage:queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:queryModel.queryTargetLanguage];
    NSString *text = [queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    if (!from || !to) {
        return nil;
    }

    return [NSString stringWithFormat:@"%@#%@/%@/%@", kDeepLTranslateURL, from, to, text];
}

// Supported languages: https://www.deepl.com/zh/docs-api/translate-text/
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                                                        EZLanguageAuto, @"auto",
                                                                        EZLanguageSimplifiedChinese, @"zh",
                                                                        EZLanguageEnglish, @"en",
                                                                        EZLanguageJapanese, @"ja",
                                                                        EZLanguageKorean, @"ko",
                                                                        EZLanguageFrench, @"fr",
                                                                        EZLanguageSpanish, @"es",
                                                                        EZLanguagePortuguese, @"pt",
                                                                        EZLanguageItalian, @"it",
                                                                        EZLanguageGerman, @"de",
                                                                        EZLanguageRussian, @"ru",
                                                                        EZLanguageSwedish, @"sv",
                                                                        EZLanguageRomanian, @"ro",
                                                                        EZLanguageSlovak, @"sk",
                                                                        EZLanguageDutch, @"nl",
                                                                        EZLanguageHungarian, @"hu",
                                                                        EZLanguageGreek, @"el",
                                                                        EZLanguageDanish, @"da",
                                                                        EZLanguageFinnish, @"fi",
                                                                        EZLanguagePolish, @"pl",
                                                                        EZLanguageCzech, @"cs",
                                                                        EZLanguageTurkish, @"tr",
                                                                        EZLanguageLithuanian, @"lt",
                                                                        EZLanguageLatvian, @"lv",
                                                                        EZLanguageUkrainian, @"uk",
                                                                        EZLanguageBulgarian, @"bg",
                                                                        EZLanguageIndonesian, @"id",
                                                                        EZLanguageSlovenian, @"sl",
                                                                        EZLanguageEstonian, @"et",
                                                                        EZLanguageNorwegian, @"nb",
                                                                        nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSArray *languages = @[ from, to ];
    if ([EZLanguageManager onlyContainsChineseLanguages:languages]) {
        [super translate:text from:from to:to completion:completion];
        return;
    }

    [self deepLWebTranslate:text from:from to:to completion:completion];
    //    [self webViewTranslate:completion];
}

- (void)webViewTranslate:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSString *wordLink = [self wordLink:self.queryModel];

    // Since DeepL doesn't support zh-TW, we need to convert zh-TW to zh-CN.
    if ([self.queryModel.queryFromLanguage isEqualToString:EZLanguageTraditionalChinese] &&
        ![EZLanguageManager isChineseLanguage:self.queryModel.queryTargetLanguage]) {
        EZQueryModel *queryModel = [self.queryModel copy];
        queryModel.userSourceLanguage = EZLanguageSimplifiedChinese;
        wordLink = [self wordLink:queryModel];
    }

    if ([self.queryModel.queryTargetLanguage isEqualToString:EZLanguageTraditionalChinese] &&
        ![EZLanguageManager isChineseLanguage:self.queryModel.queryFromLanguage]) {
        EZQueryModel *queryModel = [self.queryModel copy];
        queryModel.userTargetLanguage = EZLanguageSimplifiedChinese;
        wordLink = [self wordLink:queryModel];
    }

    if (!wordLink) {
        completion(self.result, EZQueryUnsupportedLanguageError(self));
        return;
    }

    [self.webViewTranslator queryTranslateURL:wordLink completionHandler:^(NSArray<NSString *> *_Nonnull texts, NSError *_Nonnull error) {
        if ([self.queryModel.queryTargetLanguage isEqualToString:EZLanguageTraditionalChinese]) {
            // Convert result to traditional Chinese.
            NSMutableArray *newTexts = [NSMutableArray array];
            for (NSString *text in texts) {
                NSString *newText = [text toTraditionalChineseText];
                [newTexts addObject:newText];
            }
            texts = newTexts;
        }

        self.result.normalResults = texts;
        completion(self.result, error);
    }];

    //    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    //    NSString *monitorURL = @"https://www2.deepl.com/jsonrpc?method=LMT_handle_jobs";
    //    [self.webViewTranslator monitorBaseURLString:monitorURL
    //                                         loadURL:self.wordLink
    //                               completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
    //        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    //        NSLog(@"API deepL cost: %.1f ms", (endTime - startTime) * 1000); // cost ~2s
    //
    //        //        NSLog(@"deepL responseObject: %@", responseObject);
    //    }];
}

/// DeepL web translate
/**
 入参格式:
 {"jsonrpc":"2.0","method" : "LMT_handle_texts","id":125090001,"params":{"texts":[{"text":"You trusted all proxies, this is NOT safe. We recommend you to set a value.","requestAlternatives":3}],"splitting":"newlines","lang":{"source_lang_user_selected":"EN","target_lang":"ZH"},"timestamp":1676555144560}}

 出参格式:
{"rawData":{},"data":{"jsonrpc":"2.0","id":194187000,"result":{"texts":[{"text":"参数","alternatives":[{"text":"Params"},{"text":"参数表"},{"text":"参量"}]}],"lang":"EN","lang_is_confident":false,"detectedLanguages":{"SK":0.011904,"ZH":0.005038,"unsupported":0.505983,"PT":0.040255,"PL":0.020479,"SL":0.024711999999999994,"DE":0.02167,"RO":0.013807,"ES":0.016012,"TR":0.027060000000000008,"NB":0.022891,"ET":0.016899,"EL":0.001863,"FI":0.016634,"SV":0.030546,"FR":0.017381,"NL":0.022213,"HU":0.017405,"CS":0.014604000000000002,"EN":0.037805,"DA":0.013585999999999997,"IT":0.024718,"JA":0.0064249999999999976,"BG":0.002212,"LT":0.023487,"ID":0.012715,"UK":0.001442,"KO":0.001697,"RU":0.004128,"LV":0.024428}}}

var config = require('./config.js');
var utils = require('./utils.js');

// 入参格式:
// {"jsonrpc":"2.0","method" : "LMT_handle_texts","id":125090001,"params":{"texts":[{"text":"You trusted all proxies, this is NOT safe. We recommend you to set a value.","requestAlternatives":3}],"splitting":"newlines","lang":{"source_lang_user_selected":"EN","target_lang":"ZH"},"timestamp":1676555144560}}
// 出参格式:
// {"rawData":{},"data":{"jsonrpc":"2.0","id":194187000,"result":{"texts":[{"text":"参数","alternatives":[{"text":"Params"},{"text":"参数表"},{"text":"参量"}]}],"lang":"EN","lang_is_confident":false,"detectedLanguages":{"SK":0.011904,"ZH":0.005038,"unsupported":0.505983,"PT":0.040255,"PL":0.020479,"SL":0.024711999999999994,"DE":0.02167,"RO":0.013807,"ES":0.016012,"TR":0.027060000000000008,"NB":0.022891,"ET":0.016899,"EL":0.001863,"FI":0.016634,"SV":0.030546,"FR":0.017381,"NL":0.022213,"HU":0.017405,"CS":0.014604000000000002,"EN":0.037805,"DA":0.013585999999999997,"IT":0.024718,"JA":0.0064249999999999976,"BG":0.002212,"LT":0.023487,"ID":0.012715,"UK":0.001442,"KO":0.001697,"RU":0.004128,"LV":0.024428}}}

function init_data(source_lang, target_lang) {
  return {
    jsonrpc: '2.0',
    method: 'LMT_handle_texts',
    params: {
      splitting: 'newlines',
      lang: {
        source_lang_user_selected: source_lang,
        target_lang: target_lang
      }
    }
  };
}

function get_i_count(translate_text) {
  return translate_text.split('i').length - 1;
}

function getRandomNumber() {
  const rand = Math.floor(Math.random() * 99999) + 100000;
  return rand * 1000;
}

function getTimeStamp(i_count) {
  const ts = Date.now();
  if (i_count !== 0) {
    i_count = i_count + 1;
    return ts - (ts % i_count) + i_count;
  } else {
    return ts;
  }
}

let id = getRandomNumber();

function supportLanguages() {
  return config.supportedLanguages.map(([standardLang]) => standardLang);
}

function translate(query, completion) {
  (async () => {
    const targetLanguage = utils.langMap.get(query.detectTo);
    const sourceLanguage = utils.langMap.get(query.detectFrom);
    if (!targetLanguage) {
      const err = new Error();
      Object.assign(err, {
        _type: 'unsupportLanguage',
        _message: '不支持该语种',
      });
      throw err;
    }
    const source_lang = sourceLanguage || 'ZH';
    const target_lang = targetLanguage || 'EN';
    const translate_text = query.text || '';
    let response;
    if (translate_text !== '') {
      const url = 'https://www2.deepl.com/jsonrpc';
      //   id = id + 1;
      id = getRandomNumber()
      const post_data = init_data(source_lang, target_lang);
      const text = {
        text: translate_text,
        requestAlternatives: 3
      };
      post_data.id = id;
      post_data.params.texts = [text];
      post_data.params.timestamp = getTimeStamp(get_i_count(translate_text));
      let post_str = JSON.stringify(post_data);
      if ((id + 5) % 29 === 0 || (id + 3) % 13 === 0) {
        post_str = post_str.replace('"method":"', '"method" : "');
      } else {
        post_str = post_str.replace('"method":"', '"method": "');
      }
      const options = {
        method: 'POST',
        url: url,
        header: { 'Content-Type': 'application/json' },
        body: $data.fromUTF8(post_str)
      };
      try {
        $http.request({
          method: "POST",
          url: url,
          header: { 'Content-Type': 'application/json' },
          body: $data.fromUTF8(post_str),
          handler: function (resp) {
            if (resp.data && resp.data.result && resp.data.result.texts && resp.data.result.texts.length) {
              completion({
                result: {
                  from: query.detectFrom,
                  to: query.detectTo,
                  toParagraphs: resp.data.result.texts[0].text.split('\n'),
                },
              });
            } else {
              const errMsg = resp.data ? JSON.stringify(resp.data) : '未知错误'
              completion({
                error: {
                  type: 'unknown',
                  message: errMsg,
                  addtion: errMsg,
                },
              });
            }
          }
        });
      }
      catch (e) {
        $log.error('接口请求错误 ==> ' + JSON.stringify(e))
        Object.assign(e, {
          _type: 'network',
          _message: '接口请求错误 - ' + JSON.stringify(e),
        });
        throw e;
      }
    }
  })().catch((err) => {
    $log.error('***********解析返回值异常==>' + JSON.stringify(err))
    completion({
      error: {
        type: err._type || 'unknown',
        message: err._message || '未知错误',
        addtion: err._addtion,
      },
    });
  });
}

exports.supportLanguages = supportLanguages;
exports.translate = translate;
 */

/// DeepL web translate. Ref: https://github.com/akl7777777/bob-plugin-akl-deepl-free-translate/blob/9d194783b3eb8b3a82f21bcfbbaf29d6b28c2761/src/main.js
- (void)deepLWebTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSString *souceLangCode = [self languageCodeForLanguage:from];
    NSString *targetLangCode = [self languageCodeForLanguage:to];

    NSString *url = @"https://www2.deepl.com/jsonrpc";
    NSInteger ID = [self getRandomNumber];
    NSInteger iCount = [self getICount:text];
    NSTimeInterval ts = [self getTimeStampWithIcount:iCount];
    NSDictionary *params = @{
        @"texts" : @[ @{@"text" : text, @"requestAlternatives" : @(3)} ],
        @"splitting" : @"newlines",
        @"lang" : @{@"source_lang_user_selected" : souceLangCode, @"target_lang" : targetLangCode},
        @"timestamp" : @(ts)
    };
    NSDictionary *postData = @{
        @"jsonrpc" : @"2.0",
        @"method" : @"LMT_handle_texts",
        @"id" : @(ID),
        @"params" : params
    };
//    NSLog(@"postData: %@", postData);
    NSString *postStr = [postData mj_JSONString];
    if ((ID + 5) % 29 == 0 || (ID + 3) % 13 == 0) {
        postStr = [postStr stringByReplacingOccurrencesOfString:@"\"method\":\"" withString:@"\"method\" : \""];
    } else {
        postStr = [postStr stringByReplacingOccurrencesOfString:@"\"method\":\"" withString:@"\"method\": \""];
    }
    NSData *postDataData = [postStr dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postDataData;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    AFURLSessionManager *manager = [[AFURLSessionManager alloc] init];
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
        if (error) {
            completion(self.result, error);
            return;
        }
        
        EZDeepLTranslateResponse *deepLTranslateResponse = [EZDeepLTranslateResponse mj_objectWithKeyValues:responseObject];
        [self.result setupWithDeepLTranslateResponse:deepLTranslateResponse];
        completion(self.result, nil);
    }] resume];
}

- (NSInteger)getICount:(NSString *)translateText {
    return [[translateText componentsSeparatedByString:@"i"] count] - 1;
}

- (NSInteger)getRandomNumber {
    NSInteger rand = arc4random_uniform(89999) + 100000;
    return rand * 1000;
}

- (NSInteger)getTimeStampWithIcount:(NSInteger)iCount {
    NSInteger ts = [[NSDate date] timeIntervalSince1970] * 1000;
    if (iCount != 0) {
        iCount = iCount + 1;
        return ts - (ts % iCount) + iCount;
    } else {
        return ts;
    }
}


- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"deepL not support ocr");
}

@end
