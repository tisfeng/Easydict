//
//  EZBingRequest.m
//  Easydict
//
//  Created by ChoiKarl on 2023/8/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZBingRequest.h"
#import "EZTranslateError.h"

NSString * const kRequestHostCN = @"https://cn.bing.com";

// memory cache
static NSString *kRequestHostString;
static NSString *kIG;
static NSString *kIID;
static NSString *kToken;
static NSString *kKey;

NSString *getTranslatorHost(void) {
    return [NSString stringWithFormat:@"%@/translator", kRequestHostString];
}

NSString *getTTranslateV3Host(void) {
    return [NSString stringWithFormat:@"%@/ttranslatev3", kRequestHostString];
}

NSString *getTLookupV3Host(void) {
    return [NSString stringWithFormat:@"%@/tlookupv3", kRequestHostString];
}




@interface EZBingRequest ()
@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) AFHTTPSessionManager *translateSession;
@property (nonatomic, strong) NSData *translateData;
@property (nonatomic, strong) NSData *lookupData;
@property (nonatomic, strong) NSError *translateError;
@property (nonatomic, strong) NSError *lookupError;
@property (nonatomic, assign) NSInteger responseCount;
@property (nonatomic, copy) BingTranslateCompletion completion;
@end

@implementation EZBingRequest

- (void)executeCallback {
    self.responseCount += 1;
    if (self.responseCount >= 2) {
        if (self.completion != nil) {
            self.completion([self.translateData copy], [self.lookupData copy], [self.translateError copy], [self.lookupError copy]);
        }
        [self resetData];
    }
}

- (void)fetchRequestHost:(void(^)(NSString * host))callback {
    if (kRequestHostString.length) {
        callback(kRequestHostString);
    }
    [self.translateSession GET:kRequestHostCN parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (task.response.URL == nil) {
            kRequestHostString = @"https://www.bing.com";
        } else {
            kRequestHostString = [NSString stringWithFormat:@"%@://%@", task.response.URL.scheme, task.response.URL.host];
        }
        NSLog(@"bing host %@", kRequestHostString);
        callback(kRequestHostString);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        kRequestHostString = @"https://www.bing.com";
        callback(kRequestHostString);
    }];
}

- (void)fetchTranslateParam:(void (^)(NSString * IG, NSString * IID, NSString * token, NSString * key))paramCallback failure:(nonnull void (^)(NSError * _Nonnull))failure {
    if (kIG.length > 0 && kIID.length > 0 && kToken.length > 0 && kKey.length > 0) {
        paramCallback(kIG, kIID, kToken, kKey);
        return;
    }
    
    [self.htmlSession GET:getTranslatorHost() parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (![responseObject isKindOfClass:[NSData class]]) {
            failure(EZTranslateError(EZErrorTypeAPI, @"bing htmlSession responseObject is not NSData", nil));
            NSLog(@"bing html responseObject type is %@", [responseObject class]);
            return;
        }
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSString *IG = [self getIGValueFromHTML:responseString];
        if (IG.length == 0) {
            failure(EZTranslateError(EZErrorTypeAPI, @"bing IG is empty", nil));
            return;
        }
        kIG = IG;
        NSLog(@"bing IG: %@", IG);
        
        NSString *IID = [self getValueOfDataIidFromHTML:responseString];
        if (IID.length == 0) {
            failure(EZTranslateError(EZErrorTypeAPI, @"bing IID is empty", nil));
            return;
        }
        kIID = IID;
        NSLog(@"bing IID: %@", IID);
        
        NSArray *arr = [self getParamsAbusePreventionHelperArrayFromHTML:responseString];
        if (arr.count != 3) {
            failure(EZTranslateError(EZErrorTypeAPI, @"bing get key and token failed", nil));
            return;
        }
        NSString *key = arr[0];
        if (key.length == 0) {
            failure(EZTranslateError(EZErrorTypeAPI, @"bing key is empey", nil));
            return;
        }
        NSString *token = arr[1];
        if (token.length == 0) {
            failure(EZTranslateError(EZErrorTypeAPI, @"bing token is empey", nil));
            return;
        }
        kKey = key;
        NSLog(@"bing key: %@", key);
        kToken = token;
        NSLog(@"bing token: %@", token);
        paramCallback(IG, IID, token, key);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)translateWithFrom:(NSString *)from to:(NSString *)to text:(NSString *)text completionHandler:(BingTranslateCompletion)completion {
    self.completion = completion;
    [self fetchRequestHost:^(NSString *host) {
        [self fetchTranslateParam:^(NSString *IG, NSString *IID, NSString *token, NSString *key) {
            NSString *translateUrlString = [NSString stringWithFormat:@"%@?isVertical=1&IG=%@&IID=%@", getTTranslateV3Host(), IG, IID];
            /*
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:translateUrlString]];
            request.HTTPMethod = @"POST";
            request.HTTPBody = [[NSString stringWithFormat:@"tryFetchingGenderDebiasedTranslations=true&fromLang=%@&to=%@&text=%@&token=%@&key=%@", from, to, text, token, key] dataUsingEncoding:NSUTF8StringEncoding];
            NSURLSessionDataTask *task = [self.translateSession dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                if (![responseObject isKindOfClass:[NSData class]]) {
                    self.translateError = EZTranslateError(EZErrorTypeAPI, @"bing translate responseObject is not NSData", nil);
                    NSLog(@"bing translate responseObject type: %@", [responseObject class]);
                    [self executeCallback];
                    return;
                }
                self.translateData = responseObject;
                self.translateError = error;
                [self executeCallback];
            }];
            [task resume];
            */
            [self.translateSession POST:translateUrlString parameters:@{
                @"tryFetchingGenderDebiasedTranslations": @"true",
                @"text": text,
                @"fromLang": from,
                @"to": to,
                @"token": token,
                @"key": key
            } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if (![responseObject isKindOfClass:[NSData class]]) {
                    self.translateError = EZTranslateError(EZErrorTypeAPI, @"bing translate responseObject is not NSData", nil);
                    NSLog(@"bing translate responseObject type: %@", [responseObject class]);
                    [self executeCallback];
                    return;
                }
                self.translateData = responseObject;
                [self executeCallback];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
                // if this problem occurs, you can try switching networks
                // if you use a VPN, you can try replacing nodes，or try adding `bing.com` into a direct rule
                // https://immersivetranslate.com/docs/faq/#429-%E9%94%99%E8%AF%AF
                if (response.statusCode == 429) {
                    self.translateError = EZTranslateError(EZErrorTypeAPI, @"bing translate too many requests", nil);
                } else {
                    self.translateError = error;
                }
                [self executeCallback];
            }];
            
            NSString *lookupUrlString = [NSString stringWithFormat:@"%@?isVertical=1&IG=%@&IID=%@", getTLookupV3Host(), IG, IID];
            [self.translateSession POST:lookupUrlString parameters:@{
                @"from": from,
                @"to": to,
                @"text": text,
                @"token": token,
                @"key": key
            } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if (![responseObject isKindOfClass:[NSData class]]) {
                    self.lookupError = EZTranslateError(EZErrorTypeAPI, @"bing lookup responseObject is not NSData", nil);
                    NSLog(@"bing lookup responseObject type: %@", [responseObject class]);
                    [self executeCallback];
                    return;
                }
                self.lookupData = responseObject;
                [self executeCallback];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"bing lookup error: %@", error);
                self.lookupError = error;
                [self executeCallback];
            }];
            
        } failure:^(NSError * error) {
            completion(nil, nil, error, nil);
        }];
    }];
}

