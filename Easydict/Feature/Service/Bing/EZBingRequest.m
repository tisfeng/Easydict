//
//  EZBingRequest.m
//  Easydict
//
//  Created by choykarl on 2023/8/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZBingRequest.h"
#import "EZError.h"
#import "EZBingLanguageVoice.h"
#import "NSString+EZRegex.h"

static NSString *const kAudioMIMEType = @"audio/mpeg";
static NSString *const kBingConfigKey = @"kBingConfigKey";

@interface EZBingRequest ()
@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) AFHTTPSessionManager *translateSession;
@property (nonatomic, strong) AFHTTPSessionManager *ttsSession;
@property (nonatomic, strong) AFHTTPSessionManager *dictTranslateSession;
@property (nonatomic, strong) NSData *translateData;
@property (nonatomic, strong) NSData *lookupData;
@property (nonatomic, strong) NSError *translateError;
@property (nonatomic, strong) NSError *lookupError;
@property (nonatomic, assign) NSInteger responseCount;

@property (nonatomic, copy) NSString *from;
@property (nonatomic, copy) NSString *to;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) BingTranslateCompletion completion;

@property (nonatomic, assign) BOOL canRetryFetchHost;

@property (nonatomic, strong) MMOrderedDictionary<EZLanguage, EZBingLanguageVoice *> *langaugeVoices;

@end

@implementation EZBingRequest

- (instancetype)init {
    if (self = [super init]) {
        _canRetryFetchHost = YES;
        
        [self fetchBingHost:^{
            [self fetchBingConfig:^{
                
            } failure:^(NSError *error) {
                
            }];
        }];
    }
    return self;
}

- (EZBingConfig *)bingConfig {
    if (!_bingConfig) {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kBingConfigKey];
        EZBingConfig *bingConfig = [EZBingConfig mj_objectWithKeyValues:dict];
        if (!bingConfig) {
            bingConfig = [[EZBingConfig alloc] init];
        }
        _bingConfig = bingConfig;
    }
    
    return _bingConfig;
}

- (void)saveBingConfig {
    NSDictionary *dict = [self.bingConfig mj_keyValues];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kBingConfigKey];
}


