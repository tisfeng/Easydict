//
//  EZMicrosoftRequest.m
//  Easydict
//
//  Created by ChoiKarl on 2023/8/8.
//  Copyright © 2023 izual. All rights reserved.
//

NSString * const kTTranslateV3Host = @"https://www.bing.com/ttranslatev3";
NSString * const kTLookupV3Host = @"https://www.bing.com/tlookupv3";

#import "EZMicrosoftRequest.h"
#import "AFNetworking.h"
#import "EZTranslateError.h"

@interface EZMicrosoftRequest ()
@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) AFHTTPSessionManager *translateSession;
@property (nonatomic, strong) NSData *translateData;
@property (nonatomic, strong) NSData *lookupData;
@property (nonatomic, strong) NSError *translateError;
@property (nonatomic, strong) NSError *lookupError;
@property (nonatomic, assign) NSInteger responseCount;
@property (nonatomic, copy) MicrosoftTranslateCompletion completion;
@end

@implementation EZMicrosoftRequest

- (void)executeCallback {
    self.responseCount += 1;
    if (self.responseCount == 2) {
        self.completion([self.translateData copy], [self.lookupData copy], [self.translateError copy], [self.lookupError copy]);
        self.translateData = nil;
        self.lookupData = nil;
        self.translateError = nil;
        self.responseCount = 0;
        self.completion = nil;
    }
}

- (void)fetchTranslateParam:(void (^)(NSString * IG, NSString * IID, NSString * token, NSString * key))paramCallback failure:(nonnull void (^)(NSError * _Nonnull))failure {
    
    static NSString *kIG;
    static NSString *kIID;
    static NSString *kToken;
    static NSString *kKey;
    
    
    if (kIG.length > 0 && kIID.length > 0 && kToken.length > 0 && kKey.length > 0) {
        paramCallback(kIG, kIID, kToken, kKey);
        return;
    }
    
    [self.htmlSession GET:kTranslatorHost parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (![responseObject isKindOfClass:[NSData class]]) {
            failure(EZTranslateError(EZErrorTypeAPI, @"microsoft htmlSession responseObject is not NSData", nil));
            NSLog(@"microsoft html responseObject type is %@", [responseObject class]);
            return;
        }
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSString *IG = [self getIGValueFromHTML:responseString];
        if (IG.length == 0) {
            failure(EZTranslateError(EZErrorTypeAPI, @"microsoft IG is empty", nil));
            return;
        }
        kIG = IG;
        NSLog(@"microsoft IG: %@", IG);
        
        NSString *IID = [self getValueOfDataIidFromHTML:responseString];
        if (IID.length == 0) {
            failure(EZTranslateError(EZErrorTypeAPI, @"microsoft IID is empty", nil));
            return;
        }
        kIID = IID;
        NSLog(@"microsoft IID: %@", IID);
        
        NSArray *arr = [self getParamsAbusePreventionHelperArrayFromHTML:responseString];
        if (arr.count != 3) {
            failure(EZTranslateError(EZErrorTypeAPI, @"microsoft get key and token failed", nil));
            return;
        }
        NSString *key = arr[0];
        if (key.length == 0) {
            failure(EZTranslateError(EZErrorTypeAPI, @"microsoft key is empey", nil));
            return;
        }
        NSString *token = arr[1];
        if (token.length == 0) {
            failure(EZTranslateError(EZErrorTypeAPI, @"microsoft token is empey", nil));
            return;
        }
        kKey = key;
        NSLog(@"microsoft key: %@", key);
        kToken = token;
        NSLog(@"microsoft token: %@", token);
        paramCallback(IG, IID, token, key);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)translateWithFrom:(NSString *)from to:(NSString *)to text:(NSString *)text completionHandler:(MicrosoftTranslateCompletion)completion {
    self.completion = completion;
    [self fetchTranslateParam:^(NSString *IG, NSString *IID, NSString *token, NSString *key) {
        NSString *translateUrlString = [NSString stringWithFormat:@"%@?isVertical=1&IG=%@&IID=%@", kTTranslateV3Host, IG, IID];
        [self.translateSession POST:translateUrlString parameters:@{
            @"tryFetchingGenderDebiasedTranslations": @"true",
            @"text": text,
            @"fromLang": from,
            @"to": to,
            @"token": token,
            @"key": key
        } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (![responseObject isKindOfClass:[NSData class]]) {
                self.translateError = EZTranslateError(EZErrorTypeAPI, @"microsoft translate responseObject is not NSData", nil);
                NSLog(@"microsoft translate responseObject type: %@", [responseObject class]);
                [self executeCallback];
                return;
            }
            self.translateData = responseObject;
            [self executeCallback];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            self.translateError = error;
            [self executeCallback];
        }];
        
        
        NSString *lookupUrlString = [NSString stringWithFormat:@"%@?isVertical=1&IG=%@&IID=%@", kTLookupV3Host, IG, IID];
        [self.translateSession POST:lookupUrlString parameters:@{
            @"from": from,
            @"to": to,
            @"text": text,
            @"token": token,
            @"key": key
        } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (![responseObject isKindOfClass:[NSData class]]) {
                self.lookupError = EZTranslateError(EZErrorTypeAPI, @"microsoft lookup responseObject is not NSData", nil);
                NSLog(@"microsoft lookup responseObject type: %@", [responseObject class]);
                [self executeCallback];
                return;
            }
            self.lookupData = responseObject;
            [self executeCallback];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            self.lookupError = error;
            [self executeCallback];
        }];
        
    } failure:^(NSError * error) {
        completion(nil, nil, error, nil);
    }];
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
        [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X "
        @"10_15_0) AppleWebKit/537.36 (KHTML, like "
        @"Gecko) Chrome/77.0.3865.120 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
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
        [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X "
        @"10_15_0) AppleWebKit/537.36 (KHTML, like "
        @"Gecko) Chrome/77.0.3865.120 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        session.requestSerializer = requestSerializer;
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        session.responseSerializer = responseSerializer;
        _translateSession = session;
    }
    return _translateSession;
}
@end