- (void)reset {
    [self resetToken];
    [self resetData];
}

- (void)resetToken {
    kIG = nil;
    kIID = nil;
    kToken = nil;
    kKey = nil;
}

- (void)resetData {
    self.translateData = nil;
    self.lookupData = nil;
    self.translateError = nil;
    self.responseCount = 0;
}

- (NSString *)getIGValueFromHTML:(NSString *)htmlString {
    NSString *pattern = @"IG:\\s*\"([^\"]+)\"";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:htmlString options:0 range:NSMakeRange(0, htmlString.length)];

    if (match && match.numberOfRanges >= 2) {
        NSRange igValueRange = [match rangeAtIndex:1];
        NSString *igValue = [htmlString substringWithRange:igValueRange];
        return igValue;
    }

    return nil;
}

- (NSArray *)getParamsAbusePreventionHelperArrayFromHTML:(NSString *)htmlString {
    NSString *pattern = @"params_AbusePreventionHelper\\s*=\\s*\\[([^]]+)\\]";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:htmlString options:0 range:NSMakeRange(0, htmlString.length)];
    
    if (match && match.numberOfRanges >= 2) {
        NSRange arrayRange = [match rangeAtIndex:1];
        NSString *arrayString = [htmlString substringWithRange:arrayRange];
        arrayString = [arrayString stringByReplacingOccurrencesOfString:@"\"" withString:@""]; // Remove double quotes
        NSArray *array = [arrayString componentsSeparatedByString:@","];
        return array;
    }
    
    return nil;
}

- (NSString *)getValueOfDataIidFromHTML:(NSString *)htmlString {
    NSString *pattern = @"data-iid\\s*=\\s*\"([^\"]+)\"";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:htmlString options:0 range:NSMakeRange(0, htmlString.length)];
    
    if (match && match.numberOfRanges >= 2) {
        NSRange dataIidValueRange = [match rangeAtIndex:1];
        NSString *dataIidValue = [htmlString substringWithRange:dataIidValueRange];
        return [dataIidValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    return nil;
}

- (AFHTTPSessionManager *)htmlSession {
    if (!_htmlSession) {
        AFHTTPSessionManager *htmlSession = [AFHTTPSessionManager manager];
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
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
        [requestSerializer setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
        session.requestSerializer = requestSerializer;
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        session.responseSerializer = responseSerializer;
        _translateSession = session;
    }
    return _translateSession;
}

- (NSString *)userAgent {
    return @"Mozilla/5.0 "
           "AppleWebKit/537.36 (KHTML, like Gecko) "
           "Chrome/77.0.3865.120 "
           "Safari/537.36";
}
@end