+ (MMOrderedDictionary<EZLanguage, EZBingLanguageVoice *> *)langaugeVoices {
    static MMOrderedDictionary *allLanguageVoices;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allLanguageVoices = [[MMOrderedDictionary alloc] init];
        
        // Docs: https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/language-support?tabs=tts
        EZBingLanguageVoice *simplifiedChineseVoice = [EZBingLanguageVoice voiceWithLanguage:@"zh-CN" voiceName:@"zh-CN-XiaoxiaoNeural"];
        [allLanguageVoices setObject:simplifiedChineseVoice forKey:EZLanguageSimplifiedChinese];
        
        EZBingLanguageVoice *traditionalChineseVoice = [EZBingLanguageVoice voiceWithLanguage:@"zh-TW" voiceName:@"zh-TW-HsiaoChenNeural"];
        [allLanguageVoices setObject:traditionalChineseVoice forKey:EZLanguageTraditionalChinese];
        
        EZBingLanguageVoice *englishVoice = [EZBingLanguageVoice voiceWithLanguage:@"en-US" voiceName:@"en-US-JennyNeural"];
        [allLanguageVoices setObject:englishVoice forKey:EZLanguageEnglish];
        
        EZBingLanguageVoice *japaneseVoice = [EZBingLanguageVoice voiceWithLanguage:@"ja-JP" voiceName:@"ja-JP-NanamiNeural"];
        [allLanguageVoices setObject:japaneseVoice forKey:EZLanguageJapanese];
        
        EZBingLanguageVoice *koreanVoice = [EZBingLanguageVoice voiceWithLanguage:@"ko-KR" voiceName:@"ko-KR-SunHiNeural"];
        [allLanguageVoices setObject:koreanVoice forKey:EZLanguageKorean];
        
        EZBingLanguageVoice *frenchVoice = [EZBingLanguageVoice voiceWithLanguage:@"fr-FR" voiceName:@"fr-FR-DeniseNeural"];
        [allLanguageVoices setObject:frenchVoice forKey:EZLanguageFrench];
        
        EZBingLanguageVoice *spanishVoice = [EZBingLanguageVoice voiceWithLanguage:@"es-ES" voiceName:@"es-ES-ElviraNeural"];
        [allLanguageVoices setObject:spanishVoice forKey:EZLanguageSpanish];
        
        EZBingLanguageVoice *portugueseVoice = [EZBingLanguageVoice voiceWithLanguage:@"pt-PT" voiceName:@"pt-PT-RaquelNeural"];
        [allLanguageVoices setObject:portugueseVoice forKey:EZLanguagePortuguese];
        
        EZBingLanguageVoice *italianVoice = [EZBingLanguageVoice voiceWithLanguage:@"it-IT" voiceName:@"it-IT-ElsaNeural"];
        [allLanguageVoices setObject:italianVoice forKey:EZLanguageItalian];
        
        EZBingLanguageVoice *germanVoice = [EZBingLanguageVoice voiceWithLanguage:@"de-DE" voiceName:@"de-DE-KatjaNeural"];
        [allLanguageVoices setObject:germanVoice forKey:EZLanguageGerman];
        
        EZBingLanguageVoice *russianVoice = [EZBingLanguageVoice voiceWithLanguage:@"ru-RU" voiceName:@"ru-RU-SvetlanaNeural"];
        [allLanguageVoices setObject:russianVoice forKey:EZLanguageRussian];
        
        EZBingLanguageVoice *arabicVoice = [EZBingLanguageVoice voiceWithLanguage:@"ar-EG" voiceName:@"ar-EG-SalmaNeural"];
        [allLanguageVoices setObject:arabicVoice forKey:EZLanguageArabic];
        
        EZBingLanguageVoice *swedishVoice = [EZBingLanguageVoice voiceWithLanguage:@"sv-SE" voiceName:@"sv-SE-HedvigNeural"];
        [allLanguageVoices setObject:swedishVoice forKey:EZLanguageSwedish];
        
        EZBingLanguageVoice *romanianVoice = [EZBingLanguageVoice voiceWithLanguage:@"ro-RO" voiceName:@"ro-RO-AlinaNeural"];
        [allLanguageVoices setObject:romanianVoice forKey:EZLanguageRomanian];
        
        EZBingLanguageVoice *thaiVoice = [EZBingLanguageVoice voiceWithLanguage:@"th-TH" voiceName:@"th-TH-PremwadeeNeural"];
        [allLanguageVoices setObject:thaiVoice forKey:EZLanguageThai];
        
        EZBingLanguageVoice *slovakVoice = [EZBingLanguageVoice voiceWithLanguage:@"sk-SK" voiceName:@"sk-SK-ViktoriaNeural"];
        [allLanguageVoices setObject:slovakVoice forKey:EZLanguageSlovak];
        
        EZBingLanguageVoice *dutchVoice = [EZBingLanguageVoice voiceWithLanguage:@"nl-NL" voiceName:@"nl-NL-ColetteNeural"];
        [allLanguageVoices setObject:dutchVoice forKey:EZLanguageDutch];
        
        EZBingLanguageVoice *czechVoice = [EZBingLanguageVoice voiceWithLanguage:@"cs-CZ" voiceName:@"cs-CZ-AntoninNeural"];
        [allLanguageVoices setObject:czechVoice forKey:EZLanguageCzech];
        
        EZBingLanguageVoice *turkishVoice = [EZBingLanguageVoice voiceWithLanguage:@"tr-TR" voiceName:@"tr-TR-EmelNeural"];
        [allLanguageVoices setObject:turkishVoice forKey:EZLanguageTurkish];
        
        EZBingLanguageVoice *greekVoice = [EZBingLanguageVoice voiceWithLanguage:@"el-GR" voiceName:@"el-GR-AthinaNeural"];
        [allLanguageVoices setObject:greekVoice forKey:EZLanguageGreek];
        
        EZBingLanguageVoice *danishVoice = [EZBingLanguageVoice voiceWithLanguage:@"da-DK" voiceName:@"da-DK-ChristelNeural"];
        [allLanguageVoices setObject:danishVoice forKey:EZLanguageDanish];
        
        EZBingLanguageVoice *finnishVoice = [EZBingLanguageVoice voiceWithLanguage:@"fi-FI" voiceName:@"fi-FI-NooraNeural"];
        [allLanguageVoices setObject:finnishVoice forKey:EZLanguageFinnish];
        
        EZBingLanguageVoice *polishVoice = [EZBingLanguageVoice voiceWithLanguage:@"pl-PL" voiceName:@"pl-PL-AgnieszkaNeural"];
        [allLanguageVoices setObject:polishVoice forKey:EZLanguagePolish];
        
        EZBingLanguageVoice *lithuanianVoice = [EZBingLanguageVoice voiceWithLanguage:@"lt-LT" voiceName:@"lt-LT-OnaNeural"];
        [allLanguageVoices setObject:lithuanianVoice forKey:EZLanguageLithuanian];
        
        EZBingLanguageVoice *latvianVoice = [EZBingLanguageVoice voiceWithLanguage:@"lv-LV" voiceName:@"lv-LV-EveritaNeural"];
        [allLanguageVoices setObject:latvianVoice forKey:EZLanguageLatvian];
        
        EZBingLanguageVoice *ukrainianVoice = [EZBingLanguageVoice voiceWithLanguage:@"uk-UA" voiceName:@"uk-UA-OstapNeural"];
        [allLanguageVoices setObject:ukrainianVoice forKey:EZLanguageUkrainian];
        
        EZBingLanguageVoice *bulgarianVoice = [EZBingLanguageVoice voiceWithLanguage:@"bg-BG" voiceName:@"bg-BG-KalinaNeural"];
        [allLanguageVoices setObject:bulgarianVoice forKey:EZLanguageBulgarian];
        
        EZBingLanguageVoice *indonesianVoice = [EZBingLanguageVoice voiceWithLanguage:@"id-ID" voiceName:@"id-ID-DamayantiNeural"];
        [allLanguageVoices setObject:indonesianVoice forKey:EZLanguageIndonesian];
        
        EZBingLanguageVoice *malayVoice = [EZBingLanguageVoice voiceWithLanguage:@"ms-MY" voiceName:@"ms-MY-OsmanNeural"];
        [allLanguageVoices setObject:malayVoice forKey:EZLanguageMalay];
        
        EZBingLanguageVoice *slovenianVoice = [EZBingLanguageVoice voiceWithLanguage:@"sl-SI" voiceName:@"sl-SI-PetraNeural"];
        [allLanguageVoices setObject:slovenianVoice forKey:EZLanguageSlovenian];
        
        EZBingLanguageVoice *estonianVoice = [EZBingLanguageVoice voiceWithLanguage:@"et-EE" voiceName:@"et-EE-AnuNeural"];
        [allLanguageVoices setObject:estonianVoice forKey:EZLanguageEstonian];
        
        EZBingLanguageVoice *vietnameseVoice = [EZBingLanguageVoice voiceWithLanguage:@"vi-VN" voiceName:@"vi-VN-HoaiMyNeural"];
        [allLanguageVoices setObject:vietnameseVoice forKey:EZLanguageVietnamese];
        
        EZBingLanguageVoice *persianVoice = [EZBingLanguageVoice voiceWithLanguage:@"fa-IR" voiceName:@"fa-IR-SimaNeural"];
        [allLanguageVoices setObject:persianVoice forKey:EZLanguagePersian];
        
        EZBingLanguageVoice *hindiVoice = [EZBingLanguageVoice voiceWithLanguage:@"hi-IN" voiceName:@"hi-IN-MadhurNeural"];
        [allLanguageVoices setObject:hindiVoice forKey:EZLanguageHindi];
        
        EZBingLanguageVoice *teluguVoice = [EZBingLanguageVoice voiceWithLanguage:@"te-IN" voiceName:@"te-IN-MohanNeural"];
        [allLanguageVoices setObject:teluguVoice forKey:EZLanguageTelugu];
        
        EZBingLanguageVoice *tamilVoice = [EZBingLanguageVoice voiceWithLanguage:@"ta-IN" voiceName:@"ta-IN-PallaviNeural"];
        [allLanguageVoices setObject:tamilVoice forKey:EZLanguageTamil];
        
        EZBingLanguageVoice *urduVoice = [EZBingLanguageVoice voiceWithLanguage:@"ur-PK" voiceName:@"ur-PK-AsadNeural"];
        [allLanguageVoices setObject:urduVoice forKey:EZLanguageUrdu];
        
        EZBingLanguageVoice *filipinoVoice = [EZBingLanguageVoice voiceWithLanguage:@"fil-PH" voiceName:@"fil-PH-AlingNeural"];
        [allLanguageVoices setObject:filipinoVoice forKey:EZLanguageFilipino];
        
        EZBingLanguageVoice *khmerVoice = [EZBingLanguageVoice voiceWithLanguage:@"km-KH" voiceName:@"km-KH-PichNeural"];
        [allLanguageVoices setObject:khmerVoice forKey:EZLanguageKhmer];
        
        EZBingLanguageVoice *laoVoice = [EZBingLanguageVoice voiceWithLanguage:@"lo-LA" voiceName:@"lo-LA-AcharaNeural"];
        [allLanguageVoices setObject:laoVoice forKey:EZLanguageLao];
        
        EZBingLanguageVoice *bengaliVoice = [EZBingLanguageVoice voiceWithLanguage:@"bn-IN" voiceName:@"bn-IN-AnuNeural"];
        [allLanguageVoices setObject:bengaliVoice forKey:EZLanguageBengali];
        
        EZBingLanguageVoice *burmeseVoice = [EZBingLanguageVoice voiceWithLanguage:@"my-MM" voiceName:@"my-MM-ShanNeural"];
        [allLanguageVoices setObject:burmeseVoice forKey:EZLanguageBurmese];
        
        EZBingLanguageVoice *norwegianVoice = [EZBingLanguageVoice voiceWithLanguage:@"nb-NO" voiceName:@"nb-NO-PernilleNeural"];
        [allLanguageVoices setObject:norwegianVoice forKey:EZLanguageNorwegian];
        
        EZBingLanguageVoice *serbianVoice = [EZBingLanguageVoice voiceWithLanguage:@"sr-SP" voiceName:@"sr-SP-LjubicaNeural"];
        [allLanguageVoices setObject:serbianVoice forKey:EZLanguageSerbian];
        
        EZBingLanguageVoice *croatianVoice = [EZBingLanguageVoice voiceWithLanguage:@"hr-HR" voiceName:@"hr-HR-SreckoNeural"];
        [allLanguageVoices setObject:croatianVoice forKey:EZLanguageCroatian];
        
        EZBingLanguageVoice *mongolianVoice = [EZBingLanguageVoice voiceWithLanguage:@"mn-MN" voiceName:@"mn-MN-NarangerelNeural"];
        [allLanguageVoices setObject:mongolianVoice forKey:EZLanguageMongolian];
        
        EZBingLanguageVoice *hebrewVoice = [EZBingLanguageVoice voiceWithLanguage:@"he-IL" voiceName:@"he-IL-HilaNeural"];
        [allLanguageVoices setObject:hebrewVoice forKey:EZLanguageHebrew];
    });
    
    return allLanguageVoices;
}


