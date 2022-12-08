//
//  SSCache.m
//  SSWKURLDemo
//
//  Created by sgcy on 2021/1/20.
//  Copyright © 2021 sgcy. All rights reserved.
//

#import "SSCache.h"

@interface SSCache()

@property (nonatomic,strong) NSMutableDictionary *responseCache;
@property (nonatomic,strong) NSMutableDictionary *dataCache;
@property (nonatomic,strong) NSMutableDictionary *requestFinished;
@property (nonatomic,strong) NSLock *lock;
@property (nonatomic,strong) NSString *rootCachePath;

@end

@implementation SSCache


+ (instancetype)sharedCache
{
    static SSCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc]init];
    });
    return sharedCache;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.responseCache = [[NSMutableDictionary alloc] init];
        self.dataCache = [[NSMutableDictionary alloc] init];
        self.requestFinished = [[NSMutableDictionary alloc] init];
        self.lock = [[NSLock alloc] init];
        [self setupCacheDirectory];
    }
    return self;
}

- (NSData *)dataForRequestId:(NSString *)requestId
{
    //load from memory
    NSData *data = self.dataCache[requestId];
    if (data) {
        NSNumber *finished = self.requestFinished[requestId];
        if (finished && finished.boolValue) {
            return data;
        }
    }
    
    //load from disk
    NSString *cacheFilePath = [self filePathWithType:1 sessionID:requestId];
    return [NSData dataWithContentsOfFile:cacheFilePath];
}

- (NSDictionary *)responseHeadersWithRequestID:(NSString *)requestId
{
    //load from memory
    NSDictionary *responseHeaders = self.responseCache[requestId];
    if (responseHeaders) {
        return responseHeaders;
    }
    
    //load from disk
    NSString *responsePath = [self filePathWithType:0 sessionID:requestId];
    return [NSDictionary dictionaryWithContentsOfFile:responsePath];
}

- (void)saveData:(NSData *)data forRequestId:(NSString *)requestId
{
    NSMutableData *mutaData = self.dataCache[requestId];
    if (!mutaData) {
        mutaData = [[NSMutableData alloc] init];
    }
    [mutaData appendData:data];
    [self.dataCache setObject:mutaData forKey:requestId];
}

- (void)saveResponseHeaders:(NSDictionary *)responseHeaders forRequestId:(NSString *)requestId
{
    [self.responseCache setObject:responseHeaders forKey:requestId];
}

- (void)finishRequestForRequestId:(NSString *)requestId
{
    [self.requestFinished setObject:@(YES) forKey:requestId];
    
    NSDictionary *responseHeaders = self.responseCache[requestId];
    if (responseHeaders) {
        NSString *responsePath = [self filePathWithType:0 sessionID:requestId];
        BOOL isSuccess = [responseHeaders writeToFile:responsePath atomically:YES];
    }
    
    NSData *data = self.dataCache[requestId];
    if (data) {
        NSString *dataPath = [self filePathWithType:1 sessionID:requestId];
        BOOL isSuccess = [data writeToFile:dataPath atomically:YES];
    }
    
}

#pragma mark - file

- (BOOL)setupCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _rootCachePath = [[self createDirectoryIfNotExist:[paths objectAtIndex:0] withSubPath:@"SSCache"] copy];
    return _rootCachePath.length > 0;
}

- (BOOL)checkCacheTypeExist:(NSInteger)type sessionID:(NSString *)sessionID
{
    NSString *cachePath = [self filePathWithType:type sessionID:sessionID];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:cachePath];
}

- (NSString *)filePathWithType:(NSInteger)type sessionID:(NSString *)sessionID
{
    NSString *fileDir = [self sessionSubCacheDir:sessionID];
    if (fileDir.length == 0) {
        return nil;
    }
    NSString *cacheFileName = [sessionID stringByAppendingPathExtension:[@(type) stringValue]];
    return [fileDir stringByAppendingPathComponent:cacheFileName];
}

- (NSString *)sessionSubCacheDir:(NSString *)sessionID
{
    return [self createDirectoryIfNotExist:_rootCachePath withSubPath:sessionID];
}

- (NSString *)createDirectoryIfNotExist:(NSString *)parent withSubPath:(NSString *)subPath
{
    if(parent.length == 0 || subPath.length == 0){
        return nil;
    }
    
    BOOL isDir = YES;
    NSString *path = [parent stringByAppendingPathComponent:subPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            return nil;
        }
    }
    return path;
}

@end