- (void)executeCallback {
    self.responseCount += 1;
    if (self.responseCount >= 2) {
        // 测试发现，切换到与之前国家不同的ip后，可能使用之前的host请求不会报错，但是data没却没有值。
        // 所以需要重新获取一下host。
        // 但是不保证这个场景下一定是host的问题，所以重试一次。
        if (self.canRetryFetchHost && self.translateData != nil && self.translateData.length == 0 && self.lookupData != nil && self.lookupData.length == 0) {
            [self reset];
            self.canRetryFetchHost = NO;
            self.bingConfig.host = nil;
            [self saveBingConfig];
            [self translateText:self.text from:self.from to:self.to completionHandler:self.completion];
            return;
        }
        if (self.completion != nil) {
            self.completion([self.translateData copy], [self.lookupData copy], [self.translateError copy], [self.lookupError copy]);
            self.canRetryFetchHost = YES;
        }
        [self resetData];
    }
}

- (void)fetchBingHost:(void (^)(void))callback {
    if (self.bingConfig.host) {
        callback();
        return;
    }
    
    // For www.bing.com, sometimes it won't return redirect URL, so we use cn.bing.com
    NSString *webBingURLString = [NSString stringWithFormat:@"http://%@", EZBingChinaHost];
    
    [self.translateSession GET:webBingURLString parameters:nil progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        NSString *host = host = task.response.URL.host ?: EZBingChinaHost;
        self.bingConfig.host = host;
        [self saveBingConfig];
        NSLog(@"bing host: %@", host);
        callback();
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        self.bingConfig.host = EZBingChinaHost;
        [self saveBingConfig];
        callback();
    }];
}

- (void)fetchBingConfig:(void (^)(void))callback failure:(nonnull void (^)(NSError *_Nonnull))failure {
    if (![self.bingConfig isBingTokenExpired]) {
        callback();
        return;
    }
    
    NSString *url = self.bingConfig.translatorURLString;
    [self.htmlSession GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        NSError *error;
        if (![responseObject isKindOfClass:[NSData class]]) {
             error = [EZError errorWithType:EZErrorTypeAPI description: @"bing htmlSession responseObject is not NSData" request:nil];
            failure(error);
            NSLog(@"bing html responseObject type is %@", [responseObject class]);
            return;
        }
        
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSString *IG = [self getIGValueFromHTML:responseString];
        if (IG.length == 0) {
            error = [EZError errorWithType:EZErrorTypeAPI description: @"bing IG is empty" request:nil];
            failure(error);
            return;
        }
        NSLog(@"bing IG: %@", IG);
        
        NSString *IID = [self getValueOfDataIidFromHTML:responseString];
        if (IID.length == 0) {
            error = [EZError errorWithType:EZErrorTypeAPI description: @"bing IID is empty" request:nil];
            failure(error);
            return;
        }
        NSLog(@"bing IID: %@", IID);
        
        NSArray *arr = [self getParamsAbusePreventionHelperArrayFromHTML:responseString];
        if (arr.count != 3) {
            error = [EZError errorWithType:EZErrorTypeAPI description: @"bing get key and token failed" request:nil];
            failure(error);
            return;
        }
        NSString *key = arr[0];
        if (key.length == 0) {
            error = [EZError errorWithType:EZErrorTypeAPI description: @"bing key is empey" request:nil];
            failure(error);
            return;
        }
        NSString *token = arr[1];
        if (token.length == 0) {
            error = [EZError errorWithType:EZErrorTypeAPI description: @"bing token is empey" request:nil];
            failure(error);
            return;
        }
        NSLog(@"bing key: %@", key);
        NSLog(@"bing token: %@", token);
        
        NSString *expirationInterval = arr[2];
        
        self.bingConfig.IG = IG;
        self.bingConfig.IID = IID;
        self.bingConfig.key = key;
        self.bingConfig.token = token;
        self.bingConfig.expirationInterval = expirationInterval;
        [self saveBingConfig];
        callback();
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        failure(error);
    }];
}

- (void)translateText:(NSString *)text from:(NSString *)from to:(NSString *)to completionHandler:(BingTranslateCompletion)completion {
    self.from = from;
    self.to = to;
    self.text = text;
    self.completion = completion;
    [self fetchBingHost:^{
        [self fetchBingConfig:^{
            NSDictionary *parameters = @{
                @"text" : text,
                @"to" : to,
                @"token" : self.bingConfig.token,
                @"key" : self.bingConfig.key
            };
                        
            // Get translate data
            NSMutableDictionary *translateParameters = [parameters mutableCopy];
            [translateParameters addEntriesFromDictionary:@{
                @"fromLang" : from,
                @"tryFetchingGenderDebiasedTranslations" : @"true",
            }];
            
            [self.translateSession POST:self.bingConfig.ttranslatev3URLString parameters:translateParameters
                               progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                if (![responseObject isKindOfClass:[NSData class]]) {
                    self.translateError = [EZError errorWithType:EZErrorTypeAPI description:@"bing translate responseObject is not NSData" request:nil];
                    NSLog(@"bing translate responseObject type: %@", [responseObject class]);
                    [self executeCallback];
                    return;
                }
                self.translateData = responseObject;
                [self executeCallback];
            } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
                // if this problem occurs, you can try switching networks
                // if you use a VPN, you can try replacing nodes，or try adding `bing.com` into a direct rule
                // https://immersivetranslate.com/docs/faq/#429-%E9%94%99%E8%AF%AF
                if (response.statusCode == 429) {
                    self.translateError = [EZError errorWithType:EZErrorTypeAPI description:@"429 error, Bing translate too many requests" request:nil];
                } else {
                    self.translateError = error;
                }
                [self executeCallback];
            }];
            
            // Get lookup data
            NSMutableDictionary *dictParameters = [parameters mutableCopy];
            [dictParameters addEntriesFromDictionary:@{
                @"from" : from,
            }];
            
            [self.translateSession POST:self.bingConfig.tlookupv3URLString parameters:dictParameters
                               progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                if (![responseObject isKindOfClass:[NSData class]]) {
                    self.lookupError = [EZError errorWithType:EZErrorTypeAPI description:@"bing translate responseObject is not NSData" request:nil];
                    NSLog(@"bing lookup responseObject type: %@", [responseObject class]);
                    [self executeCallback];
                    return;
                }
                self.lookupData = responseObject;
                [self executeCallback];
            } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                NSLog(@"bing lookup error: %@", error);
                self.lookupError = error;
                [self executeCallback];
            }];
        } failure:^(NSError *error) {
            completion(nil, nil, error, nil);
        }];
    }];
}

- (void)fetchTextToAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(void (^)(NSData *_Nullable, NSError *_Nullable))completion {
    [self fetchBingHost:^{
        [self fetchBingConfig:^{
            NSString *ssml = [self genrateSSMLWithText:text language:from];
            NSDictionary *parameters = @{
                @"ssml" : ssml,
                @"token" : self.bingConfig.token,
                @"key" : self.bingConfig.key
            };
            
            [self.ttsSession POST:self.bingConfig.tfetttsURLString parameters:parameters progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                NSData *audioData = responseObject;
                if ([task.response.MIMEType isEqualToString:kAudioMIMEType]) {
                    completion(audioData, nil);
                } else {
                    // If host has changed, use new host to fetch again.
                    NSString *host = task.response.URL.host;
                    if (![self.bingConfig.host isEqualToString:host]) {
                        NSLog(@"bing host changed: %@", host);
                        self.bingConfig.host = host;
                        [self saveBingConfig];

                        [self fetchTextToAudio:text fromLanguage:from completion:completion];
                        return;
                    } else {
                        completion(nil, nil);
                    }
                }
            } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                completion(nil, error);
            }];
        } failure:^(NSError *error) {
            completion(nil, error);
        }];
    }];
}

- (void)translateTextFromDict:(NSString *)text completion:(void (^)(NSDictionary * _Nullable json, NSError * _Nullable error))completion {
    assert(completion != nil);
    [self fetchBingHost:^{
        [self.dictTranslateSession GET:self.bingConfig.dictTranslateURLString parameters:@{
            @"q": text,
        } progress:nil  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (![responseObject isKindOfClass:[NSDictionary class]]) {
               completion(nil, [EZError errorWithType:EZErrorTypeAPI description:@"bing dict translate json parse fail" request:nil]);
                return;
            }
            completion(responseObject, nil);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            completion(nil, error);
        }];
    }];
}


/**
 Generate ssml with text and language.
 
 Docs: https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/speech-synthesis-markup-structure#speak-examples
 
 <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
 <voice name="en-US-JennyNeural">
 This is the text that is spoken.
 </voice>
 </speak>
 
 */
- (NSString *)genrateSSMLWithText:(NSString *)text language:(EZLanguage)language {
    NSString *voiceRate = @"-10%"; // bing web is -20%
    
    EZBingLanguageVoice *languageVoice = [[EZBingRequest langaugeVoices] objectForKey:language];
    
    /**
     !!!: We need to hanle xml speacial characters, like ' < &, Ref:  https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/speech-synthesis-markup-structure#special-characters
     
     1000 Chinese characters, is about 1MB, duration 4 minutes (mp3)
     
     2000 Chinese characters, is about 1.9MB, duration 8 minutes
     
     7000 English characters, is about 2MB, duration 8 minutes
     */
    
    NSString *trimText = [text trimToMaxLength:7000];
    // Chinese text should short, long TTS will cost much time.
    if (![EZLanguageManager.shared isLanguageWordsNeedSpace:language]) {
        trimText = [text trimToMaxLength:2000];
    }
    
    NSString *escapedXMLText = CFBridgingRelease(CFXMLCreateStringByEscapingEntities(NULL, (__bridge CFStringRef)trimText, NULL));
    
    NSString *ssml = [NSString stringWithFormat:@"<speak version=\"1.0\" xml:lang='%@'>"
                      @"<voice name='%@'>"
                      @"<prosody rate='%@'>%@</prosody>"
                      @"</voice>"
                      @"</speak>",
                      languageVoice.lang, languageVoice.voiceName, voiceRate, escapedXMLText];
    
    return ssml;
}

- (void)reset {
    [self.bingConfig resetToken];
    [self resetData];
}


- (void)resetData {
    self.translateData = nil;
    self.lookupData = nil;
    self.translateError = nil;
    self.responseCount = 0;
}

- (NSString *)getIGValueFromHTML:(NSString *)htmlString {
    // IG:"8E24D5A82C3240C8A68683C2484870E6",
    NSString *pattern = @"IG:\\s*\"([^\"]+)\"";
    NSString *ig = [htmlString getStringValueWithPattern:pattern];
    return ig;
}

- (NSArray *)getParamsAbusePreventionHelperArrayFromHTML:(NSString *)htmlString {
    // var params_AbusePreventionHelper = [1693880687457,"0T_WDBmVBWjrlS5lBJPS6KYPLOboyyrf",3600000];
    NSString *pattern = @"params_AbusePreventionHelper\\s*=\\s*\\[([^]]+)\\]";
    NSString *arrayString = [htmlString getStringValueWithPattern:pattern];
    if (arrayString) {
        arrayString = [arrayString stringByReplacingOccurrencesOfString:@"\"" withString:@""]; // Remove double quotes
        NSArray *array = [arrayString componentsSeparatedByString:@","];
        return array;
    }
    
    return nil;
}

- (NSString *)getValueOfDataIidFromHTML:(NSString *)htmlString {
    // data-iid="translator.5029"
    NSString *pattern = @"data-iid\\s*=\\s*\"([^\"]+)\"";
    NSString *iid = [htmlString getStringValueWithPattern:pattern];
    return iid;
}

- (AFHTTPSessionManager *)htmlSession {
    if (!_htmlSession) {
        AFHTTPSessionManager *htmlSession = [AFHTTPSessionManager manager];
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:EZUserAgent forHTTPHeaderField:@"User-Agent"];
        htmlSession.requestSerializer = requestSerializer;
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
        htmlSession.responseSerializer = responseSerializer;
        _htmlSession = htmlSession;
    }
    return _htmlSession;
}

- (AFHTTPSessionManager *)translateSession {
    if (!_translateSession) {
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:EZUserAgent forHTTPHeaderField:@"User-Agent"];
        [requestSerializer setValue:self.bingConfig.cookie forHTTPHeaderField:@"Cookie"];
        session.requestSerializer = requestSerializer;
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        session.responseSerializer = responseSerializer;
        _translateSession = session;
    }
    return _translateSession;
}

- (AFHTTPSessionManager *)ttsSession {
    if (!_ttsSession) {
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:EZUserAgent forHTTPHeaderField:@"User-Agent"];
        [requestSerializer setValue:self.bingConfig.cookie forHTTPHeaderField:@"Cookie"];
        session.requestSerializer = requestSerializer;
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:kAudioMIMEType, nil];
        session.responseSerializer = responseSerializer;
        _ttsSession = session;
    }
    return _ttsSession;
}

- (AFHTTPSessionManager *)dictTranslateSession {
    if (!_dictTranslateSession) {
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:EZUserAgent forHTTPHeaderField:@"User-Agent"];
        [requestSerializer setValue:self.bingConfig.cookie forHTTPHeaderField:@"Cookie"];
        session.requestSerializer = requestSerializer;
        session.responseSerializer = [AFJSONResponseSerializer serializer];
        _dictTranslateSession = session;
    }
    return _dictTranslateSession;
}

@end
